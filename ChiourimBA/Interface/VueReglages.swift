import SwiftUI

struct VueReglages: View {
    @Environment(\.dismiss) private var dismiss
    @State private var octets: Int64 = 0
    @State private var confirmer = false

    var body: some View {
        NavigationStack {
            List {
                Section("Stockage") {
                    LabeledContent("Espace utilisé", value: texteTaille)
                    Button("Vider le cache", role: .destructive) {
                        confirmer = true
                    }
                }
                Section("Hors connexion") {
                    Text("Une page déjà ouverte reste lisible sans réseau. Le bouton « Télécharger pour lire hors ligne » enregistre un sommaire. Les PDF ne sont téléchargés qu'à l'ouverture.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                octets = await PasserelleContenu.partagee.tailleCache()
            }
            .confirmationDialog(
                "Vider le cache ?",
                isPresented: $confirmer,
                titleVisibility: .visible
            ) {
                Button("Vider le cache", role: .destructive) {
                    Task {
                        await PasserelleContenu.partagee.viderCache()
                        octets = 0
                        NotificationCenter.default.post(name: .cacheContenuVide, object: nil)
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Les pages enregistrées sur cet iPhone seront effacées. Les favoris sont conservés.")
            }
        }
    }

    private var texteTaille: String {
        let formateur = ByteCountFormatter()
        formateur.countStyle = .file
        return formateur.string(fromByteCount: octets)
    }
}
