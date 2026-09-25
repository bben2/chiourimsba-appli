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
    @Environment(\.horizontalSizeClass) private var classe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                EnteteSite(
                    hebreu: "שיעורים",
                    titre: "Chiourim BA",
                    sousTitre: "Les chiourim de la semaine, et une bibliothèque de textes traduits intégralement en français, face à l'hébreu."
                )

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

                VStack(alignment: .leading, spacing: 12) {
                    enteteSection("La bibliothèque", "Trois collections, toutes bilingues hébreu-français")
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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                            ForEach(idsCollections, id: \.self) { id in
                                boutonCollection(id)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    enteteSection("Aller plus loin", "Le portail, les questions et les livres")
                    NavigationLink(value: RouteWeb(titre: "Chiourim BA", url: Config.urlPortail, discussion: false)) {
                        carteLien(titre: "Chiourim BA", detail: "Les chiourim de la semaine, sur le portail", or: "שיעורים")
                    }
                    .buttonStyle(StylePlein())
                    NavigationLink(value: RouteWeb(titre: "Questions à l'IA", url: Config.urlPortail, discussion: true)) {
                        carteLien(titre: "Questions à l'IA", detail: "La page de discussion du portail", or: "שאלות")
                    }
                    .buttonStyle(StylePlein())
                    NavigationLink {
                        LivresView()
                    } label: {
                        carteLien(titre: "Nos livres", detail: LivresPapier.liens.isEmpty ? "Bientôt" : "Les éditions imprimées", or: "ספרים")
                    }
                    .buttonStyle(StylePlein())
                    if let url = Config.urlDons {
                        NavigationLink(value: RouteWeb(titre: "Nous soutenir", url: url, discussion: false)) {
                            carteLien(titre: "Nous soutenir", detail: "Participer aux traductions", or: "תודה")
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
            .padding(.top, 8)
            .padding(.bottom, 28)
            .largeurSite(1040)
        }
        .background(Theme.fond)
        .navigationTitle("Chiourim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(classe == .regular ? .visible : .hidden, for: .navigationBar)
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

    private func enteteSection(_ titre: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titre)
                .font(.system(size: classe == .regular ? 20 : 18, weight: .semibold))
                .foregroundStyle(Theme.bleu)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(.system(size: 14))
                .foregroundStyle(Theme.gris)
        }
    }

    private func carteReprise(_ position: PositionLecture) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reprendre la lecture")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(Theme.or)
            Text(position.titrePage.isEmpty ? position.unite : position.titrePage)
                .font(Polices.titre(22))
                .foregroundStyle(Theme.encreInverse)
            Text(position.resume.isEmpty ? position.oeuvreTitre : position.resume)
                .font(.system(size: 15))
                .foregroundStyle(Color(red: 0.910, green: 0.886, blue: 0.847))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.bleu, in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.or).frame(width: 4).padding(.vertical, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            CarteSite {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hebreu)
                        .font(Polices.hebreu(22))
                        .foregroundStyle(Theme.or)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text(titre)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.encre)
                    Text(Libelles.sousTitreCollection(id))
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.gris)
                    Text(Libelles.compteOeuvres(nombre, collection: id))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.or)
                        .padding(.top, 2)
                }
            }
        }
        .buttonStyle(StylePlein())
        .accessibilityLabel("\(titre), \(detailCollection(id, nombre: nombre))")
    }

    private func carteLien(titre: String, detail: String, or: String) -> some View {
        CarteSite {
            VStack(alignment: .leading, spacing: 4) {
                Text(or)
                    .font(Polices.hebreu(20))
                    .foregroundStyle(Theme.or)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityHidden(true)
                Text(titre)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.encre)
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.gris)
            }
        }
    }

    private func detailCollection(_ id: String, nombre: Int) -> String {
        let compte = Libelles.compteOeuvres(nombre, collection: id)
        let sous = Libelles.sousTitreCollection(id)
        if sous.isEmpty { return compte }
        if id == "halakha", nombre == 0 { return sous }
        return "\(compte) · \(sous)"
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
