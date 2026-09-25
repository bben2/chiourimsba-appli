import SwiftUI
import UIKit

enum Theme {
    static let fond = Color("Fond")
    static let papier = Color("Papier")
    static let encre = Color("Encre")
    static let bleu = Color("BleuNuit")
    static let or = Color("Or")
    static let gris = Color("GrisTexte")
    static let filet = Color("Filet")
    static let champ = Color("ChampRecherche")
    static let vert = Color("VertHorsLigne")
    static let rouge = Color("RougeCache")
    static let surbrillance = Color("Surbrillance")
    static let encreInverse = Color("EncreInverse")
}

enum Polices {
    static let garamond = "EBGaramond-Regular"
    static let garamondTitre = "EBGaramond-SemiBold"
    static let hebreu = "FrankRuhlLibre-Regular_Medium"
    static let hebreuGras = "FrankRuhlLibre-Regular_Bold"

    static func titre(_ taille: CGFloat) -> Font { .custom(garamondTitre, size: taille) }
    static func texte(_ taille: CGFloat) -> Font { .custom(garamond, size: taille) }
    static func hebreu(_ taille: CGFloat) -> Font { .custom(hebreu, size: taille) }
}

struct TitreEcran: View {
    var texte: String
    @ScaledMetric(relativeTo: .largeTitle) private var taille: CGFloat = 34

    var body: some View {
        Text(texte)
            .font(Polices.titre(taille))
            .foregroundStyle(Theme.bleu)
            .accessibilityAddTraits(.isHeader)
    }
}

struct EtatPlace: View {
    var symbole: String
    var titre: String
    var detail: String
    var actionTitre: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbole)
                .font(.system(size: 28))
                .foregroundStyle(Theme.gris)
                .accessibilityHidden(true)
            Text(titre)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.encre)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Theme.gris)
                .multilineTextAlignment(.center)
            if let actionTitre, let action {
                Button(actionTitre, action: action)
                    .font(.body.weight(.semibold))
                    .frame(minHeight: 44)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Theme.papier, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, style: StrokeStyle(lineWidth: 1, dash: [5])))
        .accessibilityElement(children: .combine)
    }
}

struct SqueletteLignes: View {
    var nombre: Int = 6

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0 ..< nombre, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.papier)
                    .frame(height: 64)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.filet, lineWidth: 1))
                    .redacted(reason: .placeholder)
            }
        }
        .accessibilityLabel("Chargement")
    }
}

struct TexteJustifie: UIViewRepresentable {
    var texte: String
    var police: String
    var taille: CGFloat
    var rtl: Bool
    var etirer = true
    var teinte: String = "Encre"
    @Environment(\.colorScheme) private var schema
    @Environment(\.dynamicTypeSize) private var typeDynamique

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let brut = UIFont(name: police, size: taille) ?? .systemFont(ofSize: taille)
        let policeAdaptee = UIFontMetrics(forTextStyle: .body).scaledFont(for: brut)
        let trait = UITraitCollection(userInterfaceStyle: schema == .dark ? .dark : .light)
        let couleur = (UIColor(named: teinte) ?? .label).resolvedColor(with: trait)
        let style = NSMutableParagraphStyle()
        style.alignment = etirer ? .justified : (rtl ? .right : .natural)
        style.baseWritingDirection = rtl ? .rightToLeft : .leftToRight
        style.lineSpacing = typeDynamique.isAccessibilitySize ? 6 : 4
        label.attributedText = NSAttributedString(string: texte, attributes: [
            .font: policeAdaptee,
            .paragraphStyle: style,
            .foregroundColor: couleur
        ])
        label.accessibilityLanguage = rtl ? "he" : "fr"
        label.accessibilityLabel = texte
        label.isAccessibilityElement = true
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let largeurMax = proposal.width ?? 320
        uiView.preferredMaxLayoutWidth = largeurMax
        let mesure = uiView.sizeThatFits(CGSize(width: largeurMax, height: .greatestFiniteMagnitude))
        let largeur = etirer ? largeurMax : min(largeurMax, ceil(mesure.width))
        return CGSize(width: max(largeur, 1), height: max(ceil(mesure.height), 1))
    }
}

enum HTMLSimple {
    @MainActor
    static func attribue(_ html: String, taille: CGFloat) -> AttributedString {
        let enveloppe = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>body{font-family:'EB Garamond',Georgia,serif;font-size:\(Int(taille))px} p{margin:0 0 0.45em} </style>
        </head><body>\(html)</body></html>
        """
        guard let data = enveloppe.data(using: .utf8),
              let ns = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
              ) else {
            let nu = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            return AttributedString(nu)
        }
        let mutable = NSMutableAttributedString(attributedString: ns)
        let tout = NSRange(location: 0, length: mutable.length)
        mutable.removeAttribute(.foregroundColor, range: tout)
        return AttributedString(mutable)
    }
}

enum MesureSVG {
    static func ratio(_ svg: String) -> CGFloat {
        guard let expression = try? NSRegularExpression(pattern: "viewBox\\s*=\\s*[\"']\\s*[-0-9.]+\\s+[-0-9.]+\\s+([0-9.]+)\\s+([0-9.]+)\\s*[\"']"),
              let trouve = expression.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
              let plageL = Range(trouve.range(at: 1), in: svg),
              let plageH = Range(trouve.range(at: 2), in: svg),
              let largeur = Double(svg[plageL]),
              let hauteur = Double(svg[plageH]),
              largeur > 0, hauteur > 0 else { return 1.6 }
        return CGFloat(largeur / hauteur)
    }
}

struct BoutonRetour: View {
    var titre: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text(titre)
            }
            .font(.body)
            .foregroundStyle(Theme.bleu)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Retour, \(titre)")
    }
}
