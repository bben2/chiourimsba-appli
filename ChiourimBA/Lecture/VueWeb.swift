import SwiftUI
@preconcurrency import WebKit

@MainActor
final class PontLecture: ObservableObject {
    weak var vue: WKWebView?
    @Published var peutReculer = false
    @Published var chargement = false

    func retour() {
        vue?.goBack()
    }
}

struct VueWeb: UIViewRepresentable {
    var url: URL
    var zoom: CGFloat
    var nonce: Int
    var siteID: String
    var pont: PontLecture
    var onPage: (URL, String) -> Void
    var onPDF: (URL) -> Void
    var onExterne: (URL) -> Void
    var onCourriel: (URL) -> Void
    var onAutreSite: (URL) -> Void

    func makeCoordinator() -> Coordinateur {
        Coordinateur(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let gestionnaire = GestionnaireSchema()
        context.coordinator.gestionnaire = gestionnaire
        configuration.setURLSchemeHandler(gestionnaire, forURLScheme: "chiourim")
        if !DiscussionWidget.estActive {
            configuration.userContentController.addUserScript(DiscussionWidget.script())
        }
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        web.pageZoom = zoom
        web.isOpaque = false
        web.backgroundColor = .systemBackground
        web.scrollView.backgroundColor = .systemBackground
        context.coordinator.pont.vue = web
        context.coordinator.derniereURL = url
        context.coordinator.dernierNonce = nonce
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        if abs(web.pageZoom - zoom) > 0.01 {
            web.pageZoom = zoom
        }
        let forcer = context.coordinator.dernierNonce != nonce
        let changer = context.coordinator.derniereURL != url
        if forcer || changer {
            context.coordinator.dernierNonce = nonce
            context.coordinator.derniereURL = url
            web.load(URLRequest(url: url))
        }
    }
}

final class Coordinateur: NSObject, WKNavigationDelegate, WKUIDelegate, @unchecked Sendable {
    var parent: VueWeb
    var gestionnaire: GestionnaireSchema?
    var derniereURL: URL?
    var dernierNonce: Int
    var pont: PontLecture { parent.pont }

    init(parent: VueWeb) {
        self.parent = parent
        self.dernierNonce = parent.nonce
        self.derniereURL = parent.url
    }

    @MainActor
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        let siteID = parent.siteID
        if url.scheme?.lowercased() == "chiourim", url.pathExtension.lowercased() == "pdf" {
            decisionHandler(.cancel)
            parent.onPDF(url)
            return
        }
        if url.scheme?.lowercased() == "chiourim",
           let hote = url.host?.lowercased(),
           hote != siteID.lowercased(),
           hote != "bloque" {
            decisionHandler(.cancel)
            parent.onAutreSite(url)
            return
        }

        switch ReecritureLien.decider(url) {
        case .interne(let cible):
            if ReecritureLien.memeDocument(url, cible) || url.scheme?.lowercased() == "chiourim" {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                webView.load(URLRequest(url: cible))
            }
        case .bloque:
            decisionHandler(.cancel)
        case .courriel(let mail):
            decisionHandler(.cancel)
            parent.onCourriel(mail)
        case .safari(let lien):
            if navigationAction.navigationType == .other, lien.host?.contains("fonts.g") == true {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            if navigationAction.navigationType != .other {
                parent.onExterne(lien)
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor in
            self.pont.chargement = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let url = webView.url
        let titre = webView.title ?? ""
        let reculer = webView.canGoBack
        Task { @MainActor in
            if let url {
                self.derniereURL = url
                self.parent.onPage(url, titre)
            }
            self.pont.peutReculer = reculer
            self.pont.chargement = false
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        terminerEchec(webView, error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        terminerEchec(webView, error: error)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    private func terminerEchec(_ webView: WKWebView, error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorCancelled { return }
        let reculer = webView.canGoBack
        Task { @MainActor in
            self.pont.peutReculer = reculer
            self.pont.chargement = false
        }
    }
}
