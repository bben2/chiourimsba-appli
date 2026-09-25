import SafariServices
import SwiftUI
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

/// La taille vient du viewBox, pas du contenu web : un `contentSize` signalé
/// pendant `layoutSubviews` fait avorter AttributeGraph.
private final class WebSchema: WKWebView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    override func invalidateIntrinsicContentSize() {}
}

struct VueSchema: UIViewRepresentable {
    var svg: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        configuration.defaultWebpagePreferences = preferences
        let web = WebSchema(frame: .zero, configuration: configuration)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.isUserInteractionEnabled = false
        web.accessibilityElementsHidden = true
        charger(web)
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        if context.coordinator.dernier != svg {
            context.coordinator.dernier = svg
            charger(web)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WKWebView, context: Context) -> CGSize? {
        let ratio = max(MesureSVG.ratio(svg), 0.25)
        if let largeur = proposal.width, largeur.isFinite, largeur > 1,
           let hauteur = proposal.height, hauteur.isFinite, hauteur > 1 {
            return CGSize(width: largeur, height: hauteur)
        }
        let largeur: CGFloat
        if let proposee = proposal.width, proposee.isFinite, proposee > 1 {
            largeur = min(proposee, 4096)
        } else {
            largeur = 320
        }
        return CGSize(width: largeur, height: max((largeur / ratio).rounded(.up), 1))
    }

    func makeCoordinator() -> Memo { Memo(dernier: svg) }

    private func charger(_ web: WKWebView) {
        let html = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;background:transparent}svg{width:100%;height:auto;display:block}</style>
        </head><body>\(svg)</body></html>
        """
        web.loadHTMLString(html, baseURL: nil)
    }

    final class Memo {
        var dernier: String
        init(dernier: String) { self.dernier = dernier }
    }
}

struct BoiteSchema: View {
    var schema: SchemaTexte

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VueSchema(svg: schema.svg)
                .aspectRatio(MesureSVG.ratio(schema.svg), contentMode: .fit)
                .frame(maxWidth: .infinity)
                .accessibilityElement()
                .accessibilityLabel(schema.legende ?? "Schéma")
            if let legende = schema.legende, !legende.isEmpty {
                Text(legende)
                    .font(.footnote)
                    .foregroundStyle(Theme.gris)
            }
        }
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
