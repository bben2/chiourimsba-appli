import SwiftData
import SwiftUI

@main
struct ChiourimBAApp: App {
    private let conteneur: ModelContainer

    init() {
        let schema = Schema([Favori.self, EntreeHistorique.self])
        do {
            conteneur = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            )
        } catch {
            do {
                conteneur = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Le stockage local est indisponible : \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RacineView()
        }
        .modelContainer(conteneur)
    }
}

struct RacineView: View {
    @State private var navigation = NavigationBibliotheque()

    var body: some View {
        TabView(selection: Binding(
            get: { navigation.onglet },
            set: { navigation.onglet = $0 }
        )) {
            ForEach(Bibliotheque.sites) { site in
                OngletBibliotheque(site: site)
                    .tabItem { Label(site.titreOnglet, systemImage: site.symbole) }
                    .tag(OngletApp.site(site.id))
            }
            FavorisView()
                .tabItem { Label("Favoris", systemImage: "star") }
                .tag(OngletApp.favoris)
        }
        .environment(navigation)
        .tint(Color.accentColor)
        .task {
            while !Task.isCancelled {
                await PasserelleContenu.partagee.verifierRevisionsSiBesoin()
                try? await Task.sleep(for: .seconds(3600))
            }
        }
    }
}
