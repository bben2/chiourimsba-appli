import SwiftData
import SwiftUI

@main
struct ChiourimBAApp: App {
    @State private var magasin = MagasinTextes()
    @State private var navigation = NavigationApp()
    private let conteneur = FabriqueConteneur.creer()

    var body: some Scene {
        WindowGroup {
            RacineView()
                .environment(magasin)
                .environment(navigation)
                .modelContainer(conteneur)
                .tint(Theme.bleu)
                .task {
                    _ = ReseauEtat.partage.enLigne
                    await magasin.rafraichirCatalogue()
                }
                .task {
                    await SignalementService.retenter(FileSignalements.standard())
                }
        }
    }
}

struct RacineView: View {
    @Environment(NavigationApp.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.onglet) {
            NavigationStack {
                AccueilView()
            }
            .tabItem { Label("Chiourim", systemImage: "house") }
            .tag(OngletApp.chiourim)

            NavigationStack {
                ListeOeuvresView(collectionID: "guemara")
            }
            .tabItem { Label("Guemara", systemImage: "book") }
            .tag(OngletApp.guemara)

            NavigationStack {
                ListeOeuvresView(collectionID: "hassidout")
            }
            .tabItem { Label("Hassidout", systemImage: "flame") }
            .tag(OngletApp.hassidout)

            NavigationStack {
                ListeOeuvresView(collectionID: "halakha")
            }
            .tabItem { Label("Halakha", systemImage: "scalemass") }
            .tag(OngletApp.halakha)

            NavigationStack {
                EspaceView()
            }
            .tabItem { Label("Mon espace", systemImage: "bookmark") }
            .tag(OngletApp.espace)
        }
        .toolbarBackground(Theme.papier, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
