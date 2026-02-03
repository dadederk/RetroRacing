//
//  AuthenticationPresenter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Presents Game Center authentication UI from platform-specific layers.
public protocol AuthenticationPresenter: AnyObject {
    func presentAuthenticationUI(_ viewController: Any)
}
