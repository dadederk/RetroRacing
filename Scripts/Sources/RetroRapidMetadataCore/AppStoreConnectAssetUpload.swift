//
//  AppStoreConnectAssetUpload.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import CryptoKit
import Foundation

struct AppStoreConnectUploadOperation: Sendable {
    let method: String
    let url: URL
    let requestHeaders: [(name: String, value: String)]
}

enum AppStoreConnectAssetUpload {
    static func md5Checksum(for data: Data) -> String {
        Insecure.MD5.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func uploadOperations(from resource: [String: Any]) -> [AppStoreConnectUploadOperation] {
        guard let attributes = resource["attributes"] as? [String: Any],
              let operations = attributes["uploadOperations"] as? [[String: Any]] else {
            return []
        }

        return operations.compactMap { operation in
            guard let method = operation["method"] as? String,
                  let urlString = operation["url"] as? String,
                  let url = URL(string: urlString) else {
                return nil
            }
            let headers = (operation["requestHeaders"] as? [[String: Any]] ?? [])
                .compactMap { header -> (String, String)? in
                    guard let name = header["name"] as? String,
                          let value = header["value"] as? String else {
                        return nil
                    }
                    return (name, value)
                }
            return AppStoreConnectUploadOperation(
                method: method,
                url: url,
                requestHeaders: headers
            )
        }
    }

    static func upload(data: Data, operation: AppStoreConnectUploadOperation) async throws {
        var request = URLRequest(url: operation.url)
        request.httpMethod = operation.method
        for header in operation.requestHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        request.httpBody = data

        let (_, response) = try await AppStoreConnectHTTPClient.assetURLSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect asset upload failed with HTTP \(status)."
            )
        }
    }

    static func commitUploadedGameCenterImage(
        type: String,
        id: String,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": type,
                "id": id,
                "attributes": [
                    "uploaded": true,
                ],
            ],
        ]
        _ = try await AppStoreConnectHTTPClient.patch(
            path: "\(type)/\(id)",
            body: body,
            token: token
        )
    }

    static func commitUploadedAsset(
        type: String,
        id: String,
        checksum: String,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": type,
                "id": id,
                "attributes": [
                    "uploaded": true,
                    "sourceFileChecksum": checksum,
                ],
            ],
        ]
        _ = try await AppStoreConnectHTTPClient.patch(
            path: "\(type)/\(id)",
            body: body,
            token: token
        )
    }

    static func resolvedTemplateURL(
        templateURL: String,
        width: Int,
        height: Int,
        fileExtension: String
    ) -> URL? {
        let resolved = templateURL
            .replacingOccurrences(of: "{w}", with: String(width))
            .replacingOccurrences(of: "{h}", with: String(height))
            .replacingOccurrences(of: "{f}", with: fileExtension)
        return URL(string: resolved)
    }

    static func fileExtension(from fileName: String) -> String {
        let ext = URL(fileURLWithPath: fileName).pathExtension
        return ext.isEmpty ? "png" : ext
    }

    static func downloadAsset(from url: URL) async throws -> Data {
        let (data, response) = try await AppStoreConnectHTTPClient.assetURLSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw MetadataToolError.appStoreConnectFailed(
                "Failed to download source Game Center image (HTTP \(status))."
            )
        }
        return data
    }

    static func sourceImageDownload(
        fromImageResource resource: [String: Any]
    ) -> (fileName: String, downloadURL: URL)? {
        guard let attributes = resource["attributes"] as? [String: Any],
              let fileName = attributes["fileName"] as? String else {
            return nil
        }

        if assetDeliveryStateIsReady(attributes["assetDeliveryState"]) == false {
            return nil
        }

        let imageAsset = attributes["imageAsset"] as? [String: Any]
        let templateURL = stringValue(from: imageAsset?["templateUrl"])
            ?? stringValue(from: imageAsset?["templateURL"])
        let width = intValue(from: imageAsset?["width"]) ?? 1024
        let height = intValue(from: imageAsset?["height"]) ?? 1024
        let fileExtension = fileExtension(from: fileName)

        guard let templateURL,
              let downloadURL = resolvedTemplateURL(
                templateURL: templateURL,
                width: width,
                height: height,
                fileExtension: fileExtension
              ) else {
            return nil
        }

        return (fileName: fileName, downloadURL: downloadURL)
    }

    private static func assetDeliveryStateIsReady(_ value: Any?) -> Bool {
        guard let deliveryState = value as? [String: Any] else {
            return true
        }
        guard let state = deliveryState["state"] as? String else {
            return true
        }
        return state == "COMPLETE"
    }

    private static func stringValue(from value: Any?) -> String? {
        value as? String
    }

    private static func intValue(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
