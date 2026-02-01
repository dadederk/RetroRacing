import Foundation
import RetroRacingShared

#if canImport(UIKit)
import UIKit

/// Presents Game Center authentication UI. Callbacks are used to show the view controller from SwiftUI.
final class iOSAuthenticationPresenter: AuthenticationPresenter {
    var onPresent: ((UIViewController) -> Void)?

    func presentAuthenticationUI(_ viewController: Any) {
        guard let vc = viewController as? UIViewController else { return }
        onPresent?(vc)
    }
}
#else
/// No-op presenter when UIKit is not available (e.g. macOS). Game Center auth UI is not presented.
final class NoOpAuthenticationPresenter: AuthenticationPresenter {
    func presentAuthenticationUI(_ viewController: Any) {}
}
#endif
