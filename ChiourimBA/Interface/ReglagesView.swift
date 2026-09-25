import SwiftUI

struct ReglagesView: View {
    @Environment(MagasinTextes.self) private var magasin
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ReglagesLocaux.cleEchelle) private var echelle = 1.0
    @AppStorage(ReglagesLocaux.cleDisposition) private var dispositionBrute = DispositionTexte.auto.rawValue
    @AppStorage(ReglagesLocaux.cleMaj) private var misesAJour = true
    @AppStorage(ReglagesLocaux.cleApparence) private var apparenceBrute = Apparence.papier.rawValue
    @State private var confirmerVidage = false
    @State private var espace: (total: Int64, details: [(nom: String, octets: Int64)]) = (0, [])

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BoutonRetour(titre: "Mon espace") { dismiss() }
                TitreEcran(texte: "Réglages")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Espace utilisé")
                        .font(.system(size: 15, weight: .semibold))
                    barre
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                        ForEach(espace.details, id: \.nom) { detail in
                            Text("\(nomSite(detail.nom)) · \(octets(detail.octets))")
                                .font(.subheadline)
                        }
                        Text("Total · \(octets(espace.total))")
                            .font(.subheadline)
                            .foregroundStyle(Theme.gris)
                    }
                    Button("Vider le cache", role: .destructive) { confirmerVidage = true }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.rouge)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.rouge, lineWidth: 1))
                }
                .padding(16)
                .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Apparence")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.encre)
                    Text("Papier est le fond crème des sites, même si l'appareil est en mode sombre.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.gris)
                    Picker("Apparence", selection: $apparenceBrute) {
                        ForEach(Apparence.allCases) { mode in
                            Text(mode.titre).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Apparence")
                }
                .padding(16)
                .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))

                VStack(spacing: 0) {
                    HStack {
                        Text("Taille du texte")
                        Spacer()
                        Text(echelle.formatted(.percent.precision(.fractionLength(0))))
                            .foregroundStyle(Theme.gris)
                    }
                    .frame(minHeight: 44)
                    Slider(value: $echelle, in: 0.85 ... 1.45, step: 0.05)
                        .tint(Theme.bleu)
                        .accessibilityLabel("Taille du texte")
                    Picker("Disposition", selection: $dispositionBrute) {
                        ForEach(DispositionTexte.allCases) { mode in
                            Text(mode.titre).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Disposition du texte")
                }
                .padding(16)
                .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))

                VStack(spacing: 0) {
                    Toggle("Mises à jour automatiques", isOn: $misesAJour)
                        .frame(minHeight: 44)
                    Divider().background(Theme.filet)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dernière vérification")
                        Text(texteVerification)
                            .font(.footnote)
                            .foregroundStyle(Theme.gris)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 16)
                .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))

                if !ReseauEtat.partage.enLigne {
                    EtatPlace(
                        symbole: "wifi.slash",
                        titre: "Hors connexion",
                        detail: "Cette page n'a pas encore été téléchargée. Elle s'ouvrira dès le retour du réseau."
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .largeurSite(720)
        }
        .background(Theme.fond)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { espace = magasin.espaceUtilise() }
        .confirmationDialog("Vider le cache des textes téléchargés ?", isPresented: $confirmerVidage, titleVisibility: .visible) {
            Button("Vider le cache", role: .destructive) {
                magasin.viderCache()
                espace = magasin.espaceUtilise()
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var barre: some View {
        GeometryReader { geo in
            let total = max(espace.total, 1)
            HStack(spacing: 0) {
                ForEach(Array(espace.details.enumerated()), id: \.element.nom) { index, detail in
                    Rectangle()
                        .fill(couleurBarre(index))
                        .frame(width: geo.size.width * CGFloat(detail.octets) / CGFloat(total))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.champ)
        }
        .frame(height: 10)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func couleurBarre(_ index: Int) -> Color {
        switch index {
        case 0: return Theme.bleu
        case 1: return Theme.or
        default: return Color(red: 0.420, green: 0.561, blue: 0.702)
        }
    }

    private func nomSite(_ id: String) -> String {
        switch id {
        case "guemara": return "Guemara"
        case "hassidout": return "Hassidout"
        case "halakha": return "Halakha"
        default: return id
        }
    }

    private func octets(_ n: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: n, countStyle: .file)
    }

    private var texteVerification: String {
        guard let date = ReglagesLocaux.derniereVerification else { return "Pas encore vérifié." }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
