import SwiftUI

enum OngletApp: Hashable {
    case site(String)
    case favoris
}

@MainActor
@Observable
final class NavigationBibliotheque {
    var onglet: OngletApp = .site("portail")
    var destinations: [String: URL] = [:]
    var jetons: [String: Int] = [:]

    func ouvrir(siteID: String, chemin: String) {
        guard let site = Bibliotheque.site(id: siteID) else { return }
        destinations[siteID] = site.urlApplication(chemin: chemin)
        jetons[siteID, default: 0] += 1
        onglet = .site(siteID)
    }

    func ouvrir(url: URL) {
        guard url.scheme?.lowercased() == "chiourim",
              let hote = url.host,
              Bibliotheque.site(id: hote) != nil,
              let chemin = CheminContenu.normaliser(url.path) else {
            return
        }
        ouvrir(siteID: hote, chemin: chemin)
    }
}
