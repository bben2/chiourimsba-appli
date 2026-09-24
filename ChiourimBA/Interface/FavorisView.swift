import SwiftData
import SwiftUI

struct FavorisView: View {
    @Environment(NavigationBibliotheque.self) private var navigation
    @Environment(\.modelContext) private var contexte
    @Query(sort: \Favori.ajouteLe, order: .reverse) private var favoris: [Favori]
    @Query(sort: \EntreeHistorique.visiteLe, order: .reverse) private var historique: [EntreeHistorique]
    @State private var recherche = ""
    @State private var afficherReglages = false

    var body: some View {
        NavigationStack {
            liste
                .navigationTitle("Favoris")
                .searchable(text: $recherche, prompt: "Titres des favoris et de l'historique")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            afficherReglages = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Réglages")
                    }
                }
        }
        .sheet(isPresented: $afficherReglages) {
            VueReglages()
        }
    }

    @ViewBuilder
    private var liste: some View {
        if favorisFiltres.isEmpty && historiqueFiltre.isEmpty {
            ContentUnavailableView(
                recherche.isEmpty ? "Aucun favori" : "Aucun résultat",
                systemImage: "star",
                description: Text(
                    recherche.isEmpty
                        ? "Ajoutez une page avec l'étoile, pendant la lecture."
                        : "Aucun titre ne correspond."
                )
            )
        } else {
            List {
                if !favorisFiltres.isEmpty {
                    Section("Favoris") {
                        ForEach(favorisFiltres) { favori in
                            BoutonDocument(
                                titre: favori.titre,
                                siteID: favori.siteID,
                                date: favori.ajouteLe
                            ) {
                                navigation.ouvrir(siteID: favori.siteID, chemin: favori.chemin)
                            }
                        }
                        .onDelete { index in
                            for indice in index {
                                contexte.delete(favorisFiltres[indice])
                            }
                        }
                    }
                }
                if !historiqueFiltre.isEmpty {
                    Section("Historique") {
                        ForEach(historiqueFiltre.prefix(80)) { entree in
                            BoutonDocument(
                                titre: entree.titre,
                                siteID: entree.siteID,
                                date: entree.visiteLe
                            ) {
                                navigation.ouvrir(siteID: entree.siteID, chemin: entree.chemin)
                            }
                        }
                    }
                }
            }
        }
    }

    private var favorisFiltres: [Favori] {
        filtrer(recherche, dans: favoris.map { ($0, $0.titre) }).map(\.0)
    }

    private var historiqueFiltre: [EntreeHistorique] {
        filtrer(recherche, dans: historique.map { ($0, $0.titre) }).map(\.0)
    }

    private func filtrer<T>(_ texte: String, dans lignes: [(T, String)]) -> [(T, String)] {
        let aiguille = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !aiguille.isEmpty else { return lignes }
        return lignes.filter { $0.1.localizedStandardContains(aiguille) }
    }
}

struct FeuilleRecherche: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FavorisView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
        }
    }
}

private struct BoutonDocument: View {
    let titre: String
    let siteID: String
    let date: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titre)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text("\(nomSite) · \(date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR"))))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var nomSite: String {
        Bibliotheque.site(id: siteID)?.nom ?? siteID
    }
}
