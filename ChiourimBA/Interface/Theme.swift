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
    /// Texte français : police système, comme sur les sites.
    static let francais = "Systeme"

    static func titre(_ taille: CGFloat) -> Font { .custom(hebreuGras, size: taille) }
    static func texte(_ taille: CGFloat) -> Font { .system(size: taille) }
    static func hebreu(_ taille: CGFloat) -> Font { .custom(hebreu, size: taille) }
}

struct LargeurSite: ViewModifier {
    var max: CGFloat
    @Environment(\.horizontalSizeClass) private var classe

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: classe == .regular ? max : .infinity, alignment: .leading)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Colonne centrée. Lecture : 720. Sommaires : 1040, comme les sites.
    func largeurSite(_ max: CGFloat = 1040) -> some View {
        modifier(LargeurSite(max: max))
    }
}

struct EnteteSite: View {
    var hebreu: String
    var titre: String
    var sousTitre: String = ""
    var pastille: String?
    @Environment(\.horizontalSizeClass) private var classe

    var body: some View {
        VStack(spacing: 6) {
            if !hebreu.isEmpty {
                Text(hebreu)
                    .font(Polices.hebreu(classe == .regular ? 40 : 34))
                    .foregroundStyle(Theme.bleu)
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityLabel(hebreu)
            }
            Text(titre)
                .font(Polices.titre(classe == .regular ? 32 : 28))
                .foregroundStyle(Theme.encre)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            if !sousTitre.isEmpty {
                Text(sousTitre)
                    .font(.system(size: classe == .regular ? 17 : 15))
                    .foregroundStyle(Theme.gris)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 640)
            }
            if let pastille, !pastille.isEmpty {
                Text(pastille)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.gris)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 6)
                    .background(Theme.papier, in: Capsule())
                    .overlay(Capsule().stroke(Theme.filet, lineWidth: 1))
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 18)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.filet).frame(height: 2)
        }
    }
}

struct CarteSite<Label: View>: View {
    var or: Bool = true
    @ViewBuilder var label: () -> Label

    var body: some View {
        label()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(Theme.papier)
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.filet, lineWidth: 1))
            .overlay(alignment: .leading) {
                if or {
                    Rectangle()
                        .fill(Theme.or)
                        .frame(width: 4)
                        .padding(.vertical, 10)
                }
            }
    }
}

struct TitreEcran: View {
    var texte: String
    @ScaledMetric(relativeTo: .largeTitle) private var taille: CGFloat = 34

    var body: some View {
        Text(texte)
            .font(Polices.titre(taille))
            .foregroundStyle(Theme.encre)
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

/// Ne propage pas l'invalidation de taille intrinsèque : elle réveille
/// `ViewGraph.beginNextUpdate` depuis `layoutSubviews` et AttributeGraph avorte (`value_set`).
private final class EtiquetteLecture: UILabel {
    private var ajuste = false

    override func layoutSubviews() {
        super.layoutSubviews()
        let largeur = bounds.width
        guard largeur > 1, abs(preferredMaxLayoutWidth - largeur) > 0.5, !ajuste else { return }
        ajuste = true
        preferredMaxLayoutWidth = largeur
        ajuste = false
    }

    override func invalidateIntrinsicContentSize() {}
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

    func makeCoordinator() -> Sonde { Sonde() }

    func makeUIView(context: Context) -> UILabel {
        let label = EtiquetteLecture()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let chaine = attributs()
        if label.attributedText != chaine {
            label.attributedText = chaine
        }
        label.accessibilityLanguage = rtl ? "he" : "fr"
        label.accessibilityLabel = texte
        label.isAccessibilityElement = true
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        // Sonde hors hiérarchie : écrire preferredMaxLayoutWidth sur l'étiquette affichée
        // invalide la mise en page en cours et fait planter AttributeGraph.
        let largeurMax = largeurMesure(proposal)
        let sonde = context.coordinator.etiquette
        sonde.attributedText = attributs()
        sonde.numberOfLines = 0
        sonde.lineBreakMode = .byWordWrapping
        sonde.preferredMaxLayoutWidth = largeurMax
        let mesure = sonde.sizeThatFits(CGSize(width: largeurMax, height: .greatestFiniteMagnitude))
        let largeurTexte = mesure.width.isFinite ? ceil(mesure.width) : 1
        let largeur = etirer ? largeurMax : min(largeurMax, max(largeurTexte, 1))
        let hauteur = mesure.height.isFinite ? ceil(mesure.height) : 1
        return CGSize(width: max(largeur, 1), height: max(hauteur, 1))
    }

    private func largeurMesure(_ proposal: ProposedViewSize) -> CGFloat {
        guard let largeur = proposal.width, largeur.isFinite, largeur > 1 else { return 320 }
        return min(largeur, 4096)
    }

    private func attributs() -> NSAttributedString {
        let brut: UIFont = (police == Polices.francais || police.isEmpty)
            ? .systemFont(ofSize: taille)
            : (UIFont(name: police, size: taille) ?? .systemFont(ofSize: taille))
        let policeAdaptee = UIFontMetrics(forTextStyle: .body).scaledFont(for: brut)
        let trait = UITraitCollection(userInterfaceStyle: schema == .dark ? .dark : .light)
        let couleur = (UIColor(named: teinte) ?? .label).resolvedColor(with: trait)
        let style = NSMutableParagraphStyle()
        style.alignment = etirer ? .justified : (rtl ? .right : .natural)
        style.baseWritingDirection = rtl ? .rightToLeft : .leftToRight
        style.lineSpacing = typeDynamique.isAccessibilitySize ? 6 : 4
        return NSAttributedString(string: texte, attributes: [
            .font: policeAdaptee,
            .paragraphStyle: style,
            .foregroundColor: couleur
        ])
    }

    @MainActor
    final class Sonde {
        let etiquette = UILabel()

        init() {
            etiquette.numberOfLines = 0
            etiquette.lineBreakMode = .byWordWrapping
        }
    }
}

enum HTMLSimple {
    /// Conversion locale. `NSAttributedString` + HTML passe par WebKit (`NSHTMLReader`),
    /// qui relance la run loop au milieu de `LazyVStack.sizeThatFits` et fait avorter AttributeGraph.
    static func attribue(_ html: String, taille: CGFloat) -> AttributedString {
        let police = Font.system(size: taille)
        let policeGras = Font.system(size: taille, weight: .semibold)
        var resultat = AttributedString()
        var tampon = ""
        var gras = 0
        var italique = 0
        var index = html.startIndex

        func vider() {
            guard !tampon.isEmpty else { return }
            var morceau = AttributedString(decoderEntites(tampon))
            var fonte = gras > 0 ? policeGras : police
            if italique > 0 { fonte = fonte.italic() }
            morceau.font = fonte
            resultat.append(morceau)
            tampon.removeAll(keepingCapacity: true)
        }

        func saut() {
            vider()
            if resultat.characters.last != "\n" {
                resultat.append(AttributedString("\n"))
            }
        }

        while index < html.endIndex {
            let caractere = html[index]
            if caractere == "<" {
                guard let fin = html[index...].firstIndex(of: ">") else {
                    tampon.append(contentsOf: html[index...])
                    break
                }
                let interieur = html[html.index(after: index)..<fin]
                let fermante = interieur.first == "/"
                let nom = interieur
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let balise = nom.split(whereSeparator: { $0 == " " || $0 == "\t" }).first.map(String.init) ?? ""
                switch balise {
                case "b", "strong":
                    vider()
                    gras = max(0, gras + (fermante ? -1 : 1))
                case "i", "em":
                    vider()
                    italique = max(0, italique + (fermante ? -1 : 1))
                case "br":
                    saut()
                case "p":
                    if fermante { saut() }
                default:
                    break
                }
                index = html.index(after: fin)
            } else {
                tampon.append(caractere)
                index = html.index(after: index)
            }
        }
        vider()
        while resultat.characters.last == "\n" {
            resultat.characters.removeLast()
        }
        return resultat
    }

    private static func decoderEntites(_ texte: String) -> String {
        guard texte.contains("&") else { return texte }
        var sortie = ""
        var index = texte.startIndex
        while index < texte.endIndex {
            if texte[index] == "&", let fin = texte[index...].firstIndex(of: ";"), texte.distance(from: index, to: fin) <= 12 {
                let code = String(texte[index...fin])
                if let remplace = entite(code) {
                    sortie.append(remplace)
                    index = texte.index(after: fin)
                    continue
                }
            }
            sortie.append(texte[index])
            index = texte.index(after: index)
        }
        return sortie
    }

    private static func entite(_ code: String) -> String? {
        switch code {
        case "&amp;": return "&"
        case "&lt;": return "<"
        case "&gt;": return ">"
        case "&quot;": return "\""
        case "&apos;", "&#39;": return "'"
        case "&nbsp;": return "\u{00A0}"
        default:
            if code.hasPrefix("&#x"), let valeur = Int(code.dropFirst(3).dropLast(), radix: 16), let scalaire = UnicodeScalar(valeur) {
                return String(scalaire)
            }
            if code.hasPrefix("&#"), let valeur = Int(code.dropFirst(2).dropLast()), let scalaire = UnicodeScalar(valeur) {
                return String(scalaire)
            }
            return nil
        }
    }
}

enum MesureSVG {
    /// Largeur / hauteur du viewBox. Défaut 1,6 si le SVG n'en a pas.
    static func ratio(_ svg: String) -> CGFloat {
        guard let boite = boite(svg), boite.width > 0, boite.height > 0 else { return 1.6 }
        return boite.width / boite.height
    }

    static func boite(_ svg: String) -> CGSize? {
        guard let expression = try? NSRegularExpression(pattern: "viewBox\\s*=\\s*[\"']\\s*[-0-9.]+\\s+[-0-9.]+\\s+([0-9.]+)\\s+([0-9.]+)\\s*[\"']"),
              let trouve = expression.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
              let plageL = Range(trouve.range(at: 1), in: svg),
              let plageH = Range(trouve.range(at: 2), in: svg),
              let largeur = Double(svg[plageL]),
              let hauteur = Double(svg[plageH]),
              largeur > 0, hauteur > 0 else { return nil }
        return CGSize(width: largeur, height: hauteur)
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
