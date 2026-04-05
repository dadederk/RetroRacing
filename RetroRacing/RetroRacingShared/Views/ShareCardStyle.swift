//
//  ShareCardStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

struct ShareCardCanvas<Content: View>: View {
    let colorScheme: ColorScheme
    let content: Content

    init(
        colorScheme: ColorScheme,
        @ViewBuilder content: () -> Content
    ) {
        self.colorScheme = colorScheme
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            content
        }
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                .init(red: 0.09, green: 0.11, blue: 0.16),
                .init(red: 0.04, green: 0.05, blue: 0.08)
            ]
        }

        return [
            .init(red: 0.95, green: 0.97, blue: 1.0),
            .init(red: 0.90, green: 0.94, blue: 0.99)
        ]
    }
}

struct ShareCardGameTitle: View {
    let font: Font

    var body: some View {
        Text(GameLocalizedStrings.string("gameName"))
            .font(font)
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .accessibilityHidden(true)
    }
}
