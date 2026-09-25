import Foundation
import SwiftData

@Model
final class Favori {
    @Attribute(.unique) var cle: String
    var collectionID: String
    var oeuvreID: String
    var unite: String
    var titre: String
    var site: String
    var chemin: String
    var ajouteLe: Date

    init(cle: String, collectionID: String, oeuvreID: String, unite: String, titre: String, site: String, chemin: String, ajouteLe: Date) {
        self.cle = cle
        self.collectionID = collectionID
        self.oeuvreID = oeuvreID
        self.unite = unite
        self.titre = titre
        self.site = site
        self.chemin = chemin
        self.ajouteLe = ajouteLe
    }
}

@Model
final class PositionLecture {
    @Attribute(.unique) var cle: String
    var collectionID: String
    var oeuvreID: String
    var oeuvreTitre: String
    var unite: String
    var indexSegment: Int
    var titrePage: String
    var resume: String
    var totalUnites: Int
    var indexUnite: Int
    var miseAJour: Date

    init(cle: String, collectionID: String, oeuvreID: String, oeuvreTitre: String, unite: String, indexSegment: Int, titrePage: String, resume: String, totalUnites: Int, indexUnite: Int, miseAJour: Date) {
        self.cle = cle
        self.collectionID = collectionID
        self.oeuvreID = oeuvreID
        self.oeuvreTitre = oeuvreTitre
        self.unite = unite
        self.indexSegment = indexSegment
        self.titrePage = titrePage
        self.resume = resume
        self.totalUnites = totalUnites
        self.indexUnite = indexUnite
        self.miseAJour = miseAJour
    }
}

@Model
final class AnnotationLocale {
    var id: UUID
    var collectionID: String
    var oeuvreID: String
    var oeuvreTitre: String
    var unite: String
    var indexSegment: Int
    var passage: String
    var note: String
    var surlignage: Bool
    var creeLe: Date

    init(id: UUID, collectionID: String, oeuvreID: String, oeuvreTitre: String, unite: String, indexSegment: Int, passage: String, note: String, surlignage: Bool, creeLe: Date) {
        self.id = id
        self.collectionID = collectionID
        self.oeuvreID = oeuvreID
        self.oeuvreTitre = oeuvreTitre
        self.unite = unite
        self.indexSegment = indexSegment
        self.passage = passage
        self.note = note
        self.surlignage = surlignage
        self.creeLe = creeLe
    }
}

@Model
final class UniteLue {
    @Attribute(.unique) var cle: String
    var oeuvreID: String
    var unite: String

    init(cle: String, oeuvreID: String, unite: String) {
        self.cle = cle
        self.oeuvreID = oeuvreID
        self.unite = unite
    }
}

enum FabriqueConteneur {
    static func creer() -> ModelContainer {
        let schema = Schema([Favori.self, PositionLecture.self, AnnotationLocale.self, UniteLue.self])
        let disque = ModelConfiguration(
            "EspaceNatif",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        if let conteneur = try? ModelContainer(for: schema, configurations: disque) {
            return conteneur
        }
        let memoire = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        guard let conteneur = try? ModelContainer(for: schema, configurations: memoire) else {
            fatalError("Le stockage local est indisponible.")
        }
        return conteneur
    }
}
