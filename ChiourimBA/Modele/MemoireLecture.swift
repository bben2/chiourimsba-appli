import Foundation

/// Zoom et dernière page de chaque onglet. Fichier local, pas de UserDefaults.
@MainActor
final class MemoireLecture: ObservableObject {
    static let partagee = MemoireLecture()

    @Published private(set) var zoom: Double
    private var dernieres: [String: String]
    private let fichier: URL

    init(fichier: URL? = nil) {
        if let fichier {
            self.fichier = fichier
        } else {
            let dossier = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ChiourimBA", isDirectory: true)
            try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
            self.fichier = dossier.appendingPathComponent("preferences.json")
        }
        if let data = try? Data(contentsOf: self.fichier),
           let etat = try? JSONDecoder().decode(EtatPreferences.self, from: data) {
            zoom = min(2, max(0.7, etat.zoom))
            dernieres = etat.dernieresPages
        } else {
            zoom = 1
            dernieres = [:]
        }
    }

    func cheminDernier(siteID: String) -> String? {
        dernieres[siteID]
    }

    func memoriser(siteID: String, chemin: String) {
        dernieres[siteID] = chemin
        enregistrer()
    }

    func reglerZoom(_ valeur: Double) {
        zoom = min(2, max(0.7, (valeur * 10).rounded() / 10))
        enregistrer()
    }

    private func enregistrer() {
        let etat = EtatPreferences(zoom: zoom, dernieresPages: dernieres)
        guard let data = try? JSONEncoder().encode(etat) else { return }
        try? data.write(to: fichier, options: .atomic)
    }
}

private struct EtatPreferences: Codable {
    var zoom: Double
    var dernieresPages: [String: String]
}
