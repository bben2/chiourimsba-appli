import SwiftData
import SwiftUI

struct SommaireView: View {
    var collectionID: String
    var oeuvreID: String
    @Environment(MagasinTextes.self) private var magasin
    @Environment(\.dismiss) private var dismiss
    @Query private var lues: [UniteLue]
    @Environment(\.horizontalSizeClass) private var classe
    @State private var recherche = ""

    private var oeuvre: Oeuvre? { magasin.oeuvre(collection: collectionID, id: oeuvreID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if classe != .regular {
                    BoutonRetour(titre: titreParent) { dismiss() }
                }
                entete
                carteTelechargement
                if let oeuvre {
                    grille(oeuvre)
                } else if magasin.chargementCatalogue {
                    SqueletteLignes(nombre: 3)
                } else {
                    EtatPlace(symbole: "book", titre: "Texte introuvable", detail: "Ce livre n'est pas dans le catalogue chargé.")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .largeurSite(1040)
        }
        .background(Theme.fond)
        .navigationTitle(oeuvre?.titre ?? titreParent)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(classe != .regular)
        .toolbar(classe == .regular ? .visible : .hidden, for: .navigationBar)
        .searchable(text: $recherche, prompt: "Rechercher dans le sommaire")
        .navigationDestination(for: RouteLecture.self) { route in
            LectureView(collectionID: route.collectionID, oeuvreID: route.oeuvreID, unite: route.unite, indexInitial: 0)
        }
    }

    private var titreParent: String {
        switch collectionID {
        case "guemara": return "Guemara"
        case "hassidout": return "Hassidout"
        case "halakha": return "Halakha"
        default: return "Retour"
        }
    }

    @ViewBuilder
    private var entete: some View {
        if let oeuvre {
            EnteteSite(
                hebreu: oeuvre.titreHe,
                titre: oeuvre.titre,
                sousTitre: oeuvre.auteur ?? "",
                pastille: Libelles.compteUnites(oeuvre.unites.count, collection: collectionID)
            )
        }
    }

    @ViewBuilder
    private var carteTelechargement: some View {
        if let oeuvre {
            let cours = magasin.telechargement?.oeuvreID == oeuvre.id ? magasin.telechargement : nil
            VStack(alignment: .leading, spacing: 10) {
                if let cours {
                    HStack {
                        Text("Téléchargement hors ligne")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Button("Annuler") { magasin.annulerTelechargement() }
                            .frame(minHeight: 44)
                            .foregroundStyle(Theme.gris)
                    }
                    ProgressView(value: Double(cours.fait), total: Double(max(cours.total, 1)))
                        .tint(Theme.bleu)
                        .accessibilityLabel("Téléchargement du livre")
                    Text("\(cours.fait) sur \(cours.total)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.gris)
                } else if magasin.pretsHorsLigne.contains(oeuvre.id) {
                    Label("Lisible hors ligne", systemImage: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.vert)
                        .frame(minHeight: 44)
                } else {
                    Button {
                        magasin.telecharger(oeuvre: oeuvre)
                    } label: {
                        Text("Télécharger ce livre pour le lire hors ligne")
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.bleu)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
        }
    }

    private func grille(_ oeuvre: Oeuvre) -> some View {
        if let table = oeuvre.table, !table.isEmpty {
            return AnyView(sommaireGroupe(oeuvre, table: table))
        }
        return AnyView(grilleClassique(oeuvre))
    }

    private func grilleClassique(_ oeuvre: Oeuvre) -> some View {
        let halakha = collectionID == "halakha"
        let colonnes = halakha
            ? [GridItem(.adaptive(minimum: 108), spacing: 8)]
            : Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
        return VStack(alignment: .leading, spacing: 8) {
            Text(halakha ? "Simanim" : (collectionID == "guemara" ? "Feuillets" : "Sections"))
                .font(.system(size: classe == .regular ? 20 : 18, weight: .semibold))
                .foregroundStyle(Theme.bleu)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: colonnes, spacing: 8) {
                ForEach(oeuvre.unites, id: \.self) { unite in
                    let libelle = Libelles.libelleUnite(unite, collection: collectionID)
                    NavigationLink(value: RouteLecture(collectionID: collectionID, oeuvreID: oeuvre.id, unite: unite)) {
                        let lue = lues.contains { $0.cle == "\(oeuvre.id)/\(unite)" }
                        Text(libelle)
                            .font(.system(size: halakha ? 15 : 15, weight: .semibold))
                            .foregroundStyle(lue ? Theme.encreInverse : Theme.encre)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(lue ? Theme.bleu : Theme.papier, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.filet, lineWidth: 1))
                    }
                    .buttonStyle(StylePlein())
                    .accessibilityLabel(libelle)
                    .accessibilityIdentifier(unite)
                    .accessibilityAddTraits(lues.contains { $0.cle == "\(oeuvre.id)/\(unite)" } ? .isSelected : [])
                }
            }
        }
    }

    private func sommaireGroupe(_ oeuvre: Oeuvre, table: [PartieSommaire]) -> some View {
        let groupes = table.compactMap { groupe -> PartieSommaire? in
            let items = groupe.items.filter { item in
                recherche.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || [item.id, item.titre, item.detail ?? "", groupe.partie, groupe.partieHe ?? ""]
                        .joined(separator: " ")
                        .localizedCaseInsensitiveContains(recherche)
            }
            guard !items.isEmpty else { return nil }
            var copie = groupe
            copie.items = items
            return copie
        }
        let guemara = collectionID == "guemara"
        return VStack(alignment: .leading, spacing: 20) {
            if groupes.isEmpty {
                EtatPlace(symbole: "magnifyingglass", titre: "Aucun résultat", detail: "Essayez un autre mot dans le sommaire.")
            } else {
                ForEach(groupes) { groupe in
                    VStack(alignment: .leading, spacing: 8) {
                        enTetePartie(groupe)
                        if guemara {
                            let colonnes = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
                            LazyVGrid(columns: colonnes, spacing: 8) {
                                ForEach(groupe.items) { item in
                                    lien(item, oeuvre: oeuvre, grille: true)
                                }
                            }
                        } else {
                            VStack(spacing: 0) {
                                ForEach(groupe.items) { item in
                                    lien(item, oeuvre: oeuvre, grille: false)
                                }
                            }
                            .background(Theme.papier, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.filet, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private func enTetePartie(_ groupe: PartieSommaire) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(groupe.partie)
                .font(.custom("EBGaramond-SemiBold", size: classe == .regular ? 22 : 20))
                .foregroundStyle(Theme.bleu)
            if let he = groupe.partieHe, !he.isEmpty {
                Text(he)
                    .font(.custom("FrankRuhlLibre-Regular_Medium", size: 15))
                    .foregroundStyle(Theme.gris)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func lien(_ item: ItemSommaire, oeuvre: Oeuvre, grille: Bool) -> some View {
        let lue = lues.contains { $0.cle == "\(oeuvre.id)/\(item.id)" }
        NavigationLink(value: RouteLecture(collectionID: collectionID, oeuvreID: oeuvre.id, unite: item.id)) {
            if grille {
                Text(item.titre)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(lue ? Theme.encreInverse : Theme.encre)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(lue ? Theme.bleu : Theme.papier, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.filet, lineWidth: 1))
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.titre)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.encre)
                    if let detail = item.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.gris)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.gris)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.filet).frame(height: 1) }
            }
        }
        .buttonStyle(StylePlein())
        .accessibilityLabel([item.titre, item.detail ?? ""].filter { !$0.isEmpty }.joined(separator: ", "))
        .accessibilityIdentifier(item.id)
        .accessibilityAddTraits(lue ? .isSelected : [])
    }
}
