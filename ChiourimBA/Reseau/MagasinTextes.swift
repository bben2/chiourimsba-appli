import Foundation
import Network

struct EtatTelechargement: Equatable, Sendable {
    var oeuvreID: String
    var fait: Int
    var total: Int
}

@MainActor
@Observable
final class ReseauEtat {
    static let partage = ReseauEtat()
    private(set) var enLigne = true
    private let moniteur = NWPathMonitor()

    private init() {
        moniteur.pathUpdateHandler = { chemin in
            let ok = chemin.status == .satisfied
            Task { @MainActor in
                ReseauEtat.partage.enLigne = ok
            }
        }
        moniteur.start(queue: DispatchQueue(label: "chiourim.reseau"))
    }
}

@MainActor
@Observable
final class NavigationApp {
    var onglet = OngletApp.chiourim
}

enum OngletApp: String, Hashable, CaseIterable, Identifiable {
    case chiourim, guemara, hassidout, halakha, espace

    var id: String { rawValue }

    static var tous: [OngletApp] { allCases }

    var titre: String {
        switch self {
        case .chiourim: return "Chiourim"
        case .guemara: return "Guemara"
        case .hassidout: return "Hassidout"
        case .halakha: return "Halakha"
        case .espace: return "Mon espace"
        }
    }

    var symbole: String {
        switch self {
        case .chiourim: return "house"
        case .guemara: return "book"
        case .hassidout: return "flame"
        case .halakha: return "scalemass"
        case .espace: return "bookmark"
        }
    }
}

@MainActor
@Observable
final class MagasinTextes {
    private(set) var catalogue: Catalogue?
    private(set) var chargementCatalogue = false
    private(set) var erreurCatalogue: String?
    private(set) var telechargement: EtatTelechargement?
    private(set) var pretsHorsLigne: Set<String> = []

    private let cache: CacheDisque
    private let client: ClientDonnees
    private var tache: Task<Void, Never>?

    init(cache: CacheDisque = .standard(), session: URLSession = .shared) {
        self.cache = cache
        self.client = ClientDonnees(session: session, cache: cache)
        if let data = cache.lire("catalogue.json"), let lu = try? ClientDonnees.decoderCatalogue(data) {
            catalogue = lu
            majPrets()
        }
    }

    func collection(_ id: String) -> CollectionDonnees? {
        catalogue?.collection(id)
    }

    func oeuvre(collection: String, id: String) -> Oeuvre? {
        catalogue?.oeuvre(collection: collection, id: id)
    }

    func rafraichirCatalogue(force: Bool = false) async {
        if !force, !ReglagesLocaux.misesAJourAuto, catalogue != nil { return }
        chargementCatalogue = true
        erreurCatalogue = nil
        defer { chargementCatalogue = false }
        do {
            let data = try await client.charger(chemin: "catalogue.json", prefererReseau: force || ReglagesLocaux.misesAJourAuto)
            catalogue = try ClientDonnees.decoderCatalogue(data)
            erreurCatalogue = nil
            ReglagesLocaux.noterVerification()
            majPrets()
        } catch let erreur as ErreurDonnees {
            if catalogue == nil { erreurCatalogue = erreur.message }
        } catch {
            if catalogue == nil { erreurCatalogue = ErreurDonnees.reseau.message }
        }
    }

    func ouvrirPage(chemin: String) async throws -> PageTexte {
        let data = try await client.charger(chemin: chemin, prefererReseau: ReglagesLocaux.misesAJourAuto)
        return try ClientDonnees.decoderPage(data)
    }

    func telecharger(oeuvre: Oeuvre) {
        tache?.cancel()
        let total = oeuvre.unites.count
        telechargement = EtatTelechargement(oeuvreID: oeuvre.id, fait: 0, total: total)
        tache = Task {
            for (indice, unite) in oeuvre.unites.enumerated() {
                if Task.isCancelled { return }
                let chemin = SourceDonnees.cheminPage(oeuvre: oeuvre, unite: unite)
                _ = try? await client.charger(chemin: chemin, prefererReseau: true)
                if Task.isCancelled { return }
                telechargement = EtatTelechargement(oeuvreID: oeuvre.id, fait: indice + 1, total: total)
            }
            telechargement = nil
            majPrets()
        }
    }

    func annulerTelechargement() {
        tache?.cancel()
        tache = nil
        telechargement = nil
        majPrets()
    }

    func viderCache() {
        try? cache.vider()
        pretsHorsLigne = []
        catalogue = nil
        Task { await rafraichirCatalogue(force: true) }
    }

    func espaceUtilise() -> (total: Int64, details: [(nom: String, octets: Int64)]) {
        (cache.taille(), cache.taillesParDossier())
    }

    private func majPrets() {
        guard let catalogue else {
            pretsHorsLigne = []
            return
        }
        var prets: Set<String> = []
        for collection in catalogue.collections {
            for oeuvre in collection.oeuvres where cache.oeuvreComplete(oeuvre) {
                prets.insert(oeuvre.id)
            }
        }
        pretsHorsLigne = prets
    }
}
