//
//  ContentView.swift
//  RetroRacing for visionOS
//
//  Created by Dani Devesa on 01/02/2026.
//

import SwiftUI
import RealityKit
import RealityKitContent
import RetroRacingShared

/// Placeholder visionOS landing view until 3D gameplay is available.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text(GameLocalizedStrings.string("gameName"))
                .font(.title)
            Text(GameLocalizedStrings.string("coming_soon"))
                .font(.subheadline)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
