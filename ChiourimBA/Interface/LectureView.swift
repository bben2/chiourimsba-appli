import SwiftData
import SwiftUI

struct LectureView: View {
    var collectionID: String
    var oeuvreID: String
    var uniteDepart: String
    var indexInitial: Int

    @State private var uniteCourante: String

    init(collectionID: String, oeuvreID: String, unite: String, indexInitial: Int) {
        self.collectionID = collectionID
        self.oeuvreID = oeuvreID
        self.uniteDepart = unite
        self.indexInitial = indexInitial
        _uniteCourante = State(initialValue: unite)
    }

    private var unite: String { uniteCourante }

    @Environment(MagasinTextes.self) private var magasin
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var classe
    @Environment(\.verticalSizeClass) private var classeVerticale
    @Environment(\.modelContext) private var contexte
    @Query private var favoris: [Favori]
    @Query private var annotations: [AnnotationLocale]
    @Query private var positions: [PositionLecture]
    @Query private var lues: [UniteLue]

    @AppStorage(ReglagesLocaux.cleEchelle) private var echelle = 1.0
    @AppStorage(ReglagesLocaux.cleDisposition) private var dispositionBrute = DispositionTexte.auto.rawValue

    @State private var page: PageTexte?
    @State private var erreur: String?
    @State private var chargement = true
    @State private var segmentVisible: Int?
    @State private var feuille: Int?
    @ScaledMetric(relativeTo: .body) private var tailleFR: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var tailleHE: CGFloat = 22

    var body: some View {
        VStack(spacing: 0) {
            barreHaut
            contenu
            barreBas
        }
        .background(Theme.papier)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: uniteCourante) { await charger() }
        .sheet(item: cibleFeuille) { cible in
            FeuilleAnnotation(
                passage: passage(cible.index),
                peutSignaler: siteSignalement != nil,
                onSurligner: { enregistrer(index: cible.index, note: "", surlignage: true) },
                onAnnoter: { texte in enregistrer(index: cible.index, note: texte, surlignage: false) },
                onSignaler: { correction in await signaler(index: cible.index, correction: correction) }
            )
        }
    }

    private var cibleFeuille: Binding<CibleSegment?> {
        Binding(
            get: { feuille.map { CibleSegment(index: $0) } },
            set: { feuille = $0?.index }
        )
    }

    /// `scrollPosition` appelle le setter pendant `layoutSubviews`. Écrire `@State` à cet instant
    /// fait avorter AttributeGraph (`value_set` dans `beginNextUpdate`).
    private var positionDefilement: Binding<Int?> {
        Binding(
            get: { segmentVisible },
            set: { nouveau in
                guard let nouveau, nouveau != segmentVisible else { return }
                let valeur = nouveau
                Task { @MainActor in
                    await Task.yield()
                    guard segmentVisible != valeur else { return }
                    segmentVisible = valeur
                }
            }
        )
    }

    private var oeuvre: Oeuvre? { magasin.oeuvre(collection: collectionID, id: oeuvreID) }

    private var unites: [String] { oeuvre?.unites ?? [] }

    private var indexUnite: Int { unites.firstIndex(of: unite) ?? 0 }

    private var cleFavori: String { "\(collectionID)|\(oeuvreID)|\(unite)" }

    private var estFavori: Bool { favoris.contains { $0.cle == cleFavori } }

    private var coteACote: Bool {
        switch DispositionTexte(rawValue: dispositionBrute) ?? .auto {
        case .empile: return false
        case .cote: return true
        case .auto: return classe == .regular || classeVerticale == .compact
        }
    }

    private var siteSignalement: String? {
        if collectionID == "guemara" || collectionID == "hassidout" { return collectionID }
        return nil
    }

    private var pageHTML: String {
        SourceDonnees.pageHTML(collectionID: collectionID, oeuvreID: oeuvreID, unite: unite)
    }

    private var urlPartage: URL? {
        SourceDonnees.urlPartage(collectionID: collectionID, page: pageHTML)
    }

    private var horsLigne: Bool {
        let chemin = SourceDonnees.cheminPage(
            collectionID: collectionID,
            oeuvreID: oeuvreID,
            unite: unite,
            cheminOeuvre: oeuvre?.chemin
        )
        return CacheDisque.standard().existe(chemin)
    }

    private var barreHaut: some View {
        HStack(spacing: 0) {
            BoutonRetour(titre: oeuvre?.titre ?? "Retour") { sauverPosition(); dismiss() }
            Spacer(minLength: 0)
            Button {
                echelle = max(0.85, echelle - 0.05)
            } label: {
                Text("A−").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Réduire le texte")
            Button {
                echelle = min(1.45, echelle + 0.05)
            } label: {
                Text("A+").font(.body).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Agrandir le texte")
            Button {
                basculerFavori()
            } label: {
                Image(systemName: estFavori ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(Theme.or)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(estFavori ? "Retirer des favoris" : "Ajouter aux favoris")
            if let urlPartage {
                ShareLink(item: urlPartage) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Partager")
            }
        }
        .padding(.horizontal, 8)
        .background(Theme.fond)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.filet).frame(height: 1) }
        .foregroundStyle(Theme.bleu)
    }

    @ViewBuilder
    private var contenu: some View {
        if chargement && page == nil {
            SqueletteLignes(nombre: 4)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let erreur, page == nil {
            EtatPlace(
                symbole: "wifi.slash",
                titre: "Page indisponible",
                detail: erreur,
                actionTitre: "Réessayer"
            ) { Task { await charger() } }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let page {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    Text(titreAffiche(page))
                        .font(Polices.titre(25))
                        .foregroundStyle(Theme.bleu)
                        .accessibilityAddTraits(.isHeader)
                    if let resume = page.resume, !resume.isEmpty {
                        Text(resume)
                            .font(.subheadline)
                            .foregroundStyle(Theme.gris)
                    }
                    ForEach(Array(page.segments.enumerated()), id: \.offset) { index, segment in
                        bloc(segment, index: index)
                            .id(index)
                    }
                    ForEach(Array(page.schemas.enumerated()), id: \.offset) { _, schema in
                        BoiteSchema(schema: schema)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .scrollTargetLayout()
            }
            .scrollPosition(id: positionDefilement, anchor: .top)
            .onChange(of: segmentVisible) { _, _ in
                Task { @MainActor in
                    await Task.yield()
                    sauverPosition()
                }
            }
            .simultaneousGesture(glissement)
        }
    }

    private var glissement: some Gesture {
        DragGesture(minimumDistance: 48, coordinateSpace: .local)
            .onEnded { valeur in
                let horizontal = valeur.translation.width
                let vertical = valeur.translation.height
                guard abs(horizontal) > abs(vertical) * 1.6 else { return }
                if horizontal < -40 { aller(1) }
                if horizontal > 40 { aller(-1) }
            }
    }

    private func bloc(_ segment: Segment, index: Int) -> some View {
        let surligne = annotations.contains { $0.collectionID == collectionID && $0.oeuvreID == oeuvreID && $0.unite == unite && $0.indexSegment == index && $0.surlignage }
        return VStack(alignment: .leading, spacing: 12) {
            if coteACote {
                HStack(alignment: .top, spacing: 16) {
                    texteFR(segment.fr, surligne: surligne)
                    texteHE(segment.he)
                }
            } else {
                texteHE(segment.he)
                texteFR(segment.fr, surligne: surligne)
            }
            if !segment.rashi.isEmpty {
                gloses("Rachi", segment.rashi, fond: Theme.fond, grise: false)
            }
            if !segment.tosafot.isEmpty {
                gloses("Tossefot", segment.tosafot, fond: Theme.champ, grise: true)
            }
            if !segment.roch.isEmpty {
                gloses("Roch", segment.roch, fond: Theme.fond, grise: false)
            }
            if let explication = segment.explication, !explication.isEmpty {
                DisclosureGroup {
                    Text(HTMLSimple.attribue(explication, taille: tailleFR * echelle))
                        .foregroundStyle(Theme.encre)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                } label: {
                    Text("Pour comprendre")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.bleu)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .background(Theme.fond, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.filet, lineWidth: 1))
            }
            if let schema = segment.schema {
                BoiteSchema(schema: schema)
            }
            Button("Annoter ou signaler") { feuille = index }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
        }
        .padding(.vertical, 4)
        .onLongPressGesture(minimumDuration: 0.45) { feuille = index }
        .accessibilityHint("Maintenez appuyé pour annoter ou signaler")
        .accessibilityAction(named: "Annoter ou signaler") { feuille = index }
    }

    private func texteHE(_ texte: String) -> some View {
        TexteJustifie(texte: texte, police: Polices.hebreu, taille: tailleHE * echelle, rtl: true)
    }

    private func texteFR(_ texte: String, surligne: Bool) -> some View {
        TexteJustifie(texte: texte, police: Polices.garamond, taille: tailleFR * echelle, rtl: false)
            .padding(.horizontal, surligne ? 4 : 0)
            .background(surligne ? Theme.surbrillance : Color.clear)
    }

    private func gloses(_ nom: String, _ gloses: [Glose], fond: Color, grise: Bool) -> some View {
        let mot = gloses.count == 1 ? "glose" : "gloses"
        return DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(gloses.enumerated()), id: \.offset) { _, glose in
                    VStack(alignment: .leading, spacing: 6) {
                        if let dh = glose.dh, !dh.isEmpty {
                            TexteJustifie(texte: dh, police: Polices.hebreuGras, taille: tailleHE * echelle * 0.82, rtl: true)
                                .accessibilityLabel("Mot d'entrée \(dh)")
                        }
                        if let he = glose.he, !he.isEmpty {
                            TexteJustifie(texte: he, police: Polices.hebreu, taille: tailleHE * echelle * 0.82, rtl: true)
                        }
                        if let fr = glose.fr, !fr.isEmpty {
                            TexteJustifie(texte: fr, police: Polices.garamond, taille: tailleFR * echelle * 0.92, rtl: false)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            Text("\(nom) · \(gloses.count) \(mot)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.bleu)
                .frame(minHeight: 44, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(fond, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(grise ? Color.clear : Theme.filet, lineWidth: 1))
    }

    private var barreBas: some View {
        HStack {
            Button {
                aller(-1)
            } label: {
                Text("‹ Précédent")
                    .frame(minHeight: 44)
            }
            .disabled(indexUnite <= 0 || unites.isEmpty)
            Spacer()
            Text(horsLigne ? "Lisible hors ligne" : "En ligne")
                .font(.system(size: 13))
                .foregroundStyle(horsLigne ? Theme.vert : Theme.gris)
            Spacer()
            Button {
                aller(1)
            } label: {
                Text(titreSuivant)
                    .frame(minHeight: 44)
            }
            .disabled(unites.isEmpty || indexUnite >= unites.count - 1)
        }
        .font(.body)
        .foregroundStyle(Theme.bleu)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(Theme.fond)
        .overlay(alignment: .top) { Rectangle().fill(Theme.filet).frame(height: 1) }
    }

    private var titreSuivant: String {
        guard indexUnite + 1 < unites.count else { return "Suivant ›" }
        let suivant = unites[indexUnite + 1]
        if collectionID == "guemara" {
            return "\(oeuvre?.titre ?? "") \(suivant) ›"
        }
        return "\(suivant) ›"
    }

    private func titreAffiche(_ page: PageTexte) -> String {
        if page.titre.isEmpty { return page.ref.isEmpty ? unite : page.ref }
        if page.ref.isEmpty || page.titre.contains(page.ref) { return page.titre }
        return "\(page.ref) — \(page.titre)"
    }

    private func passage(_ index: Int) -> String {
        guard let segment = page?.segments[safe: index] else { return "" }
        let texte = segment.fr.isEmpty ? segment.he : segment.fr
        if texte.count <= 500 { return texte }
        return String(texte.prefix(500))
    }

    private func charger() async {
        let demande = uniteCourante
        chargement = true
        erreur = nil
        page = nil
        let chemin = SourceDonnees.cheminPage(
            collectionID: collectionID,
            oeuvreID: oeuvreID,
            unite: unite,
            cheminOeuvre: oeuvre?.chemin
        )
        do {
            let chargee = try await magasin.ouvrirPage(chemin: chemin)
            if Task.isCancelled || demande != uniteCourante { return }
            let index: Int
            if let deja = positions.first(where: { $0.cle == "\(collectionID)|\(oeuvreID)" }), deja.unite == unite {
                index = deja.indexSegment
            } else if unite == uniteDepart {
                index = indexInitial
            } else {
                index = 0
            }
            segmentVisible = index
            page = chargee
            erreur = nil
            chargement = false
            // Laisser la première mise en page se terminer avant d'écrire SwiftData :
            // un @Query invalidé pendant layoutSubviews reproduit le même SIGABRT.
            await Task.yield()
            if Task.isCancelled || demande != uniteCourante { return }
            marquerLue()
            sauverPosition()
            return
        } catch let erreurDonnees as ErreurDonnees {
            if page == nil { erreur = erreurDonnees.message }
        } catch {
            if page == nil { erreur = ErreurDonnees.reseau.message }
        }
        chargement = false
    }

    private func aller(_ delta: Int) {
        let suivant = indexUnite + delta
        guard unites.indices.contains(suivant) else { return }
        sauverPosition()
        uniteCourante = unites[suivant]
    }

    private func basculerFavori() {
        if let existant = favoris.first(where: { $0.cle == cleFavori }) {
            contexte.delete(existant)
        } else {
            let titre = page?.titre.isEmpty == false ? (page?.titre ?? unite) : "\(oeuvre?.titre ?? oeuvreID) \(unite)"
            contexte.insert(Favori(
                cle: cleFavori,
                collectionID: collectionID,
                oeuvreID: oeuvreID,
                unite: unite,
                titre: titre,
                site: nomSite,
                chemin: pageHTML,
                ajouteLe: Date()
            ))
        }
        try? contexte.save()
    }

    private var nomSite: String {
        switch collectionID {
        case "guemara": return "Guemara"
        case "hassidout": return "Hassidout"
        case "halakha": return "Halakha"
        default: return collectionID
        }
    }

    private func marquerLue() {
        let cle = "\(oeuvreID)/\(unite)"
        guard !lues.contains(where: { $0.cle == cle }) else { return }
        contexte.insert(UniteLue(cle: cle, oeuvreID: oeuvreID, unite: unite))
        try? contexte.save()
    }

    private func sauverPosition() {
        let cle = "\(collectionID)|\(oeuvreID)"
        let index = segmentVisible ?? indexInitial
        let titre = titreAffiche(page ?? PageTexte(ref: unite, titre: "", resume: nil, segments: [], schemas: []))
        let resume = page?.resume ?? ""
        if let existante = positions.first(where: { $0.cle == cle }) {
            existante.unite = unite
            existante.indexSegment = index
            existante.titrePage = titre
            existante.resume = resume
            existante.totalUnites = unites.count
            existante.indexUnite = indexUnite
            existante.miseAJour = Date()
            existante.oeuvreTitre = oeuvre?.titre ?? oeuvreID
        } else {
            contexte.insert(PositionLecture(
                cle: cle,
                collectionID: collectionID,
                oeuvreID: oeuvreID,
                oeuvreTitre: oeuvre?.titre ?? oeuvreID,
                unite: unite,
                indexSegment: index,
                titrePage: titre,
                resume: resume,
                totalUnites: unites.count,
                indexUnite: indexUnite,
                miseAJour: Date()
            ))
        }
        try? contexte.save()
    }

    private func enregistrer(index: Int, note: String, surlignage: Bool) {
        contexte.insert(AnnotationLocale(
            id: UUID(),
            collectionID: collectionID,
            oeuvreID: oeuvreID,
            oeuvreTitre: oeuvre?.titre ?? oeuvreID,
            unite: unite,
            indexSegment: index,
            passage: passage(index),
            note: note,
            surlignage: surlignage,
            creeLe: Date()
        ))
        try? contexte.save()
    }

    private func signaler(index: Int, correction: String) async -> String {
        guard let site = siteSignalement else { return "Le signalement n'est pas ouvert pour cette collection." }
        let fichier = FileSignalements.standard()
        do {
            let entree = try fichier.ajouter(site: site, page: pageHTML, passage: passage(index), correction: correction)
            let issue = await SignalementService.envoyer(entree, session: .shared, fichier: fichier)
            return issue.message
        } catch {
            return ErreurDonnees.reseau.message
        }
    }
}

private struct CibleSegment: Identifiable {
    var id: Int { index }
    var index: Int
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
