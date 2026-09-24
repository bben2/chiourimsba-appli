import Foundation

enum DecisionLien: Equatable {
    case interne(URL)
    case safari(URL)
    case courriel(URL)
    case bloque
}

/// Réécrit les liens Vercel vers `chiourim://` et bloque otsrot.
enum ReecritureLien {
    private static let correspondances: [(source: String, cible: String)] = [
        ("https://www.chiourimsba.vercel.app", "chiourim://portail"),
        ("http://www.chiourimsba.vercel.app", "chiourim://portail"),
        ("https://chiourimsba.vercel.app", "chiourim://portail"),
        ("http://chiourimsba.vercel.app", "chiourim://portail"),
        ("https://www.guemara.vercel.app", "chiourim://guemara"),
        ("http://www.guemara.vercel.app", "chiourim://guemara"),
        ("https://guemara.vercel.app", "chiourim://guemara"),
        ("http://guemara.vercel.app", "chiourim://guemara"),
        ("https://www.hassidout.vercel.app", "chiourim://hassidout"),
        ("http://www.hassidout.vercel.app", "chiourim://hassidout"),
        ("https://hassidout.vercel.app", "chiourim://hassidout"),
        ("http://hassidout.vercel.app", "chiourim://hassidout"),
        ("https://www.halakha.vercel.app", "chiourim://halakha"),
        ("http://www.halakha.vercel.app", "chiourim://halakha"),
        ("https://halakha.vercel.app", "chiourim://halakha"),
        ("http://halakha.vercel.app", "chiourim://halakha"),
        ("https://www.otsrot.vercel.app", "chiourim://bloque"),
        ("http://www.otsrot.vercel.app", "chiourim://bloque"),
        ("https://otsrot.vercel.app", "chiourim://bloque"),
        ("http://otsrot.vercel.app", "chiourim://bloque"),
    ]

    static func decider(_ url: URL) -> DecisionLien {
        let schema = url.scheme?.lowercased() ?? ""
        if schema == "mailto" {
            return .courriel(url)
        }
        if schema == "chiourim" {
            if url.host?.lowercased() == "bloque" {
                return .bloque
            }
            return .interne(url)
        }
        if schema == "http" || schema == "https" {
            if estOtsrot(url) {
                return .bloque
            }
            if let interne = urlInterne(depuis: url) {
                return .interne(interne)
            }
            return .safari(url)
        }
        if schema == "about" || schema == "blob" || schema == "data" {
            return .interne(url)
        }
        return .safari(url)
    }

    /// Réécrit les URL absolues Vercel dans le HTML, le CSS et le JavaScript servis à la WebView.
    static func reecrireTexte(_ texte: String, retirerDiscussion: Bool) -> String {
        var resultat = texte
        for couple in correspondances {
            resultat = resultat.replacingOccurrences(
                of: couple.source,
                with: couple.cible,
                options: [.caseInsensitive]
            )
        }
        if retirerDiscussion && !DiscussionWidget.estActive {
            resultat = retirerScriptDiscussion(resultat)
        }
        return resultat
    }

    static func memeDocument(_ gauche: URL, _ droite: URL) -> Bool {
        gauche.scheme?.lowercased() == droite.scheme?.lowercased()
            && gauche.host?.lowercased() == droite.host?.lowercased()
            && gauche.path == droite.path
            && gauche.query == droite.query
    }

    private static func estOtsrot(_ url: URL) -> Bool {
        guard let hote = url.host?.lowercased() else { return false }
        return hote == "otsrot.vercel.app" || hote.hasSuffix(".otsrot.vercel.app")
    }

    private static func urlInterne(depuis url: URL) -> URL? {
        guard let hote = url.host?.lowercased(),
              let site = Bibliotheque.site(hoteVercel: hote) else {
            return nil
        }
        var composants = URLComponents()
        composants.scheme = "chiourim"
        composants.host = site.id
        composants.path = url.path.isEmpty ? "/" : url.path
        composants.query = url.query
        composants.fragment = url.fragment
        return composants.url
    }

    private static func retirerScriptDiscussion(_ html: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"<script\b[^>]*\bchat\.js\b[^>]*>\s*(?:</script>)?"#,
            options: [.caseInsensitive]
        ) else {
            return html
        }
        let plage = NSRange(html.startIndex..., in: html)
        return regex.stringByReplacingMatches(in: html, options: [], range: plage, withTemplate: "")
    }
}
