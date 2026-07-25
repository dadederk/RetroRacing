//
//  AppStoreConnectHTTPClient.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

enum AppStoreConnectHTTPClient {
    static let v1BaseURL = AppStoreConnectAPIEndpoints.v1BaseURL
    static let v2BaseURL = AppStoreConnectAPIEndpoints.v2BaseURL
    static let assetURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 300
        return URLSession(configuration: configuration)
    }()

    static func decodeJSONObject(_ data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MetadataToolError.appStoreConnectFailed("App Store Connect API returned invalid JSON.")
        }
        return json
    }

    static func resourceRows(from json: [String: Any]) -> [[String: Any]] {
        json["data"] as? [[String: Any]] ?? []
    }

    static func singleResource(from json: [String: Any]) -> [String: Any]? {
        json["data"] as? [String: Any]
    }

    static func resourceID(from json: [String: Any]) -> String? {
        singleResource(from: json)?["id"] as? String
    }

    static func stringAttribute(
        named name: String,
        in resource: [String: Any]
    ) -> String? {
        guard let attributes = resource["attributes"] as? [String: Any] else {
            return nil
        }
        return attributes[name] as? String
    }

    static func send(request: URLRequest, token: String) async throws -> Data {
        var authorizedRequest = request
        authorizedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MetadataToolError.appStoreConnectFailed("App Store Connect API returned a non-HTTP response.")
        }
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect API HTTP \(httpResponse.statusCode): \(body)"
            )
        }
        return data
    }

    static func get(
        url: URL,
        token: String
    ) async throws -> [String: Any] {
        let data = try await send(request: URLRequest(url: url), token: token)
        return try decodeJSONObject(data)
    }

    static func post(
        path: String,
        body: [String: Any],
        token: String,
        baseURL: URL = v1BaseURL
    ) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try await send(request: request, token: token)
        return try decodeJSONObject(data)
    }

    static func patch(
        path: String,
        body: [String: Any],
        token: String,
        baseURL: URL = v1BaseURL
    ) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = try await send(request: request, token: token)
        return try decodeJSONObject(data)
    }
}
