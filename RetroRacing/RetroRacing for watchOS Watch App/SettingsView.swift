import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text(GameLocalizedStrings.string("settings_coming_soon"))
                .font(.custom("PressStart2P-Regular", size: 10))
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(GameLocalizedStrings.string("settings"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(GameLocalizedStrings.string("done")) {
                            dismiss()
                        }
                        .buttonStyle(.glass)
                    }
                }
        }
    }
}
