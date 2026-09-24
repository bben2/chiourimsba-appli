import Foundation
@preconcurrency import WebKit

/// Sert `chiourim://` avec le type MIME de l'extension, jamais le `text/plain` de GitHub.
final class GestionnaireSchema: NSObject, WKURLSchemeHandler, @unchecked Sendable {
    private let verrou = NSLock()
    private var actifs: Set<ObjectIdentifier> = []

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        let identifiant = ObjectIdentifier(urlSchemeTask)
        verrou.lock()
        actifs.insert(identifiant)
        verrou.unlock()
        let url = urlSchemeTask.request.url
        Task {
            let reponse = await PasserelleContenu.partagee.repondre(a: url)
            self.livrer(urlSchemeTask, identifiant: identifiant, reponse: reponse)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        let identifiant = ObjectIdentifier(urlSchemeTask)
        verrou.lock()
        actifs.remove(identifiant)
        verrou.unlock()
    }

    private func livrer(
        _ tache: any WKURLSchemeTask,
        identifiant: ObjectIdentifier,
        reponse: ReponseScheme
    ) {
        verrou.lock()
        let encore = actifs.contains(identifiant)
        actifs.remove(identifiant)
        verrou.unlock()
        guard encore else { return }
        guard let url = tache.request.url,
              let http = HTTPURLResponse(
                url: url,
                statusCode: reponse.code,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": reponse.typeMIME,
                    "Content-Length": String(reponse.donnees.count),
                ]
              ) else {
            tache.didFailWithError(URLError(.badServerResponse))
            return
        }
        tache.didReceive(http)
        tache.didReceive(reponse.donnees)
        tache.didFinish()
    }
}
