//
//  MetadataKeywordRules.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum MetadataKeywordRules {
    public static func keywordTokens(in keywords: String) -> [String] {
        keywords.split(
            separator: ",",
            omittingEmptySubsequences: false
        ).map(String.init)
    }

    public static func visibleTokens(
        appName: String,
        subtitle: String
    ) -> Set<String> {
        Set(
            (appName + " " + subtitle)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .map { $0.folding(options: [.caseInsensitive], locale: nil) }
        )
    }

    public static func keywordRuleErrors(
        locale: String,
        appName: String,
        subtitle: String,
        keywords: String,
        allowedShortKeywords: Set<String> = []
    ) -> [String] {
        let tokens = keywordTokens(in: keywords)
        var errors: [String] = []

        if tokens.contains(where: \.isEmpty) {
            errors.append("\(locale) keywords contain an empty token")
        }
        if tokens.contains(where: {
            $0 != $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
            errors.append("\(locale) keywords contain whitespace around a token")
        }

        let normalized = tokens.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive], locale: nil)
        }
        let normalizedAllowedShortKeywords = Set(
            allowedShortKeywords.map {
                $0.folding(options: [.caseInsensitive], locale: nil)
            }
        )
        let shortTokens = zip(tokens, normalized).compactMap { token, normalizedToken in
            token.count <= 2 && !normalizedAllowedShortKeywords.contains(normalizedToken)
                ? token
                : nil
        }
        if !shortTokens.isEmpty {
            errors.append(
                "\(locale) keywords must be greater than two characters "
                    + "unless allowlisted: "
                    + shortTokens.joined(separator: ", ")
            )
        }

        let duplicates = Dictionary(grouping: normalized, by: { $0 })
            .filter { $0.value.count > 1 }
            .keys
            .sorted()
        if !duplicates.isEmpty {
            errors.append(
                "\(locale) keywords contain duplicates: "
                    + duplicates.joined(separator: ", ")
            )
        }

        let visibleDuplicates = visibleTokens(
            appName: appName,
            subtitle: subtitle
        ).intersection(normalized).sorted()
        if !visibleDuplicates.isEmpty {
            errors.append(
                "\(locale) keywords duplicate visible name/subtitle tokens: "
                    + visibleDuplicates.joined(separator: ", ")
            )
        }
        return errors
    }
}
