import XCTest

/// Parcours réel : le catalogue et les pages viennent de raw.githubusercontent.com.
final class ParcoursLectureUITests: XCTestCase {
    private var application: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        application = XCUIApplication()
        // Le catalogue public n'a pas encore la Halakha : sur le simulateur, les fichiers
        // déjà générés dans le dossier de développement priment (SIMULATOR_HOST_HOME).
        application.launchEnvironment["SIMULATOR_HOST_HOME"] = NSHomeDirectory()
        application.launch()
    }

    func testLectureGuemaraPuisHassidout() throws {
        let guemara = application.tabBars.buttons["Guemara"]
        XCTAssertTrue(guemara.waitForExistence(timeout: 30), "L'onglet Guemara est absent")
        guemara.tap()

        let berakhot = application.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Berakhot")).firstMatch
        XCTAssertTrue(berakhot.waitForExistence(timeout: 90), "Berakhot introuvable (catalogue réseau)")
        rendreVisible(berakhot)
        berakhot.tap()

        let feuille = application.buttons["2a"]
        XCTAssertTrue(feuille.waitForExistence(timeout: 30), "Le feuillet 2a est absent")
        rendreVisible(feuille)
        feuille.tap()

        let retour = application.buttons["Retour, Berakhot"]
        XCTAssertTrue(retour.waitForExistence(timeout: 90), "La lecture Berakhot ne s'est pas ouverte")
        XCTAssertEqual(application.state, .runningForeground)

        let rachi = application.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Rachi")).firstMatch
        XCTAssertTrue(rachi.waitForExistence(timeout: 90), "Aucun Rachi sur Berakhot 2a")
        application.swipeUp()
        application.swipeUp()
        rendreVisible(rachi)
        rachi.tap()
        XCTAssertEqual(application.state, .runningForeground)

        XCTAssertTrue(retour.waitForExistence(timeout: 10))
        retour.tap()

        let hassidout = application.tabBars.buttons["Hassidout"]
        XCTAssertTrue(hassidout.waitForExistence(timeout: 15))
        hassidout.tap()

        let livre = premierLivre()
        livre.tap()

        let section = premiereSection()
        section.tap()

        let ancre = application.buttons["Annoter ou signaler"]
        XCTAssertTrue(ancre.waitForExistence(timeout: 90), "La section hassidout ne s'est pas ouverte")
        XCTAssertEqual(application.state, .runningForeground)
    }

    func testLectureHalakhaKitsour() throws {
        let halakha = application.tabBars.buttons["Halakha"]
        XCTAssertTrue(halakha.waitForExistence(timeout: 30), "L'onglet Halakha est absent")
        halakha.tap()

        let kitsour = application.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Kitsour")).firstMatch
        XCTAssertTrue(kitsour.waitForExistence(timeout: 90), "Kitsour introuvable")
        rendreVisible(kitsour)
        kitsour.tap()

        let siman = application.buttons["001"]
        let libelle = application.buttons["Siman 1"]
        let cible = siman.waitForExistence(timeout: 20) ? siman : libelle
        XCTAssertTrue(cible.waitForExistence(timeout: 30), "Le siman 001 est absent")
        rendreVisible(cible)
        cible.tap()

        let ancre = application.buttons["Annoter ou signaler"]
        XCTAssertTrue(ancre.waitForExistence(timeout: 90), "Le siman 001 ne s'est pas ouvert")
        XCTAssertEqual(application.state, .runningForeground)
    }

    private func rendreVisible(_ element: XCUIElement) {
        var essais = 0
        while !element.isHittable, essais < 8 {
            application.swipeUp()
            essais += 1
        }
    }

    private func premierLivre() -> XCUIElement {
        let exclus = ["Guemara", "Hassidout", "Halakha", "Chiourim", "Mon espace"]
        let echeance = Date().addingTimeInterval(90)
        while Date() < echeance {
            let candidats = application.buttons.allElementsBoundByIndex.filter { bouton in
                guard bouton.isHittable else { return false }
                let titre = bouton.label
                if titre.isEmpty || exclus.contains(titre) || titre.hasPrefix("Retour") { return false }
                return bouton.frame.width > 220 && bouton.frame.height >= 44
            }
            if let premier = candidats.min(by: { $0.frame.minY < $1.frame.minY }) {
                return premier
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        }
        XCTFail("Premier livre Hassidout introuvable")
        return application.buttons.firstMatch
    }

    private func premiereSection() -> XCUIElement {
        let echeance = Date().addingTimeInterval(45)
        while Date() < echeance {
            let candidats = application.buttons.allElementsBoundByIndex.filter { bouton in
                guard bouton.isHittable else { return false }
                let titre = bouton.label
                if titre.hasPrefix("Retour") || titre.hasPrefix("Télécharger") || titre.hasPrefix("Annuler") { return false }
                if titre.contains("hors ligne") { return false }
                let cadre = bouton.frame
                return cadre.width > 20 && cadre.width < 160 && cadre.height >= 40 && cadre.height < 90
            }
            if let premier = candidats.min(by: { gauche, droite in
                if abs(gauche.frame.minY - droite.frame.minY) > 8 { return gauche.frame.minY < droite.frame.minY }
                return gauche.frame.minX < droite.frame.minX
            }) {
                return premier
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        XCTFail("Première section introuvable")
        return application.buttons.firstMatch
    }
}
