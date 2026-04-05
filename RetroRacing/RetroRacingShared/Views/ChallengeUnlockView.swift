//
//  ChallengeUnlockView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

struct ChallengeUnlockView: View {
    let challengeIDs: [ChallengeIdentifier]
    let onDone: () -> Void

    @Environment(\.fontPreferenceStore) var fontPreferenceStore
    @Environment(\.colorScheme) var colorScheme
    #if !os(watchOS)
    @State var shareImageURL: URL?
    #endif

    static let sharedBundle = Bundle(for: GameScene.self)
    #if !os(watchOS)
    static let shareImageFileName = "retroracing-challenge-share.png"

    static var shareToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                challengeMainContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.background)
            .navigationTitle(GameLocalizedStrings.string("challenge_modal_title"))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if !os(watchOS)
            .toolbar {
                ToolbarItem(placement: Self.shareToolbarPlacement) {
                    shareToolbarItem
                }
            }
            #endif
        }
        #if !os(watchOS)
        .onAppear(perform: refreshShareImage)
        .onChange(of: colorScheme) { _, _ in
            refreshShareImage()
        }
        #endif
    }
}
