import Foundation

struct CorpsSignalement: Codable, Equatable, Sendable {
    var site: String
    var page: String
    var passage: String
    var correction: String
    var source: String
    var siteWeb: String

    enum CodingKeys: String, CodingKey {
        case site, page, passage, correction, source
        case siteWeb = "site_web"
    }
}

enum IssueEnvoi: Equatable, Sendable {
    case envoye
    case bientot
    case refuse
    case reseau

    var message: String {
        switch self {
        case .envoye: return "Merci, c'est envoyé."
        case .bientot: return "Les signalements ouvrent bientôt."
        case .refuse: return "L'envoi n'a pas abouti. Il reste enregistré sur cet appareil."
        case .reseau: return "Pas de réseau. Le signalement reste ici et partira plus tard."
        }
    }
}

struct EntreeSignalement: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var site: String
    var page: String
    var passage: String
    var correction: String
    var creeLe: Date
    var etat: String

    func corps() -> CorpsSignalement {
        CorpsSignalement(site: site, page: page, passage: passage, correction: correction, source: "appli", siteWeb: "")
    }
}

struct FileSignalements: Sendable {
    var fichier: URL

    static func standard() -> FileSignalements {
        FileSignalements(fichier: CacheDisque.dossierApplication().appending(path: "signalements.json"))
    }

    func lire() -> [EntreeSignalement] {
        guard let data = try? Data(contentsOf: fichier),
              let liste = try? JSONDecoder().decode([EntreeSignalement].self, from: data) else { return [] }
        return liste.sorted { $0.creeLe > $1.creeLe }
    }

    func ecrire(_ entrees: [EntreeSignalement]) throws {
        let dossier = fichier.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(entrees)
        try data.write(to: fichier, options: .atomic)
    }

    func ajouter(site: String, page: String, passage: String, correction: String) throws -> EntreeSignalement {
        var tous = lire()
        let entree = EntreeSignalement(
            id: UUID(),
            site: site,
            page: page,
            passage: passage,
            correction: correction,
            creeLe: Date(),
            etat: "attente"
        )
        tous.append(entree)
        try ecrire(tous)
        return entree
    }

    func appliquer(id: UUID, issue: IssueEnvoi) throws {
        var tous = lire()
        guard let index = tous.firstIndex(where: { $0.id == id }) else { return }
        if issue == .envoye {
            tous[index].etat = "envoye"
        } else {
            tous[index].etat = "attente"
        }
        try ecrire(tous)
    }

    func enAttente() -> [EntreeSignalement] {
        lire().filter { $0.etat != "envoye" }
    }
}

enum SignalementService {
    static func interpreter(code: Int) -> IssueEnvoi {
        switch code {
        case 201: return .envoye
        case 503: return .bientot
        default: return .refuse
        }
    }

    static func envoyer(_ entree: EntreeSignalement, session: URLSession, fichier: FileSignalements) async -> IssueEnvoi {
        do {
            var requete = URLRequest(url: Config.urlSignaler)
            requete.httpMethod = "POST"
            requete.setValue("application/json", forHTTPHeaderField: "Content-Type")
            requete.httpBody = try JSONEncoder().encode(entree.corps())
            let (_, reponse) = try await session.data(for: requete)
            let code = (reponse as? HTTPURLResponse)?.statusCode ?? 0
            let issue = interpreter(code: code)
            try? fichier.appliquer(id: entree.id, issue: issue)
            return issue
        } catch {
            return .reseau
        }
    }

    static func retenter(_ fichier: FileSignalements, session: URLSession = .shared) async {
        for entree in fichier.enAttente() {
            _ = await envoyer(entree, session: session, fichier: fichier)
        }
    }
}
