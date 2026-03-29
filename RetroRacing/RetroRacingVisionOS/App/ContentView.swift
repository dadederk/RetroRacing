//
//  ContentView.swift
//  RetroRacing for visionOS
//
//  Created by Dani Devesa on 01/02/2026.
//

import SwiftUI
import RealityKit
import RetroRacingShared

/// Placeholder visionOS landing view until 3D gameplay is available.
struct ContentView: View {
    @State private var isSettingsPresented = false
    @State private var preferencesStore: SettingsPreferencesStore

    init() {
        _preferencesStore = State(initialValue: SettingsPreferencesStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: false,
            isVoiceOverRunningProvider: { VoiceOverStatus.isVoiceOverRunning }
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Model3D(named: "Scene", bundle: .main)
                    .padding(.bottom, 50)

                Text(GameLocalizedStrings.string("gameName"))
                    .font(.title)
                Text(GameLocalizedStrings.string("coming_soon"))
                    .font(.subheadline)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label(GameLocalizedStrings.string("settings"), systemImage: "gearshape")
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                }
            }
        }
        .onAppear {
            preferencesStore.loadIfNeeded()
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                Form {
                    Section {
                        Toggle(isOn: preferencesStore.directTouchSelection) {
                            Text(GameLocalizedStrings.string("settings_direct_touch"))
                        }
                    } header: {
                        Text(GameLocalizedStrings.string("settings_accessibility"))
                    }
                }
                .navigationTitle(GameLocalizedStrings.string("settings"))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(GameLocalizedStrings.string("done")) {
                            isSettingsPresented = false
                        }
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
