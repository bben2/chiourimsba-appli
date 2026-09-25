import UIKit
import XCTest

/// Captures App Store. Schéma séparé : n'entre pas dans les tests du schéma ChiourimBA.
@MainActor
final class CapturesAppStoreUITests: XCTestCase {
    private var application: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 1200
        XCUIDevice.shared.orientation = .portrait
        application = XCUIApplication()
        application.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        // Fichiers déjà générés sur le Mac ; sinon le réseau (raw.githubusercontent.com).
        application.launchEnvironment["SIMULATOR_HOST_HOME"] = "/Users/benjaminabbou"
        application.launch()
    }

    func testCapturesAppStore() throws {
        attendreAccueil()
        capturer("01_accueil")

        ouvrirOnglet("Guemara")
        attendreListeGuemara()
        capturer("02_guemara")

        ouvrirBekhorot2a()
        attendreHautBekhorot()
        capturer("03_bekhorot")

        deplierRachi()
        capturer("04_rachi")

        cadrerSchemaPassage4()
        capturer("05_schema")

        ouvrirLectureHassidout()
        capturer("06_hassidout")

        ouvrirLectureHalakha()
        capturer("07_halakha")

        application.terminate()
        application.launchArguments.append("-captureEspace")
        application.launch()
        attendreEspace()
        capturer("08_espace")
    }

    // MARK: - Parcours

    private func attendreAccueil() {
        let bibliotheque = element(etiquetteContient: "La bibliothèque")
        let traites = element(etiquetteContient: "traité")
        let echeance = Date().addingTimeInterval(90)
        while Date() < echeance {
            if bibliotheque.exists, traites.exists, !ecranBloque() {
                poser(0.6)
                return
            }
            retenterSiErreur()
            poser(0.4)
        }
        XCTFail("Accueil non chargé. bloqué=\(ecranBloque())")
    }

    private func attendreListeGuemara() {
        let bekhorot = boutonContenant("Bekhorot")
        let seder = element(etiquetteContient: "Seder")
        let echeance = Date().addingTimeInterval(90)
        while Date() < echeance {
            if seder.exists, !ecranBloque() {
                poser(0.5)
                return
            }
            if bekhorot.exists, !ecranBloque() {
                poser(0.5)
                return
            }
            retenterSiErreur()
            poser(0.4)
        }
        XCTFail("Liste des traités absente")
    }

    private func ouvrirBekhorot2a() {
        let bekhorot = boutonContenant("Bekhorot")
        XCTAssertTrue(rendreVisible(bekhorot, delai: 40), "Bekhorot introuvable")
        bekhorot.tap()
        let feuille = application.buttons["2a"]
        XCTAssertTrue(feuille.waitForExistence(timeout: 30), "Feuillet 2a absent")
        XCTAssertTrue(rendreVisible(feuille, delai: 15), "Feuillet 2a hors d'atteinte")
        feuille.tap()
    }

    private func attendreHautBekhorot() {
        let titre = element(etiquetteContient: "Bekhorot 2a")
        let resume = element(etiquetteContient: "La Michna ouvre")
        let michna = element(etiquetteContient: "MICHNA")
        XCTAssertTrue(titre.waitForExistence(timeout: 90), "Lecture Bekhorot absente")
        let echeance = Date().addingTimeInterval(40)
        while Date() < echeance {
            if titre.exists, resume.exists, michna.exists, hebreuVisible(), !ecranBloque(), surEcran(titre) {
                poser(0.6)
                return
            }
            retenterSiErreur()
            poser(0.35)
        }
        XCTFail("Haut de Bekhorot 2a incomplet. titre=\(titre.exists) resume=\(resume.exists) michna=\(michna.exists) he=\(hebreuVisible())")
    }

    private func deplierRachi() {
        let rachi = application.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Rachi")).firstMatch
        XCTAssertTrue(rendreVisible(rachi, delai: 25), "Rachi introuvable")
        rachi.tap()
        let mot = element(etiquetteContient: "Mot d'entrée")
        XCTAssertTrue(mot.waitForExistence(timeout: 10), "Rachi non déplié")
        cadrer(mot, margeHaute: 160)
        XCTAssertTrue(surEcran(rachi) || surEcran(mot), "Rachi déplié hors écran")
        poser(0.4)
    }

    private func cadrerSchemaPassage4() {
        for _ in 0 ..< 7 {
            application.swipeUp(velocity: .slow)
            poser(0.6)
        }
    }

    private func ouvrirLectureHassidout() {
        ouvrirOnglet("Hassidout")
        let livre = boutonContenant("Tzidkat")
        XCTAssertTrue(rendreVisible(livre, delai: 90), "Tzidkat HaTzadik introuvable")
        livre.tap()
        let section = application.buttons["001"]
        XCTAssertTrue(section.waitForExistence(timeout: 30), "Section 001 absente")
        XCTAssertTrue(rendreVisible(section, delai: 15), "Section 001 hors d'atteinte")
        section.tap()
        let ancre = element(etiquetteContient: "Section 1")
        XCTAssertTrue(ancre.waitForExistence(timeout: 90), "Lecture Tzidkat absente")
        let echeance = Date().addingTimeInterval(30)
        while Date() < echeance {
            if ancre.exists, hebreuVisible(), !ecranBloque() {
                poser(0.6)
                return
            }
            retenterSiErreur()
            poser(0.35)
        }
        XCTFail("Lecture Hassidout incomplète")
    }

    private func ouvrirLectureHalakha() {
        ouvrirOnglet("Halakha")
        let kitsour = boutonContenant("Kitsour")
        XCTAssertTrue(rendreVisible(kitsour, delai: 90), "Kitsour introuvable")
        kitsour.tap()
        let siman = application.buttons["Siman 1"]
        XCTAssertTrue(siman.waitForExistence(timeout: 30), "Siman 1 absent")
        XCTAssertTrue(rendreVisible(siman, delai: 15), "Siman 1 hors d'atteinte")
        siman.tap()
        let ancre = element(etiquetteContient: "Siman 1")
        XCTAssertTrue(ancre.waitForExistence(timeout: 90), "Lecture du siman 1 absente")
        let echeance = Date().addingTimeInterval(30)
        while Date() < echeance {
            if ancre.exists, hebreuVisible(), !ecranBloque() {
                poser(0.6)
                return
            }
            retenterSiErreur()
            poser(0.35)
        }
        XCTFail("Lecture Halakha incomplète")
    }

    private func attendreEspace() {
        let titre = element(etiquetteContient: "Où j'en suis")
        if !titre.waitForExistence(timeout: 20) {
            ouvrirOnglet("Mon espace")
        }
        XCTAssertTrue(titre.waitForExistence(timeout: 60), "Mon espace absent")
        let lecture = element(etiquetteContient: "Bekhorot")
        _ = lecture.waitForExistence(timeout: 8)
        poser(0.5)
        XCTAssertFalse(ecranBloque(), "Mon espace encore en chargement ou en erreur")
    }

    // MARK: - Navigation

    private func ouvrirOnglet(_ titre: String) {
        if titre == "Mon espace" {
            let onglets = application.tabBars.buttons.allElementsBoundByIndex
            if let dernier = onglets.last, dernier.exists {
                dernier.tap()
                poser(2.5)
                return
            }
        }
        let tab = application.tabBars.buttons[titre]
        if tab.waitForExistence(timeout: 10) {
            tab.tap()
            poser(2.5)
            return
        }
        if tapLaterale(titre) { return }
        revelerLaterale()
        XCTAssertTrue(tapLaterale(titre), "Onglet \(titre) introuvable. boutons=\(noms(application.buttons, 25))")
        poser(0.4)
    }

    @discardableResult
    private func tapLaterale(_ titre: String) -> Bool {
        let predicat = NSPredicate(format: "label == %@", titre)
        let candidats = [
            application.cells.matching(predicat).firstMatch,
            application.buttons.matching(predicat).firstMatch,
            application.otherElements.matching(predicat).firstMatch,
        ]
        for candidat in candidats where candidat.exists && candidat.isHittable {
            candidat.tap()
            poser(0.35)
            return true
        }
        return false
    }

    private func revelerLaterale() {
        let libelles = [
            "Afficher la barre latérale",
            "Show Sidebar",
            "sidebar.leading",
        ]
        for libelle in libelles {
            let bouton = application.buttons[libelle]
            if bouton.exists, bouton.isHittable {
                bouton.tap()
                poser(0.4)
                return
            }
        }
        let contenant = application.buttons.matching(NSPredicate(format: "label CONTAINS %@", "barre latérale")).firstMatch
        if contenant.exists, contenant.isHittable, !contenant.label.contains("Masquer") {
            contenant.tap()
            poser(0.4)
        }
    }

    // MARK: - Cadrage

    @discardableResult
    private func rendreVisible(_ element: XCUIElement, delai: TimeInterval) -> Bool {
        let echeance = Date().addingTimeInterval(delai)
        while Date() < echeance {
            if element.exists, element.isHittable { return true }
            application.swipeUp(velocity: .slow)
            poser(0.25)
        }
        return element.exists && element.isHittable
    }

    private func cadrer(_ element: XCUIElement, margeHaute: CGFloat) {
        let echeance = Date().addingTimeInterval(20)
        while Date() < echeance {
            guard element.exists else {
                application.swipeUp(velocity: .slow)
                poser(0.25)
                continue
            }
            let cadre = element.frame
            let haut = application.frame.height
            if cadre.minY >= margeHaute, cadre.maxY < haut - 24 { return }
            if cadre.minY < margeHaute {
                application.swipeDown(velocity: .slow)
            } else {
                application.swipeUp(velocity: .slow)
            }
            poser(0.3)
        }
    }

    private func surEcran(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let cadre = element.frame
        return cadre.width > 2 && cadre.height > 2
            && cadre.maxY > 12
            && cadre.minY < application.frame.height - 12
    }

    private func hebreuVisible() -> Bool {
        let textes = application.staticTexts
        let total = min(textes.count, 40)
        for index in 0 ..< total {
            let texte = textes.element(boundBy: index)
            guard texte.exists, surEcran(texte) else { continue }
            if texte.label.unicodeScalars.contains(where: { (0x0590 ... 0x05FF).contains($0.value) }) {
                return true
            }
        }
        return false
    }

    // MARK: - État

    private func ecranBloque() -> Bool {
        if clavierVisible() { return true }
        let interdits = ["Chargement", "Catalogue indisponible", "Page indisponible", "Hors connexion"]
        for interdit in interdits {
            let trouve = application.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", interdit))
                .firstMatch
            if trouve.exists { return true }
        }
        return false
    }

    private func clavierVisible() -> Bool {
        let clavier = application.keyboards.firstMatch
        guard clavier.exists else { return false }
        let cadre = clavier.frame
        return cadre.height > 40 && cadre.width > 40 && cadre.minY < application.frame.height - 8
    }

    private func retenterSiErreur() {
        let bouton = application.buttons["Réessayer"]
        if bouton.exists, bouton.isHittable { bouton.tap() }
    }

    private func capturer(_ nom: String, fichier: StaticString = #filePath, ligne: UInt = #line) {
        XCTAssertFalse(clavierVisible(), "Clavier visible sur \(nom)", file: fichier, line: ligne)
        let chargement = application.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Chargement"))
            .firstMatch
        XCTAssertFalse(chargement.exists, "Chargement visible sur \(nom)", file: fichier, line: ligne)
        let erreur = application.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "indisponible", "Hors connexion"))
            .firstMatch
        XCTAssertFalse(erreur.exists, "Erreur visible sur \(nom)", file: fichier, line: ligne)
        poser(0.25)
        let piece = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        piece.name = nom
        piece.lifetime = .keepAlways
        add(piece)
    }

    private func element(etiquetteContient fragment: String) -> XCUIElement {
        application.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", fragment))
            .firstMatch
    }

    private func boutonContenant(_ fragment: String) -> XCUIElement {
        application.buttons.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
    }

    private func noms(_ requete: XCUIElementQuery, _ limite: Int) -> [String] {
        requete.allElementsBoundByIndex.prefix(limite).map { $0.label }
    }

    private func poser(_ secondes: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(secondes))
    }
}
