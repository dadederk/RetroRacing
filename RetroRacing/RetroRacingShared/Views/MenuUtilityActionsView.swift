//
//  MenuUtilityActionsView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

import SwiftUI

struct MenuUtilityActionsView: View {
    let showsHelp: Bool
    let font: Font
    let onHelp: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            if showsHelp {
                Button(action: onHelp) {
                    utilityLabel(
                        title: GameLocalizedStrings.string("tutorial_help_button"),
                        systemImage: "questionmark.circle"
                    )
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("menu_help")
            }

            Button(action: onSettings) {
                utilityLabel(
                    title: GameLocalizedStrings.string("settings"),
                    systemImage: "gearshape"
                )
            }
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("menu_settings")
        }
        .fixedSize(horizontal: true, vertical: false)
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func utilityLabel(title: String, systemImage: String) -> some View {
        Label {
            Text(title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(font)
    }
}
