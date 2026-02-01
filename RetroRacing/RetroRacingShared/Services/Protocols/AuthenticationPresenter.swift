import Foundation

/// Presents Game Center authentication UI. Implemented by the platform (e.g. SwiftUI view that presents the view controller).
public protocol AuthenticationPresenter: AnyObject {
    func presentAuthenticationUI(_ viewController: Any)
}
