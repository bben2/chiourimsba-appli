import Foundation

/// Extrait les pages et les ressources liées depuis un sommaire, sans les PDF.
enum ExtracteurLiens {
    private static let extensionsPages: Set<String> = ["html", "htm"]
    private static let extensionsRessources: Set<String> = [
        "css", "js", "mjs", "png", "jpg", "jpeg", "gif", "webp", "svg",
        "woff", "woff2", "ttf", "otf", "json", "ico",
    ]

    static func pagesHTML(html: String, cheminPage: String, siteID: String) -> [String] {
        liens(dans: html, cheminPage: cheminPage, siteID: siteID, extensions: extensionsPages)
    }

    static func ressources(html: String, cheminPage: String, siteID: String) -> [String] {
        liens(dans: html, cheminPage: cheminPage, siteID: siteID, extensions: extensionsRessources)
            .filter { ($0 as NSString).lastPathComponent != "chat.js" }
    }

    static func resoudre(_ reference: String, depuis cheminPage: String, siteID: String) -> String? {
        var reference = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reference.isEmpty else { return nil }
        let bas = reference.lowercased()
        if bas.hasPrefix("#") || bas.hasPrefix("mailto:") || bas.hasPrefix("tel:") || bas.hasPrefix("javascript:") {
            return nil
        }

        if bas.hasPrefix("http://") || bas.hasPrefix("https://") || bas.hasPrefix("chiourim://") {
            guard let url = URL(string: reference) else { return nil }
            switch ReecritureLien.decider(url) {
            case .interne(let cible):
                guard cible.scheme?.lowercased() == "chiourim",
                      cible.host?.lowercased() == siteID.lowercased() else {
                    return nil
                }
                return CheminContenu.normaliser(cible.path)
            case .safari, .courriel, .bloque:
                return nil
            }
        }

        if let indice = reference.firstIndex(of: "#") {
            reference = String(reference[..<indice])
        }
        if let indice = reference.firstIndex(of: "?") {
            reference = String(reference[..<indice])
        }
        guard !reference.isEmpty else { return nil }
        if reference.hasPrefix("/") {
            return CheminContenu.normaliser(reference)
        }
        let dossier = (cheminPage as NSString).deletingLastPathComponent
        let combine = dossier.isEmpty ? reference : dossier + "/" + reference
        return CheminContenu.normaliser(combine)
    }

    private static func liens(
        dans html: String,
        cheminPage: String,
        siteID: String,
        extensions: Set<String>
    ) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:href|src)\s*=\s*(?:"([^"]+)"|'([^']+)')"#,
            options: [.caseInsensitive]
        ) else {
            return []
        }
        let plage = NSRange(html.startIndex..., in: html)
        var vus: Set<String> = []
        var ordre: [String] = []
        regex.enumerateMatches(in: html, options: [], range: plage) { resultat, _, _ in
            guard let resultat else { return }
            let indice = resultat.range(at: 1).location != NSNotFound ? 1 : 2
            guard let zone = Range(resultat.range(at: indice), in: html) else { return }
            let brut = String(html[zone])
            guard let chemin = resoudre(brut, depuis: cheminPage, siteID: siteID) else { return }
            let ext = (chemin as NSString).pathExtension.lowercased()
            guard extensions.contains(ext) else { return }
            if vus.insert(chemin).inserted {
                ordre.append(chemin)
            }
        }
        return ordre
    }
}
