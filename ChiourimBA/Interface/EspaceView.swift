import AuthenticationServices
import SwiftData
import SwiftUI

struct EspaceView: View {
    @Query(sort: \PositionLecture.miseAJour, order: .reverse) private var positions: [PositionLecture]
    @Query private var favoris: [Favori]
    @Query private var annotations: [AnnotationLocale]
    @State private var signalements: [EntreeSignalement] = []
    @Environment(\.horizontalSizeClass) private var classe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    TitreEcran(texte: "Mon espace")
                    Spacer()
                    NavigationLink {
                        ReglagesView()
                    } label: {
                        Text("Réglages")
                            .font(.body)
                            .frame(minHeight: 44)
                    }
                }

                carteConnexion

                VStack(alignment: .leading, spacing: 8) {
                    Text("Où j'en suis")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.gris)
                        .accessibilityAddTraits(.isHeader)
                    if positions.isEmpty {
                        EtatPlace(symbole: "book", titre: "Aucune lecture en cours", detail: "Ouvrez un feuillet : l'endroit où vous vous arrêtez sera gardé ici.")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(positions.prefix(8).enumerated()), id: \.element.cle) { index, position in
                                NavigationLink {
                                    LectureView(
                                        collectionID: position.collectionID,
                                        oeuvreID: position.oeuvreID,
                                        unite: position.unite,
                                        indexInitial: position.indexSegment
                                    )
                                } label: {
                                    lignePosition(position, premiere: index == 0)
                                }
                                .buttonStyle(StylePlein())
                            }
                        }
                        .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
                    }
                }

                HStack(spacing: 8) {
                    NavigationLink { ListeFavorisView() } label: { compteur(favoris.count, "Favoris") }
                    NavigationLink { ListeAnnotationsView() } label: { compteur(annotations.count, "Annotations") }
                    NavigationLink { ListeSignalementsView(entrees: signalements) } label: { compteur(signalements.count, "Signalements") }
                }

                if let dernier = signalements.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dernier signalement")
                            .font(.system(size: 15, weight: .semibold))
                        Text(ligneSignalement(dernier))
                            .font(.subheadline)
                            .foregroundStyle(Theme.gris)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .largeurSite(1040)
        }
        .background(Theme.fond)
        .navigationTitle("Mon espace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(classe == .regular ? .visible : .hidden, for: .navigationBar)
        .onAppear { signalements = FileSignalements.standard().lire() }
    }

    @ViewBuilder
    private var carteConnexion: some View {
        VStack(alignment: .leading, spacing: 10) {
            if Config.connexionActive {
                Text("Retrouvez vos lectures partout")
                    .font(.system(size: 17, weight: .semibold))
                Text("Connectez-vous pour garder où vous en êtes, vos annotations et vos favoris sur tous vos appareils.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.gris)
                SignInWithAppleButton(.signIn) { demande in
                    demande.requestedScopes = [.fullName]
                } onCompletion: { _ in }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
            } else {
                Text("Vos lectures restent sur cet iPhone")
                    .font(.system(size: 17, weight: .semibold))
                Text("La connexion avec Apple arrivera avec la synchronisation. En attendant, favoris, annotations et signalements sont gardés sur cet appareil.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.gris)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.papier, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.filet, lineWidth: 1))
    }

    private func lignePosition(_ position: PositionLecture, premiere: Bool) -> some View {
        let total = max(position.totalUnites, 1)
        let courant = min(max(position.indexUnite + 1, 1), total)
        let fraction = Double(courant) / Double(total)
        let fin = position.totalUnites > 0 ? "\(position.unite) · \(courant) / \(total)" : position.unite
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(position.oeuvreTitre)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.encre)
                Spacer()
                Text(fin)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.gris)
            }
            ProgressView(value: fraction)
                .tint(Theme.bleu)
                .accessibilityLabel("Progression \(courant) sur \(total)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .overlay(alignment: .top) {
            if !premiere { Rectangle().fill(Theme.filet).frame(height: 1) }
        }
    }

    private func compteur(_ nombre: Int, _ titre: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(nombre)")
                .font(Polices.titre(26))
                .foregroundStyle(Theme.bleu)
            Text(titre)
                .font(.system(size: 13))
                .foregroundStyle(Theme.encre)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .frame(minHeight: 44)
        .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(titre), \(nombre)")
    }

    private func ligneSignalement(_ entree: EntreeSignalement) -> String {
        let etat = entree.etat == "envoye" ? "envoyé" : "en attente"
        let extrait = entree.correction.isEmpty ? entree.passage : entree.correction
        return "\(entree.page) · \(extrait) — \(etat)"
    }
}

struct ListeFavorisView: View {
    @Query(sort: \Favori.ajouteLe, order: .reverse) private var favoris: [Favori]
    @State private var recherche = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let filtres = favoris.filter { favori in
            let q = recherche.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty { return true }
            return favori.titre.localizedStandardContains(q) || favori.site.localizedStandardContains(q)
        }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                BoutonRetour(titre: "Mon espace") { dismiss() }
                TitreEcran(texte: "Favoris")
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.gris)
                    TextField("Chercher un favori", text: $recherche)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Theme.champ, in: RoundedRectangle(cornerRadius: 12))
                if filtres.isEmpty {
                    EtatPlace(symbole: "bookmark", titre: "Aucun favori", detail: "Le signet d'une page de lecture le rangera ici.")
                } else {
                    ForEach(filtres, id: \.cle) { favori in
                        NavigationLink {
                            LectureView(collectionID: favori.collectionID, oeuvreID: favori.oeuvreID, unite: favori.unite, indexInitial: 0)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(favori.titre).font(.body.weight(.semibold)).foregroundStyle(Theme.encre)
                                Text("\(favori.site) · \(favori.ajouteLe.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.gris)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .frame(minHeight: 44)
                            .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
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
    }
}

struct ListeAnnotationsView: View {
    @Query(sort: \AnnotationLocale.creeLe, order: .reverse) private var annotations: [AnnotationLocale]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                BoutonRetour(titre: "Mon espace") { dismiss() }
                TitreEcran(texte: "Annotations")
                if annotations.isEmpty {
                    EtatPlace(symbole: "highlighter", titre: "Aucune annotation", detail: "Un appui long sur un passage permet de surligner ou d'écrire une note.")
                } else {
                    ForEach(annotations, id: \.id) { note in
                        NavigationLink {
                            LectureView(collectionID: note.collectionID, oeuvreID: note.oeuvreID, unite: note.unite, indexInitial: note.indexSegment)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.oeuvreTitre).font(.body.weight(.semibold)).foregroundStyle(Theme.encre)
                                Text(note.surlignage && note.note.isEmpty ? "Surlignage" : note.note)
                                    .font(Polices.texte(16))
                                    .foregroundStyle(Theme.encre)
                                Text("\(note.unite) · \(note.creeLe.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.gris)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(note.surlignage ? Theme.surbrillance.opacity(0.45) : Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
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
    }
}

struct ListeSignalementsView: View {
    var entrees: [EntreeSignalement]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                BoutonRetour(titre: "Mon espace") { dismiss() }
                TitreEcran(texte: "Signalements")
                if entrees.isEmpty {
                    EtatPlace(symbole: "envelope", titre: "Aucun signalement", detail: "Une correction proposée depuis une page de lecture apparaît ici.")
                } else {
                    ForEach(entrees) { entree in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entree.page).font(.body.weight(.semibold))
                            Text(entree.correction.isEmpty ? entree.passage : entree.correction)
                                .font(.subheadline)
                            Text(entree.etat == "envoye" ? "Envoyé" : "En attente d'envoi")
                                .font(.footnote)
                                .foregroundStyle(Theme.gris)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Theme.fond)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
