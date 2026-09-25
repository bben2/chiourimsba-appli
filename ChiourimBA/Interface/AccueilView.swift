import SwiftData
import SwiftUI

private struct RouteWeb: Hashable {
    var titre: String
    var url: URL
    var discussion: Bool
}

struct AccueilView: View {
    @Environment(MagasinTextes.self) private var magasin
    @Environment(NavigationApp.self) private var navigation
    @Query(sort: \PositionLecture.miseAJour, order: .reverse) private var positions: [PositionLecture]
    @ScaledMetric(relativeTo: .largeTitle) private var tailleTitre: CGFloat = 36

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bibliothèque bilingue")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.gris)
                    Text("Chiourim BA")
                        .font(Polices.titre(tailleTitre))
                        .foregroundStyle(Theme.bleu)
                        .accessibilityAddTraits(.isHeader)
                }

                if let position = positions.first {
                    NavigationLink {
                        LectureView(
                            collectionID: position.collectionID,
                            oeuvreID: position.oeuvreID,
                            unite: position.unite,
                            indexInitial: position.indexSegment
                        )
                    } label: {
                        carteReprise(position)
                    }
                    .buttonStyle(StylePlein())
                    .accessibilityHint("Ouvre la dernière page lue")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("La bibliothèque")
                        .font(Polices.titre(22))
                        .foregroundStyle(Theme.encre)
                        .accessibilityAddTraits(.isHeader)
                    if magasin.chargementCatalogue && magasin.catalogue == nil {
                        SqueletteLignes(nombre: 3)
                    } else if let erreur = magasin.erreurCatalogue, magasin.catalogue == nil {
                        EtatPlace(
                            symbole: "wifi.slash",
                            titre: "Catalogue indisponible",
                            detail: erreur,
                            actionTitre: "Réessayer"
                        ) {
                            Task { await magasin.rafraichirCatalogue(force: true) }
                        }
                    } else {
                        ForEach(idsCollections, id: \.self) { id in
                            boutonCollection(id)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Aller plus loin")
                        .font(Polices.titre(22))
                        .foregroundStyle(Theme.encre)
                        .accessibilityAddTraits(.isHeader)
                    NavigationLink(value: RouteWeb(titre: "Chiourim BA", url: Config.urlPortail, discussion: false)) {
                        ligneSimple(titre: "Chiourim BA", detail: "Les chiourim de la semaine, sur le portail")
                    }
                    .buttonStyle(StylePlein())
                    NavigationLink(value: RouteWeb(titre: "Questions à l'IA", url: Config.urlPortail, discussion: true)) {
                        ligneSimple(titre: "Questions à l'IA", detail: "La page de discussion du portail")
                    }
                    .buttonStyle(StylePlein())
                    NavigationLink {
                        LivresView()
                    } label: {
                        ligneSimple(titre: "Nos livres", detail: LivresPapier.liens.isEmpty ? "Bientôt" : "Les éditions imprimées")
                    }
                    .buttonStyle(StylePlein())
                    if let url = Config.urlDons {
                        NavigationLink(value: RouteWeb(titre: "Nous soutenir", url: url, discussion: false)) {
                            ligneSimple(titre: "Nous soutenir", detail: "Participer aux traductions")
                        }
                        .buttonStyle(StylePlein())
                    }
                }

                if !ReseauEtat.partage.enLigne {
                    EtatPlace(
                        symbole: "wifi.slash",
                        titre: "Hors connexion",
                        detail: "Seules les pages déjà ouvertes ou téléchargées restent lisibles."
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Theme.fond)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: RouteWeb.self) { route in
            VuePortail(url: route.url, ouvrirDiscussion: route.discussion)
                .navigationTitle(route.titre)
                .navigationBarTitleDisplayMode(.inline)
                .background(Theme.fond)
        }
        .refreshable { await magasin.rafraichirCatalogue(force: true) }
    }

    private var idsCollections: [String] {
        let connus = ["guemara", "hassidout", "halakha"]
        if let ids = magasin.catalogue?.collections.map(\.id), !ids.isEmpty {
            return connus.filter { ids.contains($0) } + ids.filter { !connus.contains($0) }
        }
        return connus
    }

    private func carteReprise(_ position: PositionLecture) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reprendre la lecture")
                .font(.system(size: 12, weight: .regular))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.914, green: 0.851, blue: 0.659))
            Text(position.titrePage.isEmpty ? position.unite : position.titrePage)
                .font(Polices.titre(22))
                .foregroundStyle(Theme.encreInverse)
            if !position.resume.isEmpty {
                Text(position.resume)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.875, green: 0.902, blue: 0.933))
                    .lineLimit(2)
            } else {
                Text(position.oeuvreTitre)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.875, green: 0.902, blue: 0.933))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.bleu, in: RoundedRectangle(cornerRadius: 16))
        .frame(minHeight: 44)
    }

    private func boutonCollection(_ id: String) -> some View {
        let collection = magasin.collection(id)
        let nombre = collection?.oeuvres.count ?? 0
        let hebreu = collection?.titreHe ?? hebreuSecours(id)
        let titre = collection?.titre ?? titreSecours(id)
        return Button {
            switch id {
            case "guemara": navigation.onglet = .guemara
            case "hassidout": navigation.onglet = .hassidout
            case "halakha": navigation.onglet = .halakha
            default: break
            }
        } label: {
            HStack(spacing: 14) {
                TexteJustifie(texte: hebreu, police: Polices.hebreu, taille: 22, rtl: true, etirer: false, teinte: "Or")
                    .frame(width: 72)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titre)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.encre)
                    Text(detailCollection(id, nombre: nombre))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.gris)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.gris)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
        }
        .buttonStyle(StylePlein())
        .accessibilityLabel("\(titre), \(detailCollection(id, nombre: nombre))")
    }

    private func detailCollection(_ id: String, nombre: Int) -> String {
        let compte = Libelles.compteOeuvres(nombre, collection: id)
        let sous = Libelles.sousTitreCollection(id)
        if sous.isEmpty { return compte }
        if id == "halakha", nombre == 0 { return sous }
        return "\(compte) · \(sous)"
    }

    private func ligneSimple(titre: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(titre)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.encre)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.gris)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.gris)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.filet).frame(height: 1) }
    }

    private func hebreuSecours(_ id: String) -> String {
        switch id {
        case "guemara": return "גמרא"
        case "hassidout": return "חסידות"
        case "halakha": return "הלכה"
        default: return ""
        }
    }

    private func titreSecours(_ id: String) -> String {
        switch id {
        case "guemara": return "Guemara"
        case "hassidout": return "Hassidout"
        case "halakha": return "Halakha"
        default: return id
        }
    }
}

struct LivresView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var safari: LienExterne?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BoutonRetour(titre: "Chiourim") { dismiss() }
                TitreEcran(texte: "Nos livres")
                if LivresPapier.liens.isEmpty {
                    EtatPlace(
                        symbole: "book.closed",
                        titre: "Bientôt",
                        detail: "Les livres imprimés seront proposés ici."
                    )
                } else {
                    ForEach(LivresPapier.liens) { lien in
                        Button {
                            safari = LienExterne(url: lien.url)
                        } label: {
                            HStack {
                                Text(lien.titre)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Theme.encre)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(Theme.bleu)
                            }
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(StylePlein())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Theme.fond)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $safari) { lien in
            VueSafari(url: lien.url)
                .ignoresSafeArea()
        }
    }
}

struct LienExterne: Identifiable {
    var id: String { url.absoluteString }
    var url: URL
}
