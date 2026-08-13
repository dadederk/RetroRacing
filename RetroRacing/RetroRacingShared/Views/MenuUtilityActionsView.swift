//
//  MenuUtilityActionsView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

import SwiftUI

struct MenuUtilityActionsView: View {
    let showsHelp: Bool
    let onHelp: () -> Void
    let onSettings: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if MenuLayoutPolicy.usesVerticalUtilityActions(for: dynamicTypeSize) {
            VStack(alignment: .trailing, spacing: 12) { utilityActions }
                .utilityActionStyle()
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { utilityActions }
                VStack(alignment: .trailing, spacing: 12) { utilityActions }
            }
            .utilityActionStyle()
        }
    }

    @ViewBuilder
    private var utilityActions: some View {
        if showsHelp {
            Button(action: onHelp) {
                utilityLabel(
                    title: GameLocalizedStrings.string("tutorial_help_button"),
                    systemImage: "questionmark.circle"
                )
            }
            .accessibilityIdentifier("menu_help")
        }

        Button(action: onSettings) {
            utilityLabel(
                title: GameLocalizedStrings.string("settings"),
                systemImage: "gearshape"
            )
        }
        .accessibilityIdentifier("menu_settings")
    }

    private func utilityLabel(title: String, systemImage: String) -> some View {
        Label {
            Text(title)
                .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: systemImage)
        }
        .appFont(.headline)
    }
}

private extension View {
    func utilityActionStyle() -> some View {
        buttonStyle(.bordered)
            .controlSize(.large)
    }
}
