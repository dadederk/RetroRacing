//
//  AuthenticationPresenterUniversal.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Presenter capable of handing off UIKit view controllers for Game Center authentication.
public protocol UIKitAuthenticationPresenter: AuthenticationPresenter {
    func setPresentationHandler(_ handler: @escaping (UIViewController) -> Void)
}

/// Presents Game Center authentication UI on iOS, iPadOS, tvOS. Callbacks are used to show the view controller from SwiftUI.
public final class AuthenticationPresenterUniversal: UIKitAuthenticationPresenter {
    private var onPresent: ((UIViewController) -> Void)?

    public init() {}

    public func setPresentationHandler(_ handler: @escaping (UIViewController) -> Void) {
        onPresent = handler
    }

    public func presentAuthenticationUI(_ viewController: Any) {
        guard let vc = viewController as? UIViewController else { return }
        onPresent?(vc)
    }
}
#else
/// No-op presenter when UIKit is not available (e.g. macOS). Game Center auth UI is not presented.
public final class NoOpAuthenticationPresenter: AuthenticationPresenter {
    public init() {}

    public func presentAuthenticationUI(_ viewController: Any) {}
}
#endif
