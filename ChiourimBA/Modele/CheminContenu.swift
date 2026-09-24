import Foundation

/// Normalise un chemin de site : décode, refuse `..`, et transforme un dossier en `index.html`.
enum CheminContenu {
    static func normaliser(_ chemin: String) -> String? {
        var brut = chemin.removingPercentEncoding ?? chemin
        if let indice = brut.firstIndex(of: "?") {
            brut = String(brut[..<indice])
        }
        if let indice = brut.firstIndex(of: "#") {
            brut = String(brut[..<indice])
        }
        if brut.hasPrefix("/") {
            brut.removeFirst()
        }
        if brut.isEmpty || brut.hasSuffix("/") {
            brut += "index.html"
        }

        var pile: [String] = []
        for partie in brut.split(separator: "/", omittingEmptySubsequences: true) {
            if partie == "." {
                continue
            }
            if partie == ".." {
                guard !pile.isEmpty else { return nil }
                pile.removeLast()
                continue
            }
            pile.append(String(partie))
        }
        if pile.isEmpty {
            return "index.html"
        }
        return pile.joined(separator: "/")
    }
}
