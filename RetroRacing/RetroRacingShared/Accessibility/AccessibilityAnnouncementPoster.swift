import Foundation
import Accessibility

public enum AccessibilityAnnouncementPriority: Sendable {
    case low
    case `default`
    case high
}

@MainActor
public protocol AccessibilityAnnouncementPosting {
    func postAnnouncement(_ announcement: String, priority: AccessibilityAnnouncementPriority)
}

/// Centralized path for app-generated accessibility announcements.
@MainActor
public struct AccessibilityAnnouncementPoster: AccessibilityAnnouncementPosting {
    public init() {}

    public func postAnnouncement(_ announcement: String, priority: AccessibilityAnnouncementPriority) {
        var attributedAnnouncement = AttributedString(announcement)
        attributedAnnouncement[
            AttributeScopes.AccessibilityAttributes.AnnouncementPriorityAttribute.self
        ] = announcementPriority(from: priority)
        AccessibilityNotification.Announcement(attributedAnnouncement).post()
    }

    private func announcementPriority(
        from priority: AccessibilityAnnouncementPriority
    ) -> AttributeScopes.AccessibilityAttributes.AnnouncementPriorityAttribute.AnnouncementPriority {
        switch priority {
        case .low:
            return .low
        case .default:
            return .default
        case .high:
            return .high
        }
    }
}
