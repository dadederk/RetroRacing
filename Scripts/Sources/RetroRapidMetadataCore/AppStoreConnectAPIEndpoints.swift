//
//  AppStoreConnectAPIEndpoints.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

enum AppStoreConnectAPIEndpoints {
    private static let v1BaseURLString = "https://api.appstoreconnect.apple.com/v1"
    private static let v2BaseURLString = "https://api.appstoreconnect.apple.com/v2"

    static var v1BaseURL: URL {
        guard let url = URL(string: v1BaseURLString) else {
            preconditionFailure("Invalid App Store Connect v1 base URL constant.")
        }
        return url
    }

    static var v2BaseURL: URL {
        guard let url = URL(string: v2BaseURLString) else {
            preconditionFailure("Invalid App Store Connect v2 base URL constant.")
        }
        return url
    }
}
