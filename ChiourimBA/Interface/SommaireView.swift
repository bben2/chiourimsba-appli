import SwiftData
import SwiftUI

struct SommaireView: View {
    var collectionID: String
    var oeuvreID: String
    @Environment(MagasinTextes.self) private var magasin
    @Environment(\.dismiss) private var dismiss
    @Query private var lues: [UniteLue]
    @ScaledMetric(relativeTo: .largeTitle) private var tailleTitre: CGFloat = 34

    private var oeuvre: Oeuvre? { magasin.oeuvre(collection: collectionID, id: oeuvreID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                BoutonRetour(titre: titreParent) { dismiss() }
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
            .padding(.bottom, 24)
        }
        .background(Theme.fond)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(oeuvre.titre)
                        .font(Polices.titre(tailleTitre))
                        .foregroundStyle(Theme.bleu)
                        .accessibilityAddTraits(.isHeader)
                    Text(Libelles.compteUnites(oeuvre.unites.count, collection: collectionID))
                        .font(.subheadline)
                        .foregroundStyle(Theme.gris)
                    if let auteur = oeuvre.auteur, !auteur.isEmpty {
                        Text(auteur)
                            .font(.subheadline)
                            .foregroundStyle(Theme.gris)
                    }
                }
                Spacer(minLength: 8)
                TexteJustifie(texte: oeuvre.titreHe, police: Polices.hebreu, taille: 30, rtl: true, etirer: false, teinte: "Or")
            }
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
        let colonnes = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
        return VStack(alignment: .leading, spacing: 8) {
            Text(collectionID == "guemara" ? "Feuillets" : "Sections")
                .font(Polices.titre(20))
                .foregroundStyle(Theme.encre)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: colonnes, spacing: 6) {
                ForEach(oeuvre.unites, id: \.self) { unite in
                    NavigationLink(value: RouteLecture(collectionID: collectionID, oeuvreID: oeuvre.id, unite: unite)) {
                        let lue = lues.contains { $0.cle == "\(oeuvre.id)/\(unite)" }
                        Text(unite)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(lue ? Theme.encreInverse : Theme.encre)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(lue ? Theme.bleu : Theme.papier, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.filet, lineWidth: 1))
                    }
                    .buttonStyle(StylePlein())
                    .accessibilityLabel(unite)
                    .accessibilityAddTraits(lues.contains { $0.cle == "\(oeuvre.id)/\(unite)" } ? .isSelected : [])
                }
            }
        }
    }
}
