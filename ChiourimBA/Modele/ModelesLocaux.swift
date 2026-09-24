import Foundation
import SwiftData

@Model
final class Favori {
    var titre: String
    var siteID: String
    var chemin: String
    var ajouteLe: Date

    init(titre: String, siteID: String, chemin: String, ajouteLe: Date) {
        self.titre = titre
        self.siteID = siteID
        self.chemin = chemin
        self.ajouteLe = ajouteLe
    }
}

@Model
final class EntreeHistorique {
    var titre: String
    var siteID: String
    var chemin: String
    var visiteLe: Date

    init(titre: String, siteID: String, chemin: String, visiteLe: Date) {
        self.titre = titre
        self.siteID = siteID
        self.chemin = chemin
        self.visiteLe = visiteLe
    }
}
