import SwiftUI
import RetroRacingShared

struct ContentView: View {
    @State private var showGame = false
    @State private var gameID = 0
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(.custom("PressStart2P-Regular", size: 14))
                Button {
                    gameID += 1
                    showGame = true
                } label: {
                    Text(GameLocalizedStrings.string("play"))
                        .font(.custom("PressStart2P-Regular", size: 12))
                }
                .buttonStyle(.glassProminent)
            }
            .navigationDestination(isPresented: $showGame) {
                WatchGameView()
                    .id(gameID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
