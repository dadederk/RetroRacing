//
//  AuthenticationPresenterUniversal.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import RetroRacingShared

#if canImport(UIKit)
import UIKit

/// Presents Game Center authentication UI on iOS, iPadOS, tvOS. Callbacks are used to show the view controller from SwiftUI.
final class AuthenticationPresenterUniversal: AuthenticationPresenter {
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
