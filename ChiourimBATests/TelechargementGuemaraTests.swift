import XCTest
@testable import ChiourimBA

final class TelechargementGuemaraTests: XCTestCase {
    func testTelechargeIndexGuemaraEnHTML() async throws {
        let dossier = FileManager.default.temporaryDirectory
            .appendingPathComponent("chiourim-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dossier) }

        let passerelle = PasserelleContenu(racine: dossier)
        let url = try XCTUnwrap(URL(string: "chiourim://guemara/index.html"))
        let reponse = await passerelle.repondre(a: url)

        XCTAssertEqual(reponse.code, 200)
        XCTAssertTrue(reponse.typeMIME.hasPrefix("text/html"), reponse.typeMIME)
        XCTAssertTrue(reponse.typeMIME.contains("charset=utf-8"))
        XCTAssertFalse(reponse.typeMIME.hasPrefix("text/plain"))

        let texte = try XCTUnwrap(String(data: reponse.donnees, encoding: .utf8))
        XCTAssertTrue(texte.lowercased().contains("<html"))
        XCTAssertTrue(texte.contains("Guemara"))
        XCTAssertTrue(texte.contains("<style"))
        XCTAssertFalse(texte.contains("chat.js"))
        XCTAssertFalse(texte.contains(PageMessage.horsLigne))

        let fichier = dossier.appendingPathComponent("guemara/index.html")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fichier.path))
    }
}
