import CryptoKit
import SafariServices
import SwiftUI
import UIKit
@preconcurrency import WebKit

struct VuePortail: UIViewRepresentable {
    var url: URL
    var ouvrirDiscussion: Bool

    func makeCoordinator() -> Coordinateur { Coordinateur(ouvrirDiscussion: ouvrirDiscussion) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = UIColor(named: "Fond")
        web.scrollView.backgroundColor = UIColor(named: "Fond")
        web.allowsBackForwardNavigationGestures = true
        context.coordinator.derniere = url
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.ouvrirDiscussion = ouvrirDiscussion
        if context.coordinator.derniere != url {
            context.coordinator.derniere = url
            web.load(URLRequest(url: url))
        }
    }

    final class Coordinateur: NSObject, WKNavigationDelegate, @unchecked Sendable {
        var ouvrirDiscussion: Bool
        var derniere: URL?

        init(ouvrirDiscussion: Bool) {
            self.ouvrirDiscussion = ouvrirDiscussion
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard ouvrirDiscussion else { return }
            let script = "setTimeout(function(){var b=document.getElementById('ct-btn');if(b)b.click();},600);"
            Task { @MainActor in
                _ = try? await webView.evaluateJavaScript(script)
            }
        }
    }
}

/// Crème fixe (#fffdf8), identique au fond des SVG. Ne suit pas le mode Nuit :
/// le schéma reste sur une plaque claire.
private enum FondSchema {
    static let ui = UIColor(red: 1, green: 253.0 / 255, blue: 248.0 / 255, alpha: 1)
    static let couleur = Color(uiColor: ui)
    static let encre = Color(red: 28.0 / 255, green: 25.0 / 255, blue: 23.0 / 255)
    static let filet = Color(red: 0.86, green: 0.82, blue: 0.76)
}

/// Hauteur = largeur / viewBox, jamais sous `minimum` (la plaque reste lisible).
private struct HauteurSchema: Layout {
    var ratio: CGFloat
    var minimum: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposee = proposal.width ?? 0
        let largeur = proposee.isFinite && proposee > 1 ? proposee : 320
        let naturelle = largeur / max(ratio, 0.25)
        return CGSize(width: largeur, height: max(naturelle.rounded(.up), minimum))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let vue = subviews.first else { return }
        let hauteurImage = min(bounds.width / max(ratio, 0.25), bounds.height)
        let y = bounds.minY + (bounds.height - hauteurImage) / 2
        vue.place(
            at: CGPoint(x: bounds.minX, y: y),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: max(hauteurImage, 1))
        )
    }
}

struct BoiteSchema: View {
    var schema: SchemaTexte
    @State private var image: UIImage?

    private var ratio: CGFloat { max(MesureSVG.ratio(schema.svg), 0.25) }

    private var libelle: String {
        if let legende = schema.legende?.trimmingCharacters(in: .whitespacesAndNewlines), !legende.isEmpty {
            return "Schéma, \(legende)"
        }
        return "Schéma"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HauteurSchema(ratio: ratio, minimum: 128) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                } else {
                    Rectangle().fill(FondSchema.couleur)
                }
            }
            .frame(maxWidth: .infinity)
            .background(FondSchema.couleur)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(libelle)
            .accessibilityValue(image == nil ? "chargement" : "visible")
            .accessibilityAddTraits(.isImage)

            if let legende = schema.legende?.trimmingCharacters(in: .whitespacesAndNewlines), !legende.isEmpty {
                Text(legende)
                    .font(.footnote)
                    .foregroundStyle(FondSchema.encre)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FondSchema.couleur, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(FondSchema.filet, lineWidth: 1)
        )
        .task(id: schema.svg) {
            var essai = 0
            while image == nil, essai < 3, !Task.isCancelled {
                image = await AtelierSchema.partage.image(pour: schema.svg)
                essai += 1
                if image == nil {
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
    }
}

/// Le WKWebView dans le LazyVStack restait blanc : créé hors écran à taille nulle,
/// `loadHTMLString` fige le SVG (`height: auto`) et le processus Web ne repeint pas
/// quand SwiftUI lui donne enfin un cadre. On rasterise une fois, hors liste, puis
/// on affiche une image.
@MainActor
final class AtelierSchema {
    static let partage = AtelierSchema()

    private let memoire: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 24
        return cache
    }()

    private var sources: [String: String] = [:]
    private var suites: [String: [CheckedContinuation<UIImage?, Never>]] = [:]
    private var file: [String] = []
    private var enCours = false

    func image(pour svg: String) async -> UIImage? {
        let cle = empreinte(svg)
        if let deja = enCache(cle) { return deja }
        return await withCheckedContinuation { continuation in
            sources[cle] = svg
            suites[cle, default: []].append(continuation)
            if !file.contains(cle) { file.append(cle) }
            pomper()
        }
    }

    private func pomper() {
        guard !enCours, let cle = file.first else { return }
        enCours = true
        let svg = sources[cle] ?? ""
        Task { @MainActor in
            let image = await self.rasteriser(svg)
            if let image { self.memoriser(cle, image) }
            self.file.removeAll { $0 == cle }
            self.sources[cle] = nil
            let attentes = self.suites.removeValue(forKey: cle) ?? []
            self.enCours = false
            for attente in attentes {
                attente.resume(returning: image)
            }
            self.pomper()
        }
    }

    private func enCache(_ cle: String) -> UIImage? {
        let ns = cle as NSString
        if let image = memoire.object(forKey: ns) { return image }
        let url = urlCache(cle)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data),
              ContrasteImage.suffisant(image) else { return nil }
        memoire.setObject(image, forKey: ns)
        return image
    }

    private func memoriser(_ cle: String, _ image: UIImage) {
        memoire.setObject(image, forKey: cle as NSString)
        guard let data = image.pngData() else { return }
        let url = urlCache(cle)
        Task.detached {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    private func urlCache(_ cle: String) -> URL {
        CacheDisque.dossierApplication()
            .appending(path: "schemas", directoryHint: .isDirectory)
            .appending(path: cle + ".png")
    }

    private func empreinte(_ svg: String) -> String {
        SHA256.hash(data: Data(svg.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func rasteriser(_ svg: String) async -> UIImage? {
        guard svg.contains("<svg"),
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState != .unattached })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return nil }

        let ratio = max(MesureSVG.ratio(svg), 0.25)
        let largeurSVG = MesureSVG.boite(svg)?.width ?? 720
        let largeur = min(max(largeurSVG, 640), 1440)
        let hauteur = max((largeur / ratio).rounded(.up), 1)
        let taille = CGSize(width: largeur, height: hauteur)

        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        configuration.defaultWebpagePreferences = preferences
        let web = WebSchema(frame: CGRect(origin: .zero, size: taille), configuration: configuration)
        web.isOpaque = true
        web.backgroundColor = FondSchema.ui
        web.scrollView.backgroundColor = FondSchema.ui
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.isUserInteractionEnabled = false
        web.accessibilityElementsHidden = true

        let controleur = UIViewController()
        controleur.view.backgroundColor = FondSchema.ui
        controleur.view.insetsLayoutMarginsFromSafeArea = false
        controleur.view.addSubview(web)
        web.frame = CGRect(origin: .zero, size: taille)
        controleur.view.frame = CGRect(origin: .zero, size: taille)

        let fenetre = UIWindow(windowScene: scene)
        fenetre.frame = CGRect(x: -largeur - 80, y: -hauteur - 80, width: largeur, height: hauteur)
        fenetre.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue - 100)
        fenetre.rootViewController = controleur
        fenetre.isUserInteractionEnabled = false
        fenetre.accessibilityElementsHidden = true
        fenetre.isHidden = false
        fenetre.layoutIfNeeded()
        web.frame = CGRect(origin: .zero, size: taille)

        let chargement = ChargementSchema()
        web.navigationDelegate = chargement
        let html = page(svg: svg, taille: taille)
        let charge = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            chargement.armer(continuation)
            web.loadHTMLString(html, baseURL: URL(string: "about:blank"))
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                chargement.finir(false)
            }
        }
        guard charge else {
            ranger(web: web, fenetre: fenetre)
            return nil
        }

        web.setNeedsLayout()
        web.layoutIfNeeded()
        try? await Task.sleep(for: .milliseconds(80))

        var rendu: UIImage?
        for _ in 0..<4 {
            if let image = await cliche(web), ContrasteImage.suffisant(image) {
                rendu = image
                break
            }
            try? await Task.sleep(for: .milliseconds(150))
        }
        if rendu == nil {
            rendu = await pdf(web, taille: taille)
            if let image = rendu, !ContrasteImage.suffisant(image) { rendu = nil }
        }
        ranger(web: web, fenetre: fenetre)
        return rendu
    }

    private func ranger(web: WKWebView, fenetre: UIWindow) {
        web.navigationDelegate = nil
        web.stopLoading()
        fenetre.isHidden = true
        fenetre.rootViewController = nil
    }

    private func cliche(_ web: WKWebView) async -> UIImage? {
        let config = WKSnapshotConfiguration()
        config.rect = web.bounds
        config.afterScreenUpdates = true
        return await withCheckedContinuation { continuation in
            web.takeSnapshot(with: config) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    private func pdf(_ web: WKWebView, taille: CGSize) async -> UIImage? {
        let config = WKPDFConfiguration()
        config.rect = CGRect(origin: .zero, size: taille)
        let data: Data? = await withCheckedContinuation { continuation in
            web.createPDF(configuration: config) { result in
                continuation.resume(returning: try? result.get())
            }
        }
        guard let data else { return nil }
        return imagePDF(data, taille: taille)
    }

    private func imagePDF(_ data: Data, taille: CGSize) -> UIImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider),
              let page = document.page(at: 1) else { return nil }
        let echelle: CGFloat = 2
        let pixels = CGSize(width: taille.width * echelle, height: taille.height * echelle)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: pixels, format: format)
        let boite = page.getBoxRect(.mediaBox)
        guard boite.width > 0, boite.height > 0 else { return nil }
        return renderer.image { contexte in
            FondSchema.ui.setFill()
            contexte.fill(CGRect(origin: .zero, size: pixels))
            let cg = contexte.cgContext
            cg.translateBy(x: 0, y: pixels.height)
            cg.scaleBy(x: pixels.width / boite.width, y: -pixels.height / boite.height)
            cg.translateBy(x: -boite.minX, y: -boite.minY)
            cg.drawPDFPage(page)
        }
    }

    private func page(svg: String, taille: CGSize) -> String {
        let largeur = Int(taille.width.rounded())
        let hauteur = Int(taille.height.rounded())
        return """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=\(largeur),initial-scale=1,maximum-scale=1">
        <style>
        html,body{margin:0;padding:0;width:\(largeur)px;height:\(hauteur)px;background:#fffdf8;overflow:hidden}
        svg{position:absolute;left:0;top:0;width:\(largeur)px;height:\(hauteur)px;display:block}
        </style></head><body>\(svg)</body></html>
        """
    }
}

/// Hors du processus d'accessibilité : un WKWebView dans la liste ne sert plus à l'affichage.
private final class WebSchema: WKWebView {
    override var safeAreaInsets: UIEdgeInsets { .zero }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}

private final class ChargementSchema: NSObject, WKNavigationDelegate, @unchecked Sendable {
    private let verrou = NSLock()
    private var reprise: CheckedContinuation<Bool, Never>?
    private var termine = false

    func armer(_ continuation: CheckedContinuation<Bool, Never>) {
        verrou.lock()
        reprise = continuation
        verrou.unlock()
    }

    func finir(_ ok: Bool) {
        verrou.lock()
        let suite = reprise
        if suite != nil { reprise = nil; termine = true }
        let deja = suite == nil && termine
        verrou.unlock()
        guard let suite, !deja else { return }
        Task { @MainActor in
            suite.resume(returning: ok)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finir(true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finir(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finir(false)
    }
}

enum ContrasteImage {
    /// Vrai si le bitmap n'est pas une plaque unie (rendu SVG raté).
    static func suffisant(_ image: UIImage) -> Bool {
        guard let cg = image.cgImage, cg.width > 4, cg.height > 4 else { return false }
        let cote = 40
        var pixels = [UInt8](repeating: 0, count: cote * cote * 4)
        guard let contexte = CGContext(
            data: &pixels,
            width: cote,
            height: cote,
            bitsPerComponent: 8,
            bytesPerRow: cote * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        contexte.interpolationQuality = .medium
        contexte.draw(cg, in: CGRect(x: 0, y: 0, width: cote, height: cote))
        var minR = 255, maxR = 0, minG = 255, maxG = 0, minB = 255, maxB = 0
        var opaques = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            if pixels[index + 3] < 16 { continue }
            opaques += 1
            minR = min(minR, Int(pixels[index]))
            maxR = max(maxR, Int(pixels[index]))
            minG = min(minG, Int(pixels[index + 1]))
            maxG = max(maxG, Int(pixels[index + 1]))
            minB = min(minB, Int(pixels[index + 2]))
            maxB = max(maxB, Int(pixels[index + 2]))
        }
        guard opaques > cote * cote / 4 else { return false }
        return max(maxR - minR, maxG - minG, maxB - minB) >= 10
    }
}

struct VueSafari: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controleur = SFSafariViewController(url: url)
        controleur.preferredControlTintColor = UIColor(named: "BleuNuit")
        return controleur
    }

    func updateUIViewController(_ controleur: SFSafariViewController, context: Context) {}
}
