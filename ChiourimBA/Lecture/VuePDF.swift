import PDFKit
import SwiftUI

struct VuePDF: UIViewRepresentable {
    let url: URL
    var zoom: CGFloat

    func makeUIView(context: Context) -> PDFView {
        let vue = PDFView()
        vue.autoScales = true
        vue.displayMode = .singlePageContinuous
        vue.displayDirection = .vertical
        vue.backgroundColor = .systemBackground
        vue.document = PDFDocument(url: url)
        return vue
    }

    func updateUIView(_ vue: PDFView, context: Context) {
        if vue.document?.documentURL != url {
            vue.autoScales = true
            vue.document = PDFDocument(url: url)
        }
        let base = max(vue.scaleFactorForSizeToFit, 0.01)
        vue.minScaleFactor = base * 0.7
        vue.maxScaleFactor = base * 2
        let cible = base * zoom
        if abs(vue.scaleFactor - cible) > 0.02 {
            vue.scaleFactor = cible
        }
    }
}
