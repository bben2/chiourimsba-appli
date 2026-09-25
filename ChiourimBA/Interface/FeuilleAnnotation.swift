import SwiftUI

enum ModeAnnotation: String, CaseIterable, Identifiable {
    case surligner, annoter, signaler
    var id: String { rawValue }
    var titre: String {
        switch self {
        case .surligner: return "Surligner"
        case .annoter: return "Annoter"
        case .signaler: return "Signaler"
        }
    }
}

struct FeuilleAnnotation: View {
    var passage: String
    var peutSignaler: Bool
    var onSurligner: () -> Void
    var onAnnoter: (String) -> Void
    var onSignaler: (String) async -> String

    @Environment(\.dismiss) private var dismiss
    @State private var mode: ModeAnnotation = .annoter
    @State private var note = ""
    @State private var correction = ""
    @State private var message: String?
    @State private var envoi = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(Theme.filet)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            Picker("Action", selection: $mode) {
                ForEach(ModeAnnotation.allCases) { choix in
                    Text(choix.titre).tag(choix)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)

            Text("« \(passage) »")
                .font(Polices.texte(16))
                .foregroundStyle(Theme.encre)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.fond, in: RoundedRectangle(cornerRadius: 10))

            if mode == .annoter {
                Text("Ma note")
                    .font(.subheadline.weight(.semibold))
                TextEditor(text: $note)
                    .frame(minHeight: 88)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.001))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.filet, lineWidth: 1))
                    .accessibilityLabel("Ma note")
            } else if mode == .signaler {
                Text("Correction proposée")
                    .font(.subheadline.weight(.semibold))
                TextEditor(text: $correction)
                    .frame(minHeight: 88)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.filet, lineWidth: 1))
                    .accessibilityLabel("Correction proposée")
                Text("Envoyé à l'équipe de traduction avec la référence de la page. Vous suivrez la réponse dans Mon espace.")
                    .font(.footnote)
                    .foregroundStyle(Theme.gris)
            }

            if let message {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.bleu)
                    .accessibilityAddTraits(.isStaticText)
            }

            Button(action: valider) {
                Text(titreBouton)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.bleu)
            .disabled(envoi || (mode == .signaler && !peutSignaler))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Theme.papier)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var titreBouton: String {
        switch mode {
        case .surligner: return "Surligner le passage"
        case .annoter: return "Enregistrer la note"
        case .signaler: return peutSignaler ? "Envoyer le signalement" : "Signalement indisponible ici"
        }
    }

    private func valider() {
        switch mode {
        case .surligner:
            onSurligner()
            message = "Le passage est surligné."
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                dismiss()
            }
        case .annoter:
            let propre = note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !propre.isEmpty else {
                message = "Écrivez d'abord la note."
                return
            }
            onAnnoter(propre)
            dismiss()
        case .signaler:
            let propre = correction.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !propre.isEmpty else {
                message = "Proposez d'abord une correction."
                return
            }
            envoi = true
            Task {
                let recu = await onSignaler(propre)
                message = recu
                envoi = false
            }
        }
    }
}
