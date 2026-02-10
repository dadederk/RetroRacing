//
//  SafariView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import SwiftUI

#if os(iOS)
import SafariServices

/// In-app browser wrapper used for opening external links on iOS.
public struct SafariView: UIViewControllerRepresentable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .done
        return controller
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No-op
    }
}
#endif

