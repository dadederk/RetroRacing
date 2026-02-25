import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Conditional-default wrapper value for Big Cars accessibility preference.
public struct BigCarsSetting: Codable, Equatable, Sendable {
    public static let conditionalDefaultStorageKey = "bigCars_conditionalDefault"

    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

extension BigCarsSetting: ConditionalDefaultValue {
    static func systemDefaultValue(isAccessibilityTextSize: Bool) -> Bool {
        isAccessibilityTextSize
    }

    public static var systemDefault: BigCarsSetting {
        BigCarsSetting(
            isEnabled: systemDefaultValue(
                isAccessibilityTextSize: AccessibilityTextSizeStatus.isAccessibilityTextSize
            )
        )
    }
}

public enum BigCarsPreference {
    public static func currentSelection(from userDefaults: UserDefaults) -> Bool {
        let conditionalDefault = ConditionalDefault<BigCarsSetting>.load(
            from: userDefaults,
            key: BigCarsSetting.conditionalDefaultStorageKey
        )
        return conditionalDefault.effectiveValue.isEnabled
    }
}

private enum AccessibilityTextSizeStatus {
    static var isAccessibilityTextSize: Bool {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        #else
        false
        #endif
    }
}
