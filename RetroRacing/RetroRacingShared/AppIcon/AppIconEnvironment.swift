//
//  AppIconEnvironment.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

public extension EnvironmentValues {
    /// Presentation-only signal used to keep Release and unsupported-platform paywalls unchanged.
    @Entry var alternateAppIconsBenefitEnabled = false
}
