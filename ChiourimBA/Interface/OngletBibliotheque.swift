import SwiftData
import SwiftUI
import UIKit

struct OngletBibliotheque: View {
    let site: Site

    @Environment(NavigationBibliotheque.self) private var navigation
    @Environment(\.modelContext) private var contexte
    @Query private var favoris: [Favori]
    @ObservedObject private var memoire = MemoireLecture.partagee
    @StateObject private var pont = PontLecture()

    @State private var demarre = false
    @State private var urlWeb: URL
    @State private var cheminCourant = "index.html"
    @State private var titre = ""
    @State private var urlPDF: URL?
    @State private var fichierPDF: URL?
    @State private var messagePDF: String?
    @State private var chargementPDF = false
    @State private var jetonPDF = 0
    @State private var nombreLiens = 0
    @State private var telechargement: ProgresTelechargement?
    @State private var tacheTelechargement: Task<Void, Never>?
    @State private var alerte: String?
    @State private var nonce = 0
    @State private var safari: LienSafari?
    @State private var afficherReglages = false
    @State private var afficherRecherche = false

    init(site: Site) {
        self.site = site
        _urlWeb = State(initialValue: site.urlApplication(chemin: "index.html"))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                banniere
                ZStack {
                    if demarre {
                        VueWeb(
                            url: urlWeb,
                            zoom: CGFloat(memoire.zoom),
                            nonce: nonce,
                            siteID: site.id,
                            pont: pont,
                            onPage: pageChargee,
                            onPDF: ouvrirPDF,
                            onExterne: { safari = LienSafari(url: $0) },
                            onCourriel: { UIApplication.shared.open($0) },
                            onAutreSite: { navigation.ouvrir(url: $0) }
                        )
                        .opacity(urlPDF == nil ? 1 : 0)
                        .allowsHitTesting(urlPDF == nil)
                    }
                    if urlPDF != nil {
                        contenuPDF
                    }
                    if pont.chargement && urlPDF == nil {
                        ProgressView()
                            .padding(8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle(titreNavigation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { barre }
        }
        .onAppear(perform: preparer)
        .onChange(of: navigation.jetons[site.id] ?? 0) { _, jeton in
            guard jeton > 0, let url = navigation.destinations[site.id] else { return }
            demarre = true
            appliquer(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .cacheContenuVide)) { _ in
            jetonPDF += 1
            fichierPDF = nil
            nonce += 1
        }
        .sheet(item: $safari) { lien in
            VueSafari(url: lien.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $afficherReglages) {
            VueReglages()
        }
        .sheet(isPresented: $afficherRecherche) {
            FeuilleRecherche()
        }
        .alert("Téléchargement", isPresented: alertePresente) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alerte ?? "")
        }
        .task(id: "\(urlPDF?.absoluteString ?? "")-\(jetonPDF)") {
            await chargerPDF()
        }
    }

    @ViewBuilder
    private var banniere: some View {
        if let telechargement {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(telechargement.fait), total: Double(max(telechargement.total, 1)))
                HStack {
                    Text("\(telechargement.fait) sur \(telechargement.total)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Annuler", role: .cancel) {
                        tacheTelechargement?.cancel()
                        self.telechargement = nil
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        } else if nombreLiens >= 3 && urlPDF == nil {
            Button(action: lancerTelechargement) {
                Label("Télécharger pour lire hors ligne", systemImage: "arrow.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var contenuPDF: some View {
        if chargementPDF {
            ProgressView("Téléchargement du PDF…")
        } else if let fichierPDF {
            VuePDF(url: fichierPDF, zoom: CGFloat(memoire.zoom))
        } else if let messagePDF {
            ContentUnavailableView(messagePDF, systemImage: "wifi.slash")
        }
    }

    @ToolbarContentBuilder
    private var barre: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: retour) {
                Image(systemName: "chevron.backward")
            }
            .disabled(urlPDF == nil && !pont.peutReculer)
            .accessibilityLabel("Retour")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                memoire.reglerZoom(memoire.zoom - 0.1)
            } label: {
                Text("A−")
            }
            .disabled(memoire.zoom <= 0.7)
            .accessibilityLabel("Réduire le texte")

            Button {
                memoire.reglerZoom(memoire.zoom + 0.1)
            } label: {
                Text("A+")
            }
            .disabled(memoire.zoom >= 2)
            .accessibilityLabel("Agrandir le texte")

            Button(action: basculerFavori) {
                Image(systemName: favoriActuel == nil ? "star" : "star.fill")
            }
            .accessibilityLabel(favoriActuel == nil ? "Ajouter aux favoris" : "Retirer des favoris")

            ShareLink(item: site.urlPublique(chemin: cheminCourant)) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Partager")

            Menu {
                Button("Rechercher", systemImage: "magnifyingglass") {
                    afficherRecherche = true
                }
                Button("Réglages", systemImage: "gearshape") {
                    afficherReglages = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Plus")
        }
    }

    private var titreNavigation: String {
        let propre = titre.trimmingCharacters(in: .whitespacesAndNewlines)
        if !propre.isEmpty, propre != PageMessage.titre {
            return propre
        }
        return site.titreOnglet
    }

    private var favoriActuel: Favori? {
        favoris.first { $0.siteID == site.id && $0.chemin == cheminCourant }
    }

    private var alertePresente: Binding<Bool> {
        Binding(
            get: { alerte != nil },
            set: { siOui in if !siOui { alerte = nil } }
        )
    }

    private func preparer() {
        guard !demarre else { return }
        if let url = navigation.destinations[site.id] {
            appliquer(url)
        } else if let chemin = memoire.cheminDernier(siteID: site.id) {
            appliquer(site.urlApplication(chemin: chemin))
        }
        demarre = true
    }

    private func appliquer(_ url: URL) {
        guard let chemin = CheminContenu.normaliser(url.path) else { return }
        cheminCourant = chemin
        memoire.memoriser(siteID: site.id, chemin: chemin)
        if chemin.lowercased().hasSuffix(".pdf") {
            urlPDF = url
            jetonPDF += 1
        } else {
            urlPDF = nil
            fichierPDF = nil
            messagePDF = nil
            urlWeb = url
        }
    }

    private func pageChargee(_ url: URL, _ titrePage: String) {
        guard url.host?.lowercased() == site.id else { return }
        guard let chemin = CheminContenu.normaliser(url.path) else { return }
        if chemin.lowercased().hasSuffix(".pdf") {
            ouvrirPDF(url)
            return
        }
        titre = titrePage
        cheminCourant = chemin
        urlWeb = url
        memoire.memoriser(siteID: site.id, chemin: chemin)
        enregistrerHistorique(chemin: chemin, titre: titrePage)
        let demande = chemin
        nombreLiens = 0
        Task {
            let nombre = await PasserelleContenu.partagee.nombrePagesLiees(site: site, chemin: demande)
            if cheminCourant == demande {
                nombreLiens = nombre
            }
        }
    }

    private func ouvrirPDF(_ url: URL) {
        guard let chemin = CheminContenu.normaliser(url.path) else { return }
        cheminCourant = chemin
        titre = (chemin as NSString).lastPathComponent
        urlPDF = url
        jetonPDF += 1
        memoire.memoriser(siteID: site.id, chemin: chemin)
        nombreLiens = 0
    }

    private func retour() {
        if urlPDF != nil {
            urlPDF = nil
            fichierPDF = nil
            messagePDF = nil
            if let actuelle = pont.vue?.url, let chemin = CheminContenu.normaliser(actuelle.path) {
                cheminCourant = chemin
                titre = pont.vue?.title ?? ""
                memoire.memoriser(siteID: site.id, chemin: chemin)
            }
            return
        }
        pont.retour()
    }

    private func basculerFavori() {
        if let favoriActuel {
            contexte.delete(favoriActuel)
            return
        }
        contexte.insert(
            Favori(
                titre: titrePourFavori,
                siteID: site.id,
                chemin: cheminCourant,
                ajouteLe: .now
            )
        )
    }

    private var titrePourFavori: String {
        let propre = titre.trimmingCharacters(in: .whitespacesAndNewlines)
        if !propre.isEmpty, propre != PageMessage.titre {
            return propre
        }
        return (cheminCourant as NSString).lastPathComponent
    }

    private func enregistrerHistorique(chemin: String, titre titrePage: String) {
        let propre = titrePage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !propre.isEmpty, propre != PageMessage.titre else { return }
        let descripteur = FetchDescriptor<EntreeHistorique>()
        let existantes = (try? contexte.fetch(descripteur)) ?? []
        if let deja = existantes.first(where: { $0.siteID == site.id && $0.chemin == chemin }) {
            deja.titre = propre
            deja.visiteLe = .now
        } else {
            contexte.insert(
                EntreeHistorique(titre: propre, siteID: site.id, chemin: chemin, visiteLe: .now)
            )
        }
        let apres = (try? contexte.fetch(FetchDescriptor<EntreeHistorique>(
            sortBy: [SortDescriptor(\.visiteLe, order: .reverse)]
        ))) ?? []
        if apres.count > 300 {
            for entree in apres.dropFirst(300) {
                contexte.delete(entree)
            }
        }
    }

    private func lancerTelechargement() {
        let chemin = cheminCourant
        tacheTelechargement?.cancel()
        telechargement = ProgresTelechargement(fait: 0, total: 1)
        tacheTelechargement = Task {
            do {
                for try await progres in PasserelleContenu.partagee.telechargerHorsLigne(site: site, chemin: chemin) {
                    telechargement = progres
                    if progres.total == 0 {
                        telechargement = nil
                        alerte = "Aucune page liée à télécharger."
                        return
                    }
                }
                telechargement = nil
            } catch is CancellationError {
                telechargement = nil
            } catch {
                telechargement = nil
                alerte = "Le téléchargement a été interrompu."
            }
        }
    }

    private func chargerPDF() async {
        guard let urlPDF else {
            fichierPDF = nil
            messagePDF = nil
            chargementPDF = false
            return
        }
        chargementPDF = true
        messagePDF = nil
        do {
            fichierPDF = try await PasserelleContenu.partagee.fichier(pour: urlPDF)
        } catch EchecContenu.horsLigne {
            fichierPDF = nil
            messagePDF = PageMessage.horsLigne
        } catch EchecContenu.introuvable {
            fichierPDF = nil
            messagePDF = "Cette page est introuvable."
        } catch {
            fichierPDF = nil
            messagePDF = "Impossible de télécharger cette page."
        }
        chargementPDF = false
    }
}

extension Notification.Name {
    static let cacheContenuVide = Notification.Name("fr.chiourimsba.cache.vide")
}
