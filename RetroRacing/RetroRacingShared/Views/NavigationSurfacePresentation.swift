//
//  NavigationSurfacePresentation.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

/// Selects whether a shared destination owns modal navigation chrome or participates in its
/// presenter's navigation stack.
public enum NavigationSurfacePresentation: Equatable {
    case modal
    case navigationDestination
}
