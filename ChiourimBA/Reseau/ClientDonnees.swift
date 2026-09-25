import Foundation

struct ClientDonnees: Sendable {
    var session: URLSession
    var cache: CacheDisque

    func charger(chemin: String, prefererReseau: Bool) async throws -> Data {
        if let local = SourceDonnees.fichierLocal(chemin) {
            let data = try Data(contentsOf: local)
            try cache.ecrire(chemin, data)
            return data
        }
        if !prefererReseau, let enCache = cache.lire(chemin) {
            return enCache
        }
        guard let url = SourceDonnees.urlDistante(chemin) else { throw ErreurDonnees.chemin }
        do {
            let (data, reponse) = try await session.data(from: url)
            if let http = reponse as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
                if let enCache = cache.lire(chemin) { return enCache }
                throw ErreurDonnees.absent
            }
            try cache.ecrire(chemin, data)
            return data
        } catch let erreur as ErreurDonnees {
            throw erreur
        } catch {
            if let enCache = cache.lire(chemin) { return enCache }
            throw ErreurDonnees.reseau
        }
    }

    static func decoderCatalogue(_ data: Data) throws -> Catalogue {
        do {
            return try JSONDecoder().decode(Catalogue.self, from: data)
        } catch {
            throw ErreurDonnees.illisible
        }
    }

    static func decoderPage(_ data: Data) throws -> PageTexte {
        do {
            return try JSONDecoder().decode(PageTexte.self, from: data)
        } catch {
            throw ErreurDonnees.illisible
        }
    }
}
