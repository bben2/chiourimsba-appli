import Foundation

struct CacheDisque: Sendable {
    var racine: URL

    static func dossierApplication() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "ChiourimBA", directoryHint: .isDirectory)
    }

    static func standard() -> CacheDisque {
        CacheDisque(racine: dossierApplication().appending(path: "fichiers", directoryHint: .isDirectory))
    }

    func lire(_ chemin: String) -> Data? {
        guard let url = urlFichier(chemin) else { return nil }
        return try? Data(contentsOf: url)
    }

    func existe(_ chemin: String) -> Bool {
        guard let url = urlFichier(chemin) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func ecrire(_ chemin: String, _ data: Data) throws {
        guard let url = urlFichier(chemin) else { throw ErreurDonnees.chemin }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    func taille() -> Int64 {
        guard let enumerateur = FileManager.default.enumerator(at: racine, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        for cas in enumerateur {
            guard let url = cas as? URL else { continue }
            let valeurs = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            if valeurs?.isRegularFile == true {
                total += Int64(valeurs?.fileSize ?? 0)
            }
        }
        return total
    }

    func taillesParDossier() -> [(nom: String, octets: Int64)] {
        let noms = ["guemara", "hassidout", "halakha"]
        return noms.map { nom in
            let sous = CacheDisque(racine: racine.appending(path: nom, directoryHint: .isDirectory))
            return (nom, sous.taille())
        }
    }

    func vider() throws {
        if FileManager.default.fileExists(atPath: racine.path) {
            try FileManager.default.removeItem(at: racine)
        }
    }

    func oeuvreComplete(_ oeuvre: Oeuvre) -> Bool {
        guard !oeuvre.unites.isEmpty else { return false }
        return oeuvre.unites.allSatisfy { existe(SourceDonnees.cheminPage(oeuvre: oeuvre, unite: $0)) }
    }

    func urlFichier(_ chemin: String) -> URL? {
        guard let relatif = SourceDonnees.relatifSur(chemin) else { return nil }
        var url = racine
        for morceau in relatif.split(separator: "/") {
            url.append(path: String(morceau))
        }
        return url
    }
}
