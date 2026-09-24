import XCTest
@testable import ChiourimBA

final class ReecritureLienTests: XCTestCase {
    func testPortail() throws {
        let decision = ReecritureLien.decider(URL(string: "https://chiourimsba.vercel.app/pdf/note.pdf")!)
        guard case .interne(let url) = decision else { return XCTFail("\(decision)") }
        XCTAssertEqual(url.scheme, "chiourim")
        XCTAssertEqual(url.host, "portail")
        XCTAssertEqual(url.path, "/pdf/note.pdf")
    }

    func testGuemara() throws {
        let decision = ReecritureLien.decider(URL(string: "https://guemara.vercel.app/Taanit_2a.html")!)
        guard case .interne(let url) = decision else { return XCTFail("\(decision)") }
        XCTAssertEqual(url.host, "guemara")
        XCTAssertEqual(url.path, "/Taanit_2a.html")
    }

    func testHassidout() throws {
        let decision = ReecritureLien.decider(URL(string: "http://hassidout.vercel.app/noamelimelech/001.html")!)
        guard case .interne(let url) = decision else { return XCTFail("\(decision)") }
        XCTAssertEqual(url.host, "hassidout")
        XCTAssertEqual(url.path, "/noamelimelech/001.html")
    }

    func testHalakhaAvecRequeteEtFragment() throws {
        let decision = ReecritureLien.decider(
            URL(string: "https://www.halakha.vercel.app/orach-chayim/001.html?x=1#perek")!
        )
        guard case .interne(let url) = decision else { return XCTFail("\(decision)") }
        XCTAssertEqual(url.host, "halakha")
        XCTAssertEqual(url.path, "/orach-chayim/001.html")
        XCTAssertEqual(url.query, "x=1")
        XCTAssertEqual(url.fragment, "perek")
    }

    func testRacineGuemara() throws {
        let decision = ReecritureLien.decider(URL(string: "https://guemara.vercel.app")!)
        guard case .interne(let url) = decision else { return XCTFail("\(decision)") }
        XCTAssertEqual(url.host, "guemara")
        XCTAssertEqual(CheminContenu.normaliser(url.path), "index.html")
    }

    func testOtsrotBloque() {
        XCTAssertEqual(
            ReecritureLien.decider(URL(string: "https://otsrot.vercel.app/secret")!),
            .bloque
        )
        XCTAssertEqual(
            ReecritureLien.decider(URL(string: "https://www.otsrot.vercel.app/")!),
            .bloque
        )
        XCTAssertEqual(
            ReecritureLien.decider(URL(string: "chiourim://bloque/interdit")!),
            .bloque
        )
    }

    func testCourriel() {
        let mail = URL(string: "mailto:chiourimsba@gmail.com?subject=Erreur")!
        XCTAssertEqual(ReecritureLien.decider(mail), .courriel(mail))
    }

    func testSefariaDansSafari() {
        let lien = URL(string: "https://www.sefaria.org/Berakhot.2a")!
        XCTAssertEqual(ReecritureLien.decider(lien), .safari(lien))
    }

    func testDejaChiourim() throws {
        let lien = URL(string: "chiourim://guemara/Taanit_2a.html")!
        guard case .interne(let url) = ReecritureLien.decider(lien) else {
            return XCTFail("lien interne")
        }
        XCTAssertEqual(url, lien)
    }

    func testReecritureHTMLRetireLaDiscussion() {
        let html = """
        <a href="https://guemara.vercel.app/a.html">A</a>
        <script src="https://chiourimsba.vercel.app/chat.js" defer></script>
        <a href="https://otsrot.vercel.app/secret">non</a>
        """
        let resultat = ReecritureLien.reecrireTexte(html, retirerDiscussion: true)
        XCTAssertTrue(resultat.contains("chiourim://guemara/a.html"))
        XCTAssertTrue(resultat.contains("chiourim://bloque/secret"))
        XCTAssertFalse(resultat.contains("chat.js"))
        XCTAssertFalse(resultat.contains("vercel.app"))
    }
}
