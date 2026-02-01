import SwiftUI
import RetroRacingShared

struct ContentView: View {
    @State private var showGame = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(String(localized: "gameName"))
                    .font(.custom("PressStart2P-Regular", size: 14))
                Button {
                    showGame = true
                } label: {
                    Text(String(localized: "play"))
                        .font(.custom("PressStart2P-Regular", size: 12))
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationDestination(isPresented: $showGame) {
                WatchGameView()
            }
        }
    }
}

#Preview {
    ContentView()
}
