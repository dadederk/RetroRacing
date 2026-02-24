import Foundation

public enum TutorialApplyStateResolver {
    public static func isConfigured<Value: Equatable>(
        selectedValue: Value,
        configuredValue: Value
    ) -> Bool {
        selectedValue == configuredValue
    }

    public static func applyButtonLabel(
        selectedName: String,
        isConfigured: Bool
    ) -> String {
        if isConfigured {
            return GameLocalizedStrings.format("tutorial_configured %@", selectedName)
        }
        return GameLocalizedStrings.format("tutorial_set %@", selectedName)
    }
}
