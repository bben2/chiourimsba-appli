import Foundation

struct Catalogue: Codable, Equatable, Sendable {
    var version: Int
    var miseAJour: String
    var collections: [CollectionDonnees]

    enum CodingKeys: String, CodingKey {
        case version
        case miseAJour = "mise_a_jour"
        case collections
    }

    func collection(_ id: String) -> CollectionDonnees? {
        collections.first { $0.id == id }
    }

    func oeuvre(collection: String, id: String) -> Oeuvre? {
        self.collection(collection)?.oeuvres.first { $0.id == id }
    }
}

struct CollectionDonnees: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var titre: String
    var titreHe: String
    var oeuvres: [Oeuvre]

    enum CodingKeys: String, CodingKey {
        case id, titre, oeuvres
        case titreHe = "titre_he"
    }
}

struct Oeuvre: Codable, Equatable, Sendable, Identifiable, Hashable {
    var id: String
    var titre: String
    var titreHe: String
    var auteur: String?
    var chemin: String
    var unites: [String]

    enum CodingKeys: String, CodingKey {
        case id, titre, auteur, chemin, unites
        case titreHe = "titre_he"
    }
}

enum OrdreTalmud {
    struct Groupe: Identifiable, Equatable, Sendable {
        var id: String { nom }
        var nom: String
        var oeuvres: [Oeuvre]
    }

    static func groupes(_ oeuvres: [Oeuvre]) -> [Groupe] {
        let table: [(String, Set<String>)] = [
            ("Seder Zeraïm", ["berakhot", "berachot"]),
            ("Seder Moëd", ["shabbat", "chabbat", "eruvin", "erouvin", "pesachim", "rosh hashana", "rosh hashanah", "yoma", "sukkah", "soucca", "beitzah", "beitsa", "taanit", "megillah", "megilla", "moed katan", "chagigah", "haguiga"]),
            ("Seder Nachim", ["yevamot", "ketubot", "nedarim", "nazir", "sotah", "gittin", "kiddushin"]),
            ("Seder Nezikin", ["bava kamma", "baba kama", "bava metzia", "baba metsia", "baba batra", "bava batra", "sanhedrin", "makkot", "shevuot", "avodah zarah", "horayot"]),
            ("Seder Kodachim", ["zevachim", "menachot", "chullin", "houlin", "bekhorot", "arakhin", "arachin", "temurah", "keritot", "meilah", "tamid", "middot", "kinnim"]),
            ("Seder Taharot", ["niddah"])
        ]
        var reste = oeuvres
        var resultat: [Groupe] = []
        for (nom, ids) in table {
            let dedans = reste.filter { ids.contains(cle($0.id)) || ids.contains(cle($0.titre)) }
            if !dedans.isEmpty {
                resultat.append(Groupe(nom: nom, oeuvres: dedans))
                let pris = Set(dedans.map(\.id))
                reste.removeAll { pris.contains($0.id) }
            }
        }
        if !reste.isEmpty {
            resultat.append(Groupe(nom: "Autres traités", oeuvres: reste))
        }
        return resultat
    }

    private static func cle(_ texte: String) -> String {
        texte.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
    }
}

enum Libelles {
    static func compteOeuvres(_ n: Int, collection: String) -> String {
        switch collection {
        case "guemara":
            return n == 1 ? "1 traité" : "\(n) traités"
        case "hassidout":
            return n == 1 ? "1 livre" : "\(n) livres"
        case "halakha":
            return n == 0 ? "Bientôt dans l'appli" : (n == 1 ? "1 ouvrage" : "\(n) ouvrages")
        default:
            return n == 1 ? "1 texte" : "\(n) textes"
        }
    }

    static func compteUnites(_ n: Int, collection: String) -> String {
        if collection == "hassidout" || collection == "halakha" {
            return n == 1 ? "1 section" : "\(n) sections"
        }
        return n == 1 ? "1 feuillet" : "\(n) feuillets"
    }

    static func sousTitreCollection(_ id: String) -> String {
        switch id {
        case "guemara": return "Rachi, Tossefot et schémas"
        case "hassidout": return "Les maîtres, de Lizhensk à Breslev"
        case "halakha": return "Le Choulhan Aroukh et ses abrégés"
        default: return ""
        }
    }
}
