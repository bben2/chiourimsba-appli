import UIKit
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

    func testSchemaBekhorotPassage4() throws {
        let guemara = application.tabBars.buttons["Guemara"]
        XCTAssertTrue(guemara.waitForExistence(timeout: 30), "L'onglet Guemara est absent")
        guemara.tap()

        let bekhorot = application.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Bekhorot")).firstMatch
        XCTAssertTrue(attendreVisible(bekhorot, delai: 90), "Bekhorot introuvable")
        bekhorot.tap()

        let feuille = application.buttons["2a"]
        XCTAssertTrue(feuille.waitForExistence(timeout: 30), "Le feuillet 2a est absent")
        XCTAssertTrue(attendreVisible(feuille, delai: 20), "Le feuillet 2a n'est pas atteignable")
        feuille.tap()

        let retour = application.buttons["Retour, Bekhorot"]
        XCTAssertTrue(retour.waitForExistence(timeout: 90), "La lecture Bekhorot ne s'est pas ouverte")

        let predicat = NSPredicate(
            format: "label CONTAINS %@ AND label CONTAINS %@ AND NOT (label CONTAINS %@)",
            "Schéma",
            "La mahloket sur la société avec un non-Juif.",
            "Sages"
        )
        let schema = application.descendants(matching: .any).matching(predicat).firstMatch
        let echeance = Date().addingTimeInterval(50)
        while Date() < echeance {
            if schema.exists {
                let cadre = schema.frame
                let valeur = (schema.value as? String) ?? ""
                let aLEcran = cadre.maxY > 8 && cadre.minY < application.frame.height - 8
                if cadre.height > 120, aLEcran, valeur == "visible" {
                    XCTAssertGreaterThan(cadre.height, 120)
                    XCTAssertTrue(contraste(schema.screenshot().image), "Le schéma du passage 4 est vide")
                    return
                }
                if cadre.maxY < 48 {
                    application.swipeDown(velocity: .slow)
                } else if cadre.minY > application.frame.height * 0.62 {
                    application.swipeUp(velocity: .slow)
                }
            } else {
                application.swipeUp(velocity: .slow)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        }
        let voisins = application.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Schéma"))
            .allElementsBoundByIndex
            .prefix(8)
            .map { "\($0.label) h=\($0.frame.height) v=\($0.value ?? "")" }
        XCTFail("Schéma du passage 4 invisible. exists=\(schema.exists) frame=\(schema.exists ? "\(schema.frame)" : "-") value=\(schema.exists ? "\(schema.value ?? "")" : "-") voisins=\(voisins)")
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
        _ = attendreVisible(element, delai: 12)
    }

    @discardableResult
    private func attendreVisible(_ element: XCUIElement, delai: TimeInterval) -> Bool {
        let echeance = Date().addingTimeInterval(delai)
        while Date() < echeance {
            if element.exists, element.isHittable { return true }
            application.swipeUp(velocity: .slow)
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return element.exists && element.isHittable
    }

    private func contraste(_ image: UIImage) -> Bool {
        guard let cg = image.cgImage, cg.width > 4, cg.height > 4 else { return false }
        let cote = 40
        var pixels = [UInt8](repeating: 0, count: cote * cote * 4)
        guard let contexte = CGContext(
            data: &pixels,
            width: cote,
            height: cote,
            bitsPerComponent: 8,
            bytesPerRow: cote * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        contexte.draw(cg, in: CGRect(x: 0, y: 0, width: cote, height: cote))
        var minC = 255
        var maxC = 0
        var opaques = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            if pixels[index + 3] < 16 { continue }
            opaques += 1
            for canal in 0..<3 {
                minC = min(minC, Int(pixels[index + canal]))
                maxC = max(maxC, Int(pixels[index + canal]))
            }
        }
        return opaques > cote * cote / 4 && maxC - minC >= 8
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
