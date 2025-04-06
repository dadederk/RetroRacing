//
//  MenuView.swift
//  RetroRacing watchOS
//
//  Created by Dani on 06/04/2025.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationStack {
            Text(String(localized: "gameName"))
            HStack {
                NavigationLink(String(localized: "play"), destination: GameView())
            }
        }
    }
}

#Preview {
    MenuView()
}
