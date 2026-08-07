//
//  VisionSpatialPlacementPanel.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RetroRacingShared
import SwiftUI

struct VisionSpatialPlacementPanel: View {
    let state: VisionSpatialState
    let cancel: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @AccessibilityFocusState private var isStatusFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Label(statusTitle, systemImage: statusSymbol)
                .font(.title2.bold())
                .accessibilityFocused($isStatusFocused)

            Text(statusMessage)
                .font(.body)
                .multilineTextAlignment(.center)

            if showsTroubleshooting {
                Text(GameLocalizedStrings.string("vision_surface_search_help"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(
                GameLocalizedStrings.string("vision_return_to_2d"),
                systemImage: "rectangle",
                action: cancel
            )
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.black)
            .controlSize(.large)
            .accessibilityInputLabels([
                GameLocalizedStrings.string("vision_return_to_2d")
            ])
        }
        .frame(maxWidth: 560)
        .padding(24)
        .background(
            Color.black.opacity(reduceTransparency ? 1 : 0.86),
            in: .rect(cornerRadius: 28)
        )
        .foregroundStyle(.primary)
        .tint(actionTint)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(GameLocalizedStrings.string("vision_tabletop_title"))
        .accessibilityValue(statusTitle)
        .onAppear { isStatusFocused = true }
        .onChange(of: state) { isStatusFocused = true }
    }

    private var statusTitle: String {
        switch state {
        case .preflighting, .opening, .searchingSurface:
            GameLocalizedStrings.string("vision_surface_searching")
        case .recoveringSurface:
            GameLocalizedStrings.string("vision_surface_recovering")
        case .inactive, .awaitingConfirmation, .active, .returning, .failure:
            GameLocalizedStrings.string("vision_state_paused")
        }
    }

    private var statusMessage: String {
        switch state {
        case .recoveringSurface:
            GameLocalizedStrings.string("vision_surface_recovery_instructions")
        case .preflighting, .opening, .searchingSurface:
            GameLocalizedStrings.string("vision_surface_search_instructions")
        case .inactive, .awaitingConfirmation, .active, .returning, .failure:
            GameLocalizedStrings.string("vision_state_paused")
        }
    }

    private var statusSymbol: String {
        switch state {
        case .recoveringSurface:
            "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .preflighting, .opening, .searchingSurface:
            "viewfinder"
        case .inactive, .awaitingConfirmation, .active, .returning, .failure:
            "pause.fill"
        }
    }

    private var showsTroubleshooting: Bool {
        switch state {
        case .searchingSurface(let show), .recoveringSurface(let show):
            show
        case .inactive, .preflighting, .opening, .awaitingConfirmation,
             .active, .returning, .failure:
            false
        }
    }

    private var actionTint: Color {
        colorSchemeContrast == .increased ? .yellow : .cyan
    }
}
