import Foundation

/// Un site de la bibliothèque. Ajouter un site : une ligne dans `Bibliotheque.sites`.
struct Site: Identifiable, Hashable, Sendable {
    let id: String
    let depot: String
    let hoteVercel: String
    /// Libellé de l'onglet.
    let titreOnglet: String
    /// Nom affiché dans les favoris.
    let nom: String
    let symbole: String

    func urlApplication(chemin: String) -> URL {
        var composants = URLComponents()
        composants.scheme = "chiourim"
        composants.host = id
        composants.path = "/" + chemin
        guard let url = composants.url else {
            preconditionFailure("URL interne illisible pour \(id)/\(chemin)")
        }
        return url
    }

    func urlPublique(chemin: String) -> URL {
        var composants = URLComponents()
        composants.scheme = "https"
        composants.host = hoteVercel
        composants.path = "/" + chemin
        guard let url = composants.url else {
            preconditionFailure("URL publique illisible pour \(hoteVercel)/\(chemin)")
        }
        return url
    }
}

enum Bibliotheque {
    static let sites: [Site] = [
        Site(
            id: "portail",
            depot: "chiourimsba-portail",
            hoteVercel: "chiourimsba.vercel.app",
            titreOnglet: "Accueil",
            nom: "Chiourim",
            symbole: "house"
        ),
        Site(
            id: "guemara",
            depot: "chiourimsba-guemara",
            hoteVercel: "guemara.vercel.app",
            titreOnglet: "Guemara",
            nom: "Guemara",
            symbole: "book"
        ),
        Site(
            id: "hassidout",
            depot: "chiourimsba-hassidout",
            hoteVercel: "hassidout.vercel.app",
            titreOnglet: "Hassidout",
            nom: "Hassidout",
            symbole: "books.vertical"
        ),
        Site(
            id: "halakha",
            depot: "chiourimsba-halakha",
            hoteVercel: "halakha.vercel.app",
            titreOnglet: "Halakha",
            nom: "Halakha",
            symbole: "scroll"
        ),
    ]

    static func site(id: String) -> Site? {
        sites.first { $0.id.caseInsensitiveCompare(id) == .orderedSame }
    }

    static func site(hoteVercel hote: String) -> Site? {
        let cle = hote.lowercased()
        return sites.first { cle == $0.hoteVercel || cle == "www.\($0.hoteVercel)" }
    }
}
