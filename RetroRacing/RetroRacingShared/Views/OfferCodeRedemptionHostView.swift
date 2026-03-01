#if os(macOS)
import SwiftUI
import AppKit

/// Invisible host view used to provide an NSViewController for StoreKit offer-code redemption.
struct OfferCodeRedemptionHostView: NSViewControllerRepresentable {
    @Binding var controller: NSViewController?

    func makeNSViewController(context: Context) -> NSViewController {
        let hostController = NSViewController()
        Task { @MainActor in
            controller = hostController
        }
        return hostController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard controller !== nsViewController else { return }
        Task { @MainActor in
            controller = nsViewController
        }
    }
}
#endif
