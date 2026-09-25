import SwiftUI
import UIKit
import XCTest
@testable import ChiourimBA

final class DecodageDonneesTests: XCTestCase {
    func testCatalogueExemple() throws {
        let catalogue = try ClientDonnees.decoderCatalogue(Data(ExempleJSON.catalogue.utf8))
        XCTAssertEqual(catalogue.version, 1)
        XCTAssertEqual(catalogue.collections.map(\.id), ["guemara", "hassidout", "halakha"])
        let bekhorot = try XCTUnwrap(catalogue.oeuvre(collection: "guemara", id: "Bekhorot"))
        XCTAssertEqual(bekhorot.unites, ["2a", "2b"])
        XCTAssertEqual(bekhorot.titreHe, "בכורות")
        let hassidout = try XCTUnwrap(catalogue.collection("hassidout")?.oeuvres.first)
        XCTAssertEqual(hassidout.auteur, "Rabbi Tsadok HaCohen de Lublin")
        XCTAssertEqual(catalogue.collection("halakha")?.oeuvres, [])
        let groupes = OrdreTalmud.groupes(catalogue.collection("guemara")?.oeuvres ?? [])
        XCTAssertEqual(groupes.map(\.nom), ["Seder Kodachim"])
        XCTAssertEqual(SourceDonnees.base, "https://raw.githubusercontent.com/bben2/chiourimsba-donnees/main/")
    }

    func testPageGuemaraEtHassidout() throws {
        let page = try ClientDonnees.decoderPage(Data(ExempleJSON.bekhorot.utf8))
        XCTAssertEqual(page.ref, "Bekhorot 2a")
        XCTAssertEqual(page.segments.count, 1)
        let segment = try XCTUnwrap(page.segments.first)
        XCTAssertFalse(segment.he.isEmpty)
        XCTAssertFalse(segment.fr.isEmpty)
        XCTAssertEqual(segment.rashi.first?.dh, "הלוקח")
        XCTAssertEqual(segment.tosafot.count, 1)
        XCTAssertEqual(segment.roch.count, 1)
        XCTAssertTrue(segment.explication?.contains("premier-né") == true)
        XCTAssertTrue(segment.schema?.svg.contains("<svg") == true)
        XCTAssertEqual(page.schemas.count, 1)

        let section = try ClientDonnees.decoderPage(Data(ExempleJSON.hassidout.utf8))
        XCTAssertEqual(section.segments.first?.fr, "Le juste donne sans compter.")
        XCTAssertTrue(section.segments.first?.rashi.isEmpty == true)

        let ancienne = try ClientDonnees.decoderPage(Data(ExempleJSON.gloseTitre.utf8))
        XCTAssertEqual(ancienne.segments.first?.rashi.first?.dh, "מתני׳")
    }

    func testCheminsPublics() {
        let oeuvre = Oeuvre(id: "Bekhorot", titre: "Bekhorot", titreHe: "בכורות", auteur: nil, chemin: "guemara/Bekhorot/", unites: ["2a"])
        XCTAssertEqual(SourceDonnees.cheminPage(oeuvre: oeuvre, unite: "2a"), "guemara/Bekhorot/2a.json")
        XCTAssertEqual(SourceDonnees.pageHTML(collectionID: "guemara", oeuvreID: "Bekhorot", unite: "2a"), "Bekhorot_2a.html")
        XCTAssertEqual(SourceDonnees.pageHTML(collectionID: "hassidout", oeuvreID: "tzidkat", unite: "001"), "tzidkat/001.html")
        XCTAssertEqual(
            SourceDonnees.urlPartage(collectionID: "guemara", page: "Bekhorot_2a.html")?.absoluteString,
            "https://guemara.vercel.app/Bekhorot_2a.html"
        )
        XCTAssertNil(SourceDonnees.relatifSur("../secret.json"))
        XCTAssertEqual(SourceDonnees.relatifSur("/guemara/Bekhorot/2a.json"), "guemara/Bekhorot/2a.json")
    }

    func testExplicationHTMLSansWebKit() {
        let texte = HTMLSimple.attribue("<p>Le <b>Chema</b> du soir.</p><p>a &amp; b</p>", taille: 18)
        XCTAssertEqual(String(texte.characters), "Le Chema du soir.\na & b")
        XCTAssertGreaterThan(texte.runs.count, 1)
    }

    func testPolicesEmbarquees() {
        XCTAssertNotNil(UIFont(name: "EBGaramond-SemiBold", size: 17))
        XCTAssertNotNil(UIFont(name: "EBGaramond-Regular", size: 17))
        XCTAssertNotNil(UIFont(name: "FrankRuhlLibre-Regular_Medium", size: 17))
        XCTAssertNotNil(UIFont(name: "FrankRuhlLibre-Regular_Bold", size: 17))
    }
}

final class CacheDisqueTests: XCTestCase {
    private var racine: URL!

    override func setUpWithError() throws {
        racine = FileManager.default.temporaryDirectory.appending(path: "cache-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: racine)
    }

    func testEcritureLectureEtRejet() throws {
        let cache = CacheDisque(racine: racine)
        XCTAssertNil(cache.lire("catalogue.json"))
        let data = Data("{\"ok\":true}".utf8)
        try cache.ecrire("guemara/Bekhorot/2a.json", data)
        XCTAssertEqual(cache.lire("guemara/Bekhorot/2a.json"), data)
        XCTAssertTrue(cache.existe("guemara/Bekhorot/2a.json"))
        XCTAssertGreaterThan(cache.taille(), 0)
        XCTAssertNil(cache.urlFichier("../secret.json"))
        XCTAssertThrowsError(try cache.ecrire("../secret.json", data))
        let oeuvre = Oeuvre(id: "Bekhorot", titre: "Bekhorot", titreHe: "ב", auteur: nil, chemin: "guemara/Bekhorot/", unites: ["2a"])
        XCTAssertTrue(cache.oeuvreComplete(oeuvre))
        let incomplet = Oeuvre(id: "Bekhorot", titre: "Bekhorot", titreHe: "ב", auteur: nil, chemin: "guemara/Bekhorot/", unites: ["2a", "2b"])
        XCTAssertFalse(cache.oeuvreComplete(incomplet))
        try cache.vider()
        XCTAssertNil(cache.lire("guemara/Bekhorot/2a.json"))
        XCTAssertEqual(cache.taille(), 0)
    }
}

final class FileSignalementsTests: XCTestCase {
    private var fichier: URL!

    override func setUpWithError() throws {
        fichier = FileManager.default.temporaryDirectory.appending(path: "sign-\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fichier)
    }

    func testCorpsEtFile() throws {
        let corps = CorpsSignalement(site: "guemara", page: "Bekhorot_2a.html", passage: "oubar", correction: "le petit", source: "appli", siteWeb: "")
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(corps)) as? [String: String]
        XCTAssertEqual(json?["site"], "guemara")
        XCTAssertEqual(json?["page"], "Bekhorot_2a.html")
        XCTAssertEqual(json?["source"], "appli")
        XCTAssertEqual(json?["site_web"], "")
        XCTAssertEqual(SignalementService.interpreter(code: 201), .envoye)
        XCTAssertEqual(SignalementService.interpreter(code: 503), .bientot)
        XCTAssertEqual(IssueEnvoi.bientot.message, "Les signalements ouvrent bientôt.")
        XCTAssertEqual(IssueEnvoi.envoye.message, "Merci, c'est envoyé.")

        let file = FileSignalements(fichier: fichier)
        let entree = try file.ajouter(site: "hassidout", page: "tzidkat/001.html", passage: "passage", correction: "correction")
        XCTAssertEqual(file.enAttente().map(\.id), [entree.id])
        try file.appliquer(id: entree.id, issue: .bientot)
        XCTAssertEqual(file.lire().first?.etat, "attente")
        try file.appliquer(id: entree.id, issue: .reseau)
        XCTAssertEqual(file.enAttente().count, 1)
        try file.appliquer(id: entree.id, issue: .envoye)
        XCTAssertTrue(file.enAttente().isEmpty)
        XCTAssertEqual(file.lire().first?.etat, "envoye")
    }
}

private enum ExempleJSON {
    static let catalogue = """
    {"version":1,"mise_a_jour":"2026-09-25T10:00:00+02:00","collections":[{"id":"guemara","titre":"Guemara","titre_he":"גמרא","oeuvres":[{"id":"Bekhorot","titre":"Bekhorot","titre_he":"בכורות","chemin":"guemara/Bekhorot/","unites":["2a","2b"]}]},{"id":"hassidout","titre":"Hassidout et moussar","titre_he":"חסידות ומוסר","oeuvres":[{"id":"tzidkat","titre":"Tsidkat HaTsadik","titre_he":"צדקת הצדיק","auteur":"Rabbi Tsadok HaCohen de Lublin","chemin":"hassidout/tzidkat/","unites":["001"]}]},{"id":"halakha","titre":"Halakha","titre_he":"הלכה","oeuvres":[]}]}
    """

    static let bekhorot = """
    {"ref":"Bekhorot 2a","titre":"Le premier-né de l'âne","resume":"La part du non-Juif","segments":[{"he":"מתני׳ הלוקח עובר חמורו של נכרי","fr":"MICHNA. Celui qui achète le fœtus de l'âne d'un non-Juif.","rashi":[{"dh":"הלוקח","he":"הלוקח עובר","fr":"Celui qui achète le fœtus."}],"tosafot":[{"dh":"אעפ","he":"אף על פי","fr":"Bien qu'il n'en ait pas le droit."}],"roch":[{"he":"וכן פסק","fr":"Et ainsi est la décision."}],"explication":"<p>Le <b>premier-né</b> de l'âne.</p>","schema":{"svg":"<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 200 80\\"><rect width=\\"200\\" height=\\"80\\"/></svg>","legende":"Les deux cas"}}],"schemas":[{"svg":"<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 120 60\\"></svg>","legende":"Vue d'ensemble"}]}
    """

    static let hassidout = """
    {"ref":"Tsidkat HaTsadik 1","titre":"Section 1","segments":[{"he":"הצדיק נותן","fr":"Le juste donne sans compter."}]}
    """

    static let gloseTitre = """
    {"ref":"Bekhorot 2a","titre":"","segments":[{"he":"מתני","fr":"Michna.","rashi":[{"titre":"מתני׳","fr":"Notre michna."}]}]}
    """
}
