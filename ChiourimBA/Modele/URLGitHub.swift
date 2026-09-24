import Foundation

enum URLGitHub {
    static func brute(depot: String, chemin: String) -> URL? {
        var composants = URLComponents()
        composants.scheme = "https"
        composants.host = "raw.githubusercontent.com"
        composants.path = "/bben2/\(depot)/main/\(chemin)"
        return composants.url
    }

    static func commit(depot: String) -> URL? {
        URL(string: "https://api.github.com/repos/bben2/\(depot)/commits/main")
    }
}
