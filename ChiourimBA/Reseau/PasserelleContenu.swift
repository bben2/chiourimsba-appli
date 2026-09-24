import Foundation

struct ReponseScheme: Sendable, Equatable {
    var donnees: Data
    var typeMIME: String
    var code: Int
}

struct ProgresTelechargement: Sendable, Equatable {
    var fait: Int
    var total: Int
}

private struct EtatRevisions: Codable, Sendable {
    var dernierControle: Date? = nil
    var shaDistants: [String: String] = [:]
    var shaFichiers: [String: [String: String]] = [:]
}

private struct CommitAPI: Decodable, Sendable {
    let sha: String
}

/// Télécharge depuis GitHub, sert le cache, et répond au schéma `chiourim://`.
actor PasserelleContenu {
    static let partagee: PasserelleContenu = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return PasserelleContenu(racine: caches.appendingPathComponent("Contenu", isDirectory: true))
    }()

    private let cache: CacheContenu
    private let session: URLSession
    private var etat: EtatRevisions
    private let fichierEtat: URL

    init(racine: URL, session: URLSession? = nil) {
        try? FileManager.default.createDirectory(at: racine, withIntermediateDirectories: true)
        cache = CacheContenu(racine: racine)
        fichierEtat = racine.appendingPathComponent("revisions.json")
        if let data = try? Data(contentsOf: fichierEtat) {
            let decodeur = JSONDecoder()
            decodeur.dateDecodingStrategy = .iso8601
            etat = (try? decodeur.decode(EtatRevisions.self, from: data)) ?? EtatRevisions()
        } else {
            etat = EtatRevisions()
        }
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 180
            configuration.waitsForConnectivity = false
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.urlCache = nil
            self.session = URLSession(configuration: configuration)
        }
    }

    func repondre(a url: URL?) async -> ReponseScheme {
        guard let url, url.scheme?.lowercased() == "chiourim" else {
            return page(PageMessage.horsLigne)
        }
        if url.host?.lowercased() == "bloque" {
            return page("Ce site n'est pas disponible dans l'application.")
        }
        guard let hote = url.host, let site = Bibliotheque.site(id: hote) else {
            return page("Site inconnu.")
        }
        guard let chemin = CheminContenu.normaliser(url.path) else {
            return page("Chemin refusé.")
        }
        if !DiscussionWidget.estActive, (chemin as NSString).lastPathComponent == "chat.js" {
            let source = "/* Widget de discussion désactivé dans cette version. */\n"
            return ReponseScheme(donnees: Data(source.utf8), typeMIME: TypeMIME.pourChemin(chemin), code: 200)
        }
        do {
            let brut = try await obtenir(site: site, chemin: chemin)
            let mime = TypeMIME.pourChemin(chemin)
            let donnees = preparer(brut, mime: mime)
            return ReponseScheme(donnees: donnees, typeMIME: mime, code: 200)
        } catch EchecContenu.horsLigne {
            return page(PageMessage.horsLigne)
        } catch EchecContenu.introuvable {
            return page("Cette page est introuvable.")
        } catch {
            return page("Impossible de télécharger cette page.")
        }
    }

    func fichier(pour url: URL) async throws -> URL {
        guard url.scheme?.lowercased() == "chiourim",
              let hote = url.host,
              let site = Bibliotheque.site(id: hote),
              let chemin = CheminContenu.normaliser(url.path) else {
            throw EchecContenu.chemin
        }
        if cache.existe(siteID: site.id, chemin: chemin), !estPerime(site: site, chemin: chemin) {
            guard let local = cache.urlFichier(siteID: site.id, chemin: chemin) else {
                throw EchecContenu.chemin
            }
            return local
        }
        guard let distant = URLGitHub.brute(depot: site.depot, chemin: chemin) else {
            throw EchecContenu.chemin
        }
        do {
            let destination = try cache.destination(siteID: site.id, chemin: chemin)
            try await telechargerFichier(depuis: distant, vers: destination)
            marquerFichier(siteID: site.id, chemin: chemin)
            return destination
        } catch EchecContenu.introuvable {
            throw EchecContenu.introuvable
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if cache.existe(siteID: site.id, chemin: chemin),
               let local = cache.urlFichier(siteID: site.id, chemin: chemin) {
                return local
            }
            if Self.estDeconnecte(error) { throw EchecContenu.horsLigne }
            throw EchecContenu.reseau
        }
    }

    func nombrePagesLiees(site: Site, chemin: String) -> Int {
        guard let data = cache.lire(siteID: site.id, chemin: chemin) else { return 0 }
        let texte = ReecritureLien.reecrireTexte(
            String(decoding: data, as: UTF8.self),
            retirerDiscussion: false
        )
        return ExtracteurLiens.pagesHTML(html: texte, cheminPage: chemin, siteID: site.id)
            .filter { $0 != chemin }
            .count
    }

    func tailleCache() -> Int64 {
        cache.taille()
    }

    func viderCache() {
        try? cache.toutEffacer()
        etat.shaFichiers = [:]
        sauvegarderEtat()
    }

    func verifierRevisionsSiBesoin() async {
        if let date = etat.dernierControle, Date().timeIntervalSince(date) < 86_400 {
            return
        }
        await verifierRevisions()
    }

    nonisolated func telechargerHorsLigne(
        site: Site,
        chemin: String
    ) -> AsyncThrowingStream<ProgresTelechargement, Error> {
        AsyncThrowingStream { continuation in
            let tache = Task {
                do {
                    try await self.parcours(site: site, chemin: chemin) { progres in
                        continuation.yield(progres)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                tache.cancel()
            }
        }
    }

    private func parcours(
        site: Site,
        chemin: String,
        signaler: @Sendable (ProgresTelechargement) -> Void
    ) async throws {
        let sommaire = try await obtenir(site: site, chemin: chemin)
        let html = ReecritureLien.reecrireTexte(
            String(decoding: sommaire, as: UTF8.self),
            retirerDiscussion: false
        )
        var pages = ExtracteurLiens.pagesHTML(html: html, cheminPage: chemin, siteID: site.id)
        pages.removeAll { $0 == chemin }
        if pages.isEmpty {
            signaler(ProgresTelechargement(fait: 0, total: 0))
            return
        }

        var vus = Set(pages)
        vus.insert(chemin)
        var ressources: [String] = []
        var fait = 0
        signaler(ProgresTelechargement(fait: 0, total: pages.count))

        for page in pages {
            try Task.checkCancellation()
            let data = try await obtenirEnContinuant(site: site, chemin: page)
            fait += 1
            if let data, (page as NSString).pathExtension.lowercased() == "html"
                || (page as NSString).pathExtension.lowercased() == "htm" {
                let texte = ReecritureLien.reecrireTexte(
                    String(decoding: data, as: UTF8.self),
                    retirerDiscussion: false
                )
                for ressource in ExtracteurLiens.ressources(html: texte, cheminPage: page, siteID: site.id)
                where vus.insert(ressource).inserted {
                    ressources.append(ressource)
                }
            }
            signaler(ProgresTelechargement(fait: fait, total: pages.count + ressources.count))
        }

        for ressource in ressources {
            try Task.checkCancellation()
            _ = try await obtenirEnContinuant(site: site, chemin: ressource)
            fait += 1
            signaler(ProgresTelechargement(fait: fait, total: pages.count + ressources.count))
        }
    }

    private func obtenir(site: Site, chemin: String) async throws -> Data {
        if cache.existe(siteID: site.id, chemin: chemin),
           !estPerime(site: site, chemin: chemin),
           let local = cache.lire(siteID: site.id, chemin: chemin) {
            return local
        }
        guard let distant = URLGitHub.brute(depot: site.depot, chemin: chemin) else {
            throw EchecContenu.chemin
        }
        do {
            let data = try await telechargerDonnees(distant)
            try cache.ecrire(siteID: site.id, chemin: chemin, donnees: data)
            marquerFichier(siteID: site.id, chemin: chemin)
            return data
        } catch EchecContenu.introuvable {
            throw EchecContenu.introuvable
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let local = cache.lire(siteID: site.id, chemin: chemin) {
                return local
            }
            if Self.estDeconnecte(error) {
                throw EchecContenu.horsLigne
            }
            throw EchecContenu.reseau
        }
    }

    private func obtenirEnContinuant(site: Site, chemin: String) async throws -> Data? {
        do {
            return try await obtenir(site: site, chemin: chemin)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }

    private func verifierRevisions() async {
        var succes = false
        for site in Bibliotheque.sites {
            do {
                let sha = try await shaDistant(depot: site.depot)
                etat.shaDistants[site.id] = sha
                succes = true
            } catch is CancellationError {
                return
            } catch {
                continue
            }
        }
        if succes {
            etat.dernierControle = Date()
            sauvegarderEtat()
        }
    }

    private func shaDistant(depot: String) async throws -> String {
        guard let url = URLGitHub.commit(depot: depot) else { throw EchecContenu.chemin }
        var requete = URLRequest(url: url)
        requete.setValue("ChiourimBA/1.0", forHTTPHeaderField: "User-Agent")
        requete.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: requete)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw EchecContenu.reseau
        }
        return try JSONDecoder().decode(CommitAPI.self, from: data).sha
    }

    private func telechargerDonnees(_ url: URL) async throws -> Data {
        var requete = URLRequest(url: url)
        requete.setValue("ChiourimBA/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: requete)
            guard let http = response as? HTTPURLResponse else { throw EchecContenu.reseau }
            if http.statusCode == 404 { throw EchecContenu.introuvable }
            guard (200..<300).contains(http.statusCode) else { throw EchecContenu.reseau }
            return data
        } catch let erreur as EchecContenu {
            throw erreur
        } catch let erreur as URLError where erreur.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw error
        }
    }

    private func telechargerFichier(depuis url: URL, vers destination: URL) async throws {
        var requete = URLRequest(url: url)
        requete.setValue("ChiourimBA/1.0", forHTTPHeaderField: "User-Agent")
        requete.timeoutInterval = 180
        let temporaire: URL
        let response: URLResponse
        do {
            (temporaire, response) = try await session.download(for: requete)
        } catch let erreur as URLError where erreur.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        }
        guard let http = response as? HTTPURLResponse else { throw EchecContenu.reseau }
        if http.statusCode == 404 { throw EchecContenu.introuvable }
        guard (200..<300).contains(http.statusCode) else { throw EchecContenu.reseau }
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaire, to: destination)
    }

    private func estPerime(site: Site, chemin: String) -> Bool {
        guard let distant = etat.shaDistants[site.id] else { return false }
        guard let local = etat.shaFichiers[site.id]?[chemin] else { return true }
        return local != distant
    }

    private func marquerFichier(siteID: String, chemin: String) {
        let sha = etat.shaDistants[siteID] ?? "inconnu"
        var fichiers = etat.shaFichiers[siteID] ?? [:]
        fichiers[chemin] = sha
        etat.shaFichiers[siteID] = fichiers
        sauvegarderEtat()
    }

    private func preparer(_ data: Data, mime: String) -> Data {
        guard TypeMIME.estTexte(mime), let texte = String(data: data, encoding: .utf8) else {
            return data
        }
        let html = mime.lowercased().contains("html")
        let reecrit = ReecritureLien.reecrireTexte(texte, retirerDiscussion: html)
        return Data(reecrit.utf8)
    }

    private func page(_ message: String) -> ReponseScheme {
        ReponseScheme(
            donnees: PageMessage.donnees(message),
            typeMIME: "text/html; charset=utf-8",
            code: 200
        )
    }

    private func sauvegarderEtat() {
        let encodeur = JSONEncoder()
        encodeur.outputFormatting = [.prettyPrinted, .sortedKeys]
        encodeur.dateEncodingStrategy = .iso8601
        guard let data = try? encodeur.encode(etat) else { return }
        try? data.write(to: fichierEtat, options: .atomic)
    }

    private static func estDeconnecte(_ error: Error) -> Bool {
        guard let code = (error as? URLError)?.code else { return false }
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return true
        default:
            return false
        }
    }
}
