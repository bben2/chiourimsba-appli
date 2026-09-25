import SwiftUI

struct RouteSommaire: Hashable {
    var collectionID: String
    var oeuvreID: String
}

struct RouteLecture: Hashable {
    var collectionID: String
    var oeuvreID: String
    var unite: String
}

struct ListeOeuvresView: View {
    var collectionID: String
    @Environment(MagasinTextes.self) private var magasin
    @State private var recherche = ""
    @State private var safari: LienExterne?
    @ScaledMetric(relativeTo: .largeTitle) private var tailleTitre: CGFloat = 34

    var body: some View {
        let collection = magasin.collection(collectionID)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(collection?.titre ?? titreSecours)
                    .font(Polices.titre(tailleTitre))
                    .foregroundStyle(Theme.bleu)
                    .accessibilityAddTraits(.isHeader)

                if collectionID != "halakha" {
                    champRecherche
                }

                contenu(collection)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.fond)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: RouteSommaire.self) { route in
            SommaireView(collectionID: route.collectionID, oeuvreID: route.oeuvreID)
        }
        .navigationDestination(for: RouteLecture.self) { route in
            LectureView(collectionID: route.collectionID, oeuvreID: route.oeuvreID, unite: route.unite, indexInitial: 0)
        }
        .refreshable { await magasin.rafraichirCatalogue(force: true) }
        .sheet(item: $safari) { lien in
            VueSafari(url: lien.url).ignoresSafeArea()
        }
    }

    private var titreSecours: String {
        switch collectionID {
        case "guemara": return "Guemara"
        case "hassidout": return "Hassidout"
        case "halakha": return "Halakha"
        default: return collectionID
        }
    }

    private var champRecherche: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.gris)
                .accessibilityHidden(true)
            TextField(collectionID == "guemara" ? "Chercher un traité ou un daf" : "Chercher un livre", text: $recherche)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.body)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Theme.champ, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func contenu(_ collection: CollectionDonnees?) -> some View {
        if magasin.chargementCatalogue && collection == nil && magasin.erreurCatalogue == nil {
            SqueletteLignes()
        } else if collection == nil, let erreur = magasin.erreurCatalogue {
            EtatPlace(symbole: "wifi.slash", titre: "Catalogue indisponible", detail: erreur, actionTitre: "Réessayer") {
                Task { await magasin.rafraichirCatalogue(force: true) }
            }
        } else if collectionID == "halakha", (collection?.oeuvres.isEmpty ?? true) {
            EtatPlace(
                symbole: "scalemass",
                titre: "Bientôt dans l'appli",
                detail: "Le Choulhan Aroukh et ses abrégés seront lisibles ici. En attendant, le site reste ouvert.",
                actionTitre: "Ouvrir le site Halakha"
            ) {
                safari = LienExterne(url: Config.urlHalakha)
            }
        } else if collectionID == "guemara" {
            let groupes = OrdreTalmud.groupes(filtrees(collection?.oeuvres ?? []))
            if groupes.isEmpty {
                EtatPlace(symbole: "magnifyingglass", titre: "Aucun résultat", detail: "Aucun traité ne correspond à cette recherche.")
            } else {
                ForEach(groupes) { groupe in
                    section(titre: groupe.nom, oeuvres: groupe.oeuvres)
                }
            }
        } else {
            let oeuvres = filtrees(collection?.oeuvres ?? [])
            if oeuvres.isEmpty {
                EtatPlace(symbole: "book", titre: "Aucun texte pour le moment", detail: "Cette collection est encore vide.")
            } else {
                liste(oeuvres)
            }
        }
    }

    private func filtrees(_ oeuvres: [Oeuvre]) -> [Oeuvre] {
        let q = recherche.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return oeuvres }
        let cle = q.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
        return oeuvres.filter { oeuvre in
            let champs = [oeuvre.titre, oeuvre.titreHe, oeuvre.auteur ?? "", oeuvre.id] + oeuvre.unites
            return champs.contains {
                $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).localizedStandardContains(cle)
                    || $0.lowercased().contains(cle.lowercased())
            }
        }
    }

    private func section(titre: String, oeuvres: [Oeuvre]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titre)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(Theme.gris)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
            liste(oeuvres)
        }
    }

    private func liste(_ oeuvres: [Oeuvre]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(oeuvres.enumerated()), id: \.element.id) { index, oeuvre in
                NavigationLink(value: RouteSommaire(collectionID: collectionID, oeuvreID: oeuvre.id)) {
                    ligne(oeuvre, premiere: index == 0)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
    }

    private func ligne(_ oeuvre: Oeuvre, premiere: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(oeuvre.titre)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.encre)
                Text(detail(oeuvre))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.gris)
            }
            Spacer(minLength: 0)
            TexteJustifie(texte: oeuvre.titreHe, police: Polices.hebreu, taille: 18, rtl: true, etirer: false, teinte: "Or")
            if magasin.pretsHorsLigne.contains(oeuvre.id) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.vert)
                    .accessibilityLabel("Lisible hors ligne")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 44)
        .overlay(alignment: .top) {
            if !premiere { Rectangle().fill(Theme.filet).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }

    private func detail(_ oeuvre: Oeuvre) -> String {
        var morceaux = [Libelles.compteUnites(oeuvre.unites.count, collection: collectionID)]
        if let auteur = oeuvre.auteur, !auteur.isEmpty { morceaux.insert(auteur, at: 0) }
        return morceaux.joined(separator: " · ")
    }
}
