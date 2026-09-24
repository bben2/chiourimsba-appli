import XCTest
@testable import ChiourimBA

final class TypeMIMETests: XCTestCase {
    func testExtensions() {
        XCTAssertEqual(TypeMIME.pourExtension("html"), "text/html; charset=utf-8")
        XCTAssertEqual(TypeMIME.pourExtension("HTM"), "text/html; charset=utf-8")
        XCTAssertEqual(TypeMIME.pourExtension("css"), "text/css; charset=utf-8")
        XCTAssertEqual(TypeMIME.pourExtension("js"), "text/javascript; charset=utf-8")
        XCTAssertEqual(TypeMIME.pourExtension("svg"), "image/svg+xml")
        XCTAssertEqual(TypeMIME.pourExtension("png"), "image/png")
        XCTAssertEqual(TypeMIME.pourExtension("jpg"), "image/jpeg")
        XCTAssertEqual(TypeMIME.pourExtension("JPG"), "image/jpeg")
        XCTAssertEqual(TypeMIME.pourExtension("webp"), "image/webp")
        XCTAssertEqual(TypeMIME.pourExtension("pdf"), "application/pdf")
        XCTAssertEqual(TypeMIME.pourExtension("json"), "application/json")
        XCTAssertEqual(TypeMIME.pourExtension("woff2"), "font/woff2")
        XCTAssertEqual(TypeMIME.pourChemin("dossier/page.HTML"), "text/html; charset=utf-8")
        XCTAssertEqual(TypeMIME.pourExtension("bin"), "application/octet-stream")
        XCTAssertFalse(TypeMIME.pourExtension("html").hasPrefix("text/plain"))
    }
}
