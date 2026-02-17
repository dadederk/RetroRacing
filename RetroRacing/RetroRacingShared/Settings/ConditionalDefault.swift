//
//  ConditionalDefault.swift
//  RetroRacing
//
//  Infrastructure for settings with conditional defaults based on system/accessibility state.
//

import Foundation

/// A setting value that has a system-derived default (based on accessibility or system state)
/// and an optional user override.
///
/// **Pattern:**
/// - When no override is stored, the effective value is computed from current system state
///   (e.g., VoiceOver running, Dynamic Type size, Reduce Motion)
/// - When the user explicitly chooses a value, that override is persisted and used
/// - The UI can show "System Default" vs "Always use X" options
///
/// **Example use cases:**
/// - Difficulty: default to .cruise when VoiceOver is on, user can override to any difficulty
/// - Lane audio cues: default to on when VoiceOver is on, user can override
/// - Top-down view: default to on when large Dynamic Type is active, user can override
public protocol ConditionalDefaultValue: Codable, Equatable {
    /// The system-derived default value for the current accessibility/system state
    static var systemDefault: Self { get }
}

/// Storage for a conditional-default setting
public struct ConditionalDefault<Value: ConditionalDefaultValue> {
    private enum Storage: Codable, Equatable {
        case useSystemDefault
        case userOverride(Value)
    }
    
    private var storage: Storage
    
    /// The effective value: system default if no override, otherwise the user's choice
    public var effectiveValue: Value {
        switch storage {
        case .useSystemDefault:
            return Value.systemDefault
        case .userOverride(let value):
            return value
        }
    }
    
    /// Whether the user has set an explicit override (true) or is using the system default (false)
    public var isUsingSystemDefault: Bool {
        if case .useSystemDefault = storage {
            return true
        }
        return false
    }
    
    /// The user's override value, if any
    public var userOverride: Value? {
        if case .userOverride(let value) = storage {
            return value
        }
        return nil
    }
    
    public init() {
        self.storage = .useSystemDefault
    }
    
    public init(userOverride: Value) {
        self.storage = .userOverride(userOverride)
    }
    
    /// Reset to system default (clear any user override)
    public mutating func resetToSystemDefault() {
        storage = .useSystemDefault
    }
    
    /// Set an explicit user override
    public mutating func setUserOverride(_ value: Value) {
        storage = .userOverride(value)
    }
}

// MARK: - Codable conformance
extension ConditionalDefault: Codable {
    private enum CodingKeys: String, CodingKey {
        case storage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        storage = try container.decode(Storage.self, forKey: .storage)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(storage, forKey: .storage)
    }
}

// MARK: - Equatable conformance
extension ConditionalDefault: Equatable {
    public static func == (lhs: ConditionalDefault<Value>, rhs: ConditionalDefault<Value>) -> Bool {
        lhs.storage == rhs.storage
    }
}

// MARK: - UserDefaults integration
extension ConditionalDefault {
    /// Storage key for this conditional default setting
    public static func storageKey(for baseKey: String) -> String {
        "\(baseKey)_conditionalDefault"
    }
    
    /// Load from UserDefaults (returns system default if not found or decoding fails)
    public static func load(from userDefaults: UserDefaults, key: String) -> ConditionalDefault<Value> {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(ConditionalDefault<Value>.self, from: data) else {
            return ConditionalDefault()
        }
        return decoded
    }
    
    /// Save to UserDefaults
    public func save(to userDefaults: UserDefaults, key: String) {
        if let data = try? JSONEncoder().encode(self) {
            userDefaults.set(data, forKey: key)
        }
    }
}
