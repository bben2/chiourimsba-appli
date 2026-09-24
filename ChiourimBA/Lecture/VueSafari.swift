import SafariServices
import SwiftUI

struct LienSafari: Identifiable, Hashable {
    let url: URL
    var id: String { url.absoluteString }
}

struct VueSafari: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controleur = SFSafariViewController(url: url)
        controleur.preferredControlTintColor = UIColor(red: 30 / 255, green: 58 / 255, blue: 95 / 255, alpha: 1)
        return controleur
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
