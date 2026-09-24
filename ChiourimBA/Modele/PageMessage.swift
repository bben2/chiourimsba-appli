import Foundation

enum PageMessage {
    static let titre = "Page indisponible"
    static let horsLigne = "Cette page n'a pas encore été téléchargée"

    static func donnees(_ message: String) -> Data {
        let corps = """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(titre)</title>
        <style>
        body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
               font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #faf8f3; color: #1e3a5f; }
        @media (prefers-color-scheme: dark) {
          body { background: #121826; color: #faf8f3; }
        }
        main { max-width: 28rem; padding: 2rem 1.4rem; text-align: center; }
        p { font-size: 1.15rem; line-height: 1.5; }
        </style>
        </head>
        <body><main><p>\(echapper(message))</p></main></body>
        </html>
        """
        return Data(corps.utf8)
    }

    private static func echapper(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
