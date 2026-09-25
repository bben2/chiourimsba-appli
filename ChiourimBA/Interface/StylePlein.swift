import SwiftUI

/// Style « plain » dont toute la surface de la ligne répond au toucher (Spacer compris), avec un léger retour visuel.
struct StylePlein: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
