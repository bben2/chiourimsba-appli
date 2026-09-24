import Foundation

/// Fichiers sous `Library/Caches/Contenu/<site>/<chemin>`.
struct CacheContenu: Sendable {
    let racine: URL

    static func urlFichier(racine: URL, siteID: String, chemin: String) -> URL? {
        guard let chemin = CheminContenu.normaliser(chemin) else { return nil }
        var url = racine.appendingPathComponent(siteID, isDirectory: true)
        for partie in chemin.split(separator: "/") {
            url = url.appendingPathComponent(String(partie))
        }
        let standard = url.standardizedFileURL
        let base = racine.standardizedFileURL.path
        let prefixe = base.hasSuffix("/") ? base : base + "/"
        guard standard.path.hasPrefix(prefixe) else { return nil }
        return standard
    }

    func urlFichier(siteID: String, chemin: String) -> URL? {
        Self.urlFichier(racine: racine, siteID: siteID, chemin: chemin)
    }

    func lire(siteID: String, chemin: String) -> Data? {
        guard let url = urlFichier(siteID: siteID, chemin: chemin),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    func destination(siteID: String, chemin: String) throws -> URL {
        guard let url = urlFichier(siteID: siteID, chemin: chemin) else {
            throw EchecContenu.chemin
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return url
    }

    func ecrire(siteID: String, chemin: String, donnees: Data) throws {
        let url = try destination(siteID: siteID, chemin: chemin)
        try donnees.write(to: url, options: .atomic)
    }

    func existe(siteID: String, chemin: String) -> Bool {
        guard let url = urlFichier(siteID: siteID, chemin: chemin) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func taille() -> Int64 {
        guard let enumerateur = FileManager.default.enumerator(
            at: racine,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]
        ) else {
            return 0
        }
        var total: Int64 = 0
        for cas in enumerateur {
            guard let url = cas as? URL,
                  let valeurs = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  valeurs.isRegularFile == true else {
                continue
            }
            total += Int64(valeurs.fileSize ?? 0)
        }
        return total
    }

    func toutEffacer() throws {
        let gestionnaire = FileManager.default
        if gestionnaire.fileExists(atPath: racine.path) {
            try gestionnaire.removeItem(at: racine)
        }
        try gestionnaire.createDirectory(at: racine, withIntermediateDirectories: true)
    }
}

enum EchecContenu: Error, Equatable {
    case horsLigne
    case introuvable
    case reseau
    case chemin
}
