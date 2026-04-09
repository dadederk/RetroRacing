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
    #if !os(watchOS) && !os(tvOS)
    // Internal (not private) so ChallengeUnlockView+Sharing.swift can read and write it across files.
    @State var shareImageURL: URL?
    #endif

    static let sharedBundle = Bundle(for: GameScene.self)
    #if !os(watchOS) && !os(tvOS)
    static let shareImageFileName = "retroracing-challenge-share.png"

    static var shareToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
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
            #if os(iOS) || os(visionOS)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActionBar
            }
            .ignoresSafeArea(edges: .bottom)
            #endif
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.background)
            .navigationTitle(GameLocalizedStrings.string("challenge_modal_title"))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if !os(watchOS) && !os(tvOS)
            .toolbar {
                ToolbarItem(placement: Self.shareToolbarPlacement) {
                    shareToolbarItem
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
        #if !os(watchOS) && !os(tvOS)
        .onAppear(perform: refreshShareImage)
        .onChange(of: colorScheme) { _, _ in
            refreshShareImage()
        }
        #endif
    }
}
