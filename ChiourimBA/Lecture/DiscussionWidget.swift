import Foundation
@preconcurrency import WebKit

/// Le widget `chat.js` appelle une API Vercel. Il reste éteint tant que `estActive` vaut `false`.
enum DiscussionWidget {
    static let estActive = false

    static let source = """
    (function () {
      if (window.__chiourimChatAutorise) { return; }
      var bloque = function (valeur) {
        if (!valeur) { return false; }
        var s = String(valeur);
        return s.indexOf("chat.js") !== -1 || s.indexOf("/api/chat") !== -1;
      };
      var descripteur = Object.getOwnPropertyDescriptor(HTMLScriptElement.prototype, "src");
      if (descripteur && descripteur.set && descripteur.get) {
        Object.defineProperty(HTMLScriptElement.prototype, "src", {
          configurable: true,
          get: function () { return descripteur.get.call(this); },
          set: function (valeur) { if (!bloque(valeur)) { descripteur.set.call(this, valeur); } }
        });
      }
      var style = document.createElement("style");
      style.textContent = "#ct-btn,#ct-p{display:none !important;}";
      var racine = document.documentElement || document.head;
      if (racine) { racine.appendChild(style); }
    })();
    """

    @MainActor
    static func script() -> WKUserScript {
        WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
