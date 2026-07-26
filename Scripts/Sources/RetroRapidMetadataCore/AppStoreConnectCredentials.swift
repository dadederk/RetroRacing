//
//  AppStoreConnectCredentials.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
#if os(macOS)
import Security
#endif

public struct AppStoreConnectCredentials: Sendable {
    public let keyID: String
    public let issuerID: String
    public let privateKeyURL: URL

    public init(keyID: String, issuerID: String, privateKeyURL: URL) {
        self.keyID = keyID
        self.issuerID = issuerID
        self.privateKeyURL = privateKeyURL
    }
}

public enum AppStoreConnectCredentialsLoader {
    static let keychainKeyIDService = "RetroRapid ASC Key ID"
    static let keychainIssuerIDService = "RetroRapid ASC Issuer ID"
    static let keychainPrivateKeyService = "RetroRapid ASC Private Key"

    private static let keyIDEnvironmentNames = [
        "ASC_KEY_ID",
        "APP_STORE_CONNECT_KEY_ID",
    ]
    private static let issuerIDEnvironmentNames = [
        "ASC_ISSUER_ID",
        "APP_STORE_CONNECT_ISSUER_ID",
    ]
    private static let privateKeyEnvironmentNames = [
        "ASC_PRIVATE_KEY",
        "APP_STORE_CONNECT_PRIVATE_KEY",
    ]

    public static func load(
        from environment: [String: String] = ProcessInfo.processInfo.environment,
        includeKeychain: Bool = true
    ) -> AppStoreConnectCredentials? {
        switch loadResult(from: environment, includeKeychain: includeKeychain) {
        case .success(let credentials):
            return credentials
        case .failure:
            return nil
        }
    }

    public static func missingCredentialsMessage(
        from environment: [String: String] = ProcessInfo.processInfo.environment,
        includeKeychain: Bool = true
    ) -> String {
        switch loadResult(from: environment, includeKeychain: includeKeychain) {
        case .success:
            return "App Store Connect API credentials are configured."
        case .failure(let reason):
            return reason.message
        }
    }

    private enum LoadFailure: Error, Sendable {
        case missingKeyID
        case missingIssuerID
        case missingPrivateKeyPath(keyID: String, searchedPaths: [String])

        var message: String {
            switch self {
            case .missingKeyID:
                return """
                App Store Connect API credentials not found: missing key ID.
                Set ASC_KEY_ID (or APP_STORE_CONNECT_KEY_ID), or store it in Keychain \
                under service "\(keychainKeyIDService)".
                """
            case .missingIssuerID:
                return """
                App Store Connect API credentials not found: missing issuer ID.
                Set ASC_ISSUER_ID (or APP_STORE_CONNECT_ISSUER_ID), or store it in Keychain \
                under service "\(keychainIssuerIDService)".
                """
            case .missingPrivateKeyPath(let keyID, let searchedPaths):
                let searched = searchedPaths.map { "  \($0)" }.joined(separator: "\n")
                return """
                App Store Connect API credentials not found: private key file missing.
                Set ASC_PRIVATE_KEY (or APP_STORE_CONNECT_PRIVATE_KEY) to your AuthKey .p8 path, store the path \
                in Keychain under service "\(keychainPrivateKeyService)", or place:
                  AuthKey_\(keyID).p8
                in one of:
                \(searched)
                """
            }
        }
    }

    private static func loadResult(
        from environment: [String: String],
        includeKeychain: Bool
    ) -> Result<AppStoreConnectCredentials, LoadFailure> {
        guard let keyID = resolvedValue(
            in: environment,
            environmentNames: keyIDEnvironmentNames,
            keychainService: includeKeychain ? keychainKeyIDService : nil
        ) else {
            return .failure(.missingKeyID)
        }
        guard let issuerID = resolvedValue(
            in: environment,
            environmentNames: issuerIDEnvironmentNames,
            keychainService: includeKeychain ? keychainIssuerIDService : nil
        ) else {
            return .failure(.missingIssuerID)
        }

        if let privateKeyPath = resolvedValue(
            in: environment,
            environmentNames: privateKeyEnvironmentNames,
            keychainService: includeKeychain ? keychainPrivateKeyService : nil
        ) {
            let expanded = NSString(string: privateKeyPath).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded, isDirectory: false)
            if FileManager.default.fileExists(atPath: url.path) {
                return .success(
                    AppStoreConnectCredentials(
                        keyID: keyID,
                        issuerID: issuerID,
                        privateKeyURL: url
                    )
                )
            }
        }

        let searchDirectories = defaultPrivateKeySearchDirectories()
        for directory in searchDirectories {
            let candidate = directory.appending(path: "AuthKey_\(keyID).p8")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return .success(
                    AppStoreConnectCredentials(
                        keyID: keyID,
                        issuerID: issuerID,
                        privateKeyURL: candidate
                    )
                )
            }
        }

        return .failure(
            .missingPrivateKeyPath(
                keyID: keyID,
                searchedPaths: searchDirectories.map { candidatePath(for: $0, keyID: keyID) }
            )
        )
    }

    private static func candidatePath(for directory: URL, keyID: String) -> String {
        directory.appending(path: "AuthKey_\(keyID).p8").path
    }

    private static func resolvedValue(
        in environment: [String: String],
        environmentNames: [String],
        keychainService: String?
    ) -> String? {
        if let environmentValue = firstValue(in: environment, names: environmentNames) {
            return environmentValue
        }
        guard let keychainService else { return nil }
        return keychainValue(service: keychainService)
    }

    private static func firstValue(
        in environment: [String: String],
        names: [String]
    ) -> String? {
        for name in names {
            if let value = environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
               value.isEmpty == false {
                return value
            }
        }
        return nil
    }

    private static func keychainValue(service: String) -> String? {
        #if os(macOS)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              value.isEmpty == false else {
            return nil
        }
        return value
        #else
        return nil
        #endif
    }

    private static func defaultPrivateKeySearchDirectories() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appending(path: ".appstoreconnect/private_keys"),
            home.appending(path: "private_keys"),
        ]
    }
}
