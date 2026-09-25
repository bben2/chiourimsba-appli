import Foundation
import SwiftUI

/// Interrupteurs tenus à l'écart du compilateur : lus dans l'Info.plist, absents donc faux / vides.
enum Config {
    /// Passe à vrai avec le compte développeur payant, quand CloudKit sera branché.
    static var connexionActive: Bool {
        Bundle.main.object(forInfoDictionaryKey: "ConnexionActive") as? Bool ?? false
    }

    /// Lien de don. Tant qu'il est absent, « Nous soutenir » reste caché.
    static var urlDons: URL? {
        guard let brut = Bundle.main.object(forInfoDictionaryKey: "URLDons") as? String else { return nil }
        return URL(string: brut)
    }

    static let urlPortail = URL(string: "https://chiourimsba.vercel.app")!
    static let urlSignaler = URL(string: "https://chiourimsba.vercel.app/api/signaler")!
    static let urlHalakha = URL(string: "https://halakha.vercel.app")!
}

enum LivresPapier {
    struct Lien: Identifiable, Equatable, Sendable {
        var id: String { url.absoluteString }
        var titre: String
        var url: URL
    }

    /// Liens Lulu. Vide : l'écran « Nos livres » dit que ça arrive.
    static let liens: [Lien] = []
}

enum SourceDonnees {
    static let base = "https://raw.githubusercontent.com/bben2/chiourimsba-donnees/main/"

    static func urlDistante(_ chemin: String) -> URL? {
        guard let relatif = relatifSur(chemin) else { return nil }
        return URL(string: base + relatif)
    }

    /// Dossier local de développement, lu seulement sur le simulateur s'il est là.
    static func fichierLocal(_ chemin: String) -> URL? {
        #if targetEnvironment(simulator)
        guard let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"], !home.isEmpty else { return nil }
        guard let relatif = relatifSur(chemin) else { return nil }
        var url = URL(fileURLWithPath: home, isDirectory: true)
            .appending(path: "sefaria_translate")
            .appending(path: "donnees")
        for morceau in relatif.split(separator: "/") {
            url.append(path: String(morceau))
        }
        if FileManager.default.isReadableFile(atPath: url.path) { return url }
        #endif
        return nil
    }

    static func cheminPage(oeuvre: Oeuvre, unite: String) -> String {
        cheminPage(collectionID: "", oeuvreID: oeuvre.id, unite: unite, cheminOeuvre: oeuvre.chemin)
    }

    static func cheminPage(collectionID: String, oeuvreID: String, unite: String, cheminOeuvre: String?) -> String {
        if let cheminOeuvre, !cheminOeuvre.isEmpty {
            var baseChemin = cheminOeuvre
            if !baseChemin.hasSuffix("/") { baseChemin += "/" }
            return baseChemin + unite + ".json"
        }
        return "\(collectionID)/\(oeuvreID)/\(unite).json"
    }

    /// Fichier `.html` du site public, tel que l'attend l'API de signalement.
    static func pageHTML(collectionID: String, oeuvreID: String, unite: String) -> String {
        if collectionID == "guemara" {
            return "\(oeuvreID)_\(unite).html"
        }
        return "\(oeuvreID)/\(unite).html"
    }

    static func urlPartage(collectionID: String, page: String) -> URL? {
        let hote: String
        switch collectionID {
        case "guemara": hote = "guemara.vercel.app"
        case "hassidout": hote = "hassidout.vercel.app"
        case "halakha": hote = "halakha.vercel.app"
        default: return nil
        }
        let morceaux = page.split(separator: "/").map {
            String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0)
        }
        return URL(string: "https://\(hote)/" + morceaux.joined(separator: "/"))
    }

    static func relatifSur(_ chemin: String) -> String? {
        if chemin.contains("..") || chemin.contains("\\") { return nil }
        let morceaux = chemin.split(separator: "/").map(String.init).filter { !$0.isEmpty && $0 != "." }
        if morceaux.isEmpty { return nil }
        return morceaux.joined(separator: "/")
    }
}

enum Apparence: String, CaseIterable, Identifiable {
    case papier
    case nuit
    case systeme

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .papier: return "Papier"
        case .nuit: return "Nuit"
        case .systeme: return "Système"
        }
    }

    /// Papier reste crème même si l'appareil est en mode sombre.
    var schema: ColorScheme? {
        switch self {
        case .papier: return .light
        case .nuit: return .dark
        case .systeme: return nil
        }
    }
}

enum ReglagesLocaux {
    static let cleEchelle = "echelleTexte"
    static let cleDisposition = "dispositionTexte"
    static let cleMaj = "misesAJourAuto"
    static let cleVerification = "derniereVerification"
    static let cleApparence = "apparence"

    static var misesAJourAuto: Bool {
        if UserDefaults.standard.object(forKey: cleMaj) == nil { return true }
        return UserDefaults.standard.bool(forKey: cleMaj)
    }

    static var derniereVerification: Date? {
        let t = UserDefaults.standard.double(forKey: cleVerification)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    static func noterVerification(_ date: Date = Date()) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: cleVerification)
    }
}

enum DispositionTexte: String, CaseIterable, Identifiable {
    case auto
    case empile
    case cote

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .auto: return "Automatique"
        case .empile: return "L'un sous l'autre"
        case .cote: return "Côte à côte"
        }
    }
}
