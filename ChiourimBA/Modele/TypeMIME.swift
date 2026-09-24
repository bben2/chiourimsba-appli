import Foundation

enum TypeMIME {
    static func pourChemin(_ chemin: String) -> String {
        pourExtension((chemin as NSString).pathExtension)
    }

    static func pourExtension(_ extensionFichier: String) -> String {
        switch extensionFichier.lowercased() {
        case "html", "htm":
            return "text/html; charset=utf-8"
        case "css":
            return "text/css; charset=utf-8"
        case "js", "mjs":
            return "text/javascript; charset=utf-8"
        case "svg":
            return "image/svg+xml"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "webp":
            return "image/webp"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "json":
            return "application/json"
        case "woff2":
            return "font/woff2"
        case "woff":
            return "font/woff"
        case "ttf":
            return "font/ttf"
        case "otf":
            return "font/otf"
        case "ico":
            return "image/x-icon"
        case "xml":
            return "application/xml"
        case "txt":
            return "text/plain; charset=utf-8"
        case "webmanifest":
            return "application/manifest+json"
        default:
            return "application/octet-stream"
        }
    }

    static func estTexte(_ mime: String) -> Bool {
        let valeur = mime.lowercased()
        return valeur.hasPrefix("text/")
            || valeur.contains("javascript")
            || valeur.contains("json")
            || valeur.contains("svg")
            || valeur.contains("xml")
    }
}
