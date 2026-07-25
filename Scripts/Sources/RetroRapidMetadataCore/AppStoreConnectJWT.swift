//
//  AppStoreConnectJWT.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import CryptoKit
import Foundation

enum AppStoreConnectJWT {
    static func makeToken(
        credentials: AppStoreConnectCredentials,
        now: Date = Date()
    ) throws -> String {
        let headerData = try JSONSerialization.data(
            withJSONObject: [
                "alg": "ES256",
                "kid": credentials.keyID,
                "typ": "JWT",
            ]
        )
        let issuedAt = Int(now.timeIntervalSince1970)
        let payloadData = try JSONSerialization.data(
            withJSONObject: [
                "iss": credentials.issuerID,
                "iat": issuedAt,
                "exp": issuedAt + 1_199,
                "aud": "appstoreconnect-v1",
            ]
        )

        let header = base64URLEncode(headerData)
        let payload = base64URLEncode(payloadData)
        let message = Data("\(header).\(payload)".utf8)

        let pem = try String(contentsOf: credentials.privateKeyURL, encoding: .utf8)
        let privateKey = try P256.Signing.PrivateKey(pemRepresentation: pem)
        let signature = try privateKey.signature(for: message)
        let signedToken = "\(header).\(payload).\(base64URLEncode(signature.rawRepresentation))"
        return signedToken
    }

    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
