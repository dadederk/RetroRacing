//
//  ScriptCommandSuggestion.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

enum ScriptCommandSuggestion {
    static func nearestMatch(in candidates: [String], query: String) -> String? {
        guard query.isEmpty == false else {
            return nil
        }

        let loweredQuery = query.lowercased()
        if let prefixMatch = candidates.first(where: { $0.lowercased().hasPrefix(loweredQuery) }) {
            return prefixMatch
        }

        let ranked = candidates
            .map { candidate in
                (candidate, levenshteinDistance(query.lowercased(), candidate.lowercased()))
            }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0 < rhs.0
                }
                return lhs.1 < rhs.1
            }

        guard let best = ranked.first, best.1 <= max(3, query.count / 2) else {
            return nil
        }
        return best.0
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0 ... right.count)
        var current = Array(repeating: 0, count: right.count + 1)

        for row in 1 ... left.count {
            current[0] = row
            for column in 1 ... right.count {
                let substitutionCost = left[row - 1] == right[column - 1] ? 0 : 1
                current[column] = min(
                    previous[column] + 1,
                    current[column - 1] + 1,
                    previous[column - 1] + substitutionCost
                )
            }
            swap(&previous, &current)
        }
        return previous[right.count]
    }
}
