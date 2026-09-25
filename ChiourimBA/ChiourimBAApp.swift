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
        .defaultSize(width: 1200, height: 800)
    }
}

struct RacineView: View {
    @Environment(NavigationApp.self) private var navigation
    @Environment(\.horizontalSizeClass) private var classe
    @AppStorage(ReglagesLocaux.cleApparence) private var apparenceBrute = Apparence.papier.rawValue

    var body: some View {
        @Bindable var navigation = navigation
        Group {
            if classe == .regular {
                NavigationSplitView {
                    List(selection: selectionLaterale) {
                        ForEach(OngletApp.tous) { onglet in
                            Label(onglet.titre, systemImage: onglet.symbole)
                                .tag(onglet)
                        }
                    }
                    .navigationTitle("Chiourim BA")
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                    .background(Theme.fond)
                } detail: {
                    pile(navigation.onglet)
                }
                .navigationSplitViewStyle(.balanced)
                .navigationSplitViewColumnWidth(min: 220, ideal: 248, max: 300)
            } else {
                TabView(selection: $navigation.onglet) {
                    ForEach(OngletApp.tous) { onglet in
                        pile(onglet)
                            .tabItem { Label(onglet.titre, systemImage: onglet.symbole) }
                            .tag(onglet)
                    }
                }
                .toolbarBackground(Theme.papier, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            }
        }
        .background(Theme.fond)
        .preferredColorScheme((Apparence(rawValue: apparenceBrute) ?? .papier).schema)
    }

    private var selectionLaterale: Binding<OngletApp?> {
        Binding(
            get: { navigation.onglet },
            set: { if let valeur = $0 { navigation.onglet = valeur } }
        )
    }

    @ViewBuilder
    private func pile(_ onglet: OngletApp) -> some View {
        NavigationStack {
            switch onglet {
            case .chiourim:
                AccueilView()
            case .guemara:
                ListeOeuvresView(collectionID: "guemara")
            case .hassidout:
                ListeOeuvresView(collectionID: "hassidout")
            case .halakha:
                ListeOeuvresView(collectionID: "halakha")
            case .espace:
                EspaceView()
            }
        }
    }
}
