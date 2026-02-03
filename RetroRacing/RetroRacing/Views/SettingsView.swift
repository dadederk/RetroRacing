import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text(GameLocalizedStrings.string("settings_coming_soon"))
                .font(.custom("PressStart2P-Regular", size: 14))
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(GameLocalizedStrings.string("settings"))
                .modifier(SettingsNavigationTitleStyle())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(GameLocalizedStrings.string("done")) {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#if !os(macOS)
private struct SettingsNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(.inline)
    }
}
#else
private struct SettingsNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
#endif

#Preview {
    SettingsView()
}
