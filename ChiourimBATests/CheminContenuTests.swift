import XCTest
@testable import ChiourimBA

final class CheminContenuTests: XCTestCase {
    func testSlashDevientIndex() {
        XCTAssertEqual(CheminContenu.normaliser("/"), "index.html")
        XCTAssertEqual(CheminContenu.normaliser(""), "index.html")
        XCTAssertEqual(CheminContenu.normaliser("/orach-chayim/"), "orach-chayim/index.html")
    }

    func testCheminDecodeEtRelatif() {
        XCTAssertEqual(CheminContenu.normaliser("/pdf/a%20b.pdf"), "pdf/a b.pdf")
        XCTAssertEqual(CheminContenu.normaliser("/orach-chayim/001.html"), "orach-chayim/001.html")
        XCTAssertEqual(
            ExtracteurLiens.resoudre("../index.html", depuis: "noamelimelech/001.html", siteID: "hassidout"),
            "index.html"
        )
        XCTAssertEqual(
            ExtracteurLiens.resoudre("/annot.js", depuis: "noamelimelech/001.html", siteID: "hassidout"),
            "annot.js"
        )
        XCTAssertNil(CheminContenu.normaliser("/../secret.html"))
    }

    func testCheminCache() throws {
        let racine = URL(fileURLWithPath: "/Library/Caches/Contenu", isDirectory: true)
        let url = try XCTUnwrap(CacheContenu.urlFichier(racine: racine, siteID: "guemara", chemin: "Taanit_2a.html"))
        XCTAssertEqual(url.path, "/Library/Caches/Contenu/guemara/Taanit_2a.html")
        XCTAssertNil(CacheContenu.urlFichier(racine: racine, siteID: "guemara", chemin: "../secret.html"))
    }

    func testURLGitHubEncodeLesEspaces() throws {
        let url = try XCTUnwrap(URLGitHub.brute(depot: "chiourimsba-portail", chemin: "pdf/a b.pdf"))
        XCTAssertEqual(
            url.absoluteString,
            "https://raw.githubusercontent.com/bben2/chiourimsba-portail/main/pdf/a%20b.pdf"
        )
    }
}
