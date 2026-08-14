//
//  WhatsNew.swift
//  Holy Places
//
//  Created by Derek Cordon on 8/14/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation

enum WhatsNew {
    static let notesByVersion: [String: String] = [
        "5.8": """
            New:
            - Share completed achievements as an image, and post eligible milestones to the public Celebration Board
            - Change the place on an existing visit when editing
            - Tap the version numbers on the Info screen to re-read app and data update messages
            - Map Timeline now shows the temple era next to the count as you move through time
            
            Bug Fixes:
            - Map Filters hidden when opening the map from a place detail or Timeline so the back button stays visible
            - Visit swipe actions now work while search is active
            - Places and Visits list rows stay aligned with larger accessibility text sizes
            """,
        "5.7": """
            New:
            - Map Timeline now starts from the very beginning — Kirtland Temple (1836) and the original Nauvoo Temple (1846) appear before St. George, the first modern active temple
            - Temple pins show the name that was in use at the time as you move through the timeline
            
            Bug Fixes:
            - Back button missing when opening the map from a place detail
            - Home tab background image briefly flashed the default photo on launch when a custom image was set
            - Summary tab crash when top places included a renamed temple
            """,
        "5.6": """
            New:
            - Map Timeline — tap Timeline on now full-screen map to watch temples spread across the world year by year, or tap Play for an animated journey from 1877 to today
            - Historical names and images for renamed places — older visits keep the name and photo from when you were there
            - Redesigned Share on the Home tab — App Store/Google Play links, QR codes, and a printable promo PDF
            
            Improvements:
            - Info screen rebuilt in SwiftUI; Info, Settings, Map filters, and Achievements now open as sheets on iPad
            """,
        "5.5": """
            What's new:
            - Copy visits to another profile using the new select mode on the Visits tab — search for visits, select all results, and copy them in one tap
            - Visit import now treats matching place and date as duplicates, even when comments differ
            
            Version 5.4 recap:
            - Record a visit for multiple profiles at once; notes add a \"Visit Recorded for:\" line when the visit isn't only for your active profile
            
            Version 5.3 recap:
            - Profiles: Track visits separately for family members — enable in Settings and switch profiles from the Home screen
            - Watch app updated with new images and improved background launch reliability
            - Large widget now navigates directly to the featured visit
            """,
        "5.4": """
            What's new:
            - Record a visit for multiple profiles at once; notes add a \"Visit Recorded for:\" line when the visit isn't only for your active profile
            - Couple of bug fixes and improvements
            
            Version 5.3 recap:
            - Profiles for family members, watch and widget updates, map marker tweaks, large-widget visit shortcut, and fixes for saving edits and Home tab lag
            """,
        "5.3": """
            New:
            - Profiles: Track visits separately for family members — enable in Settings and switch profiles from the Home screen
            
            Improvements:
            - Watch app updated with new images and improved background launch reliability
            - Map marker sizes refined at various zoom levels
            - Medium and small widget layouts adjusted for better readability
            - Large widget now navigates directly to the featured visit
            
            Bug Fixes:
            - Fixed an issue saving visit edits
            - Fixed lag when selecting the Home tab
            """,
        "5.2": """
            Enjoy a more connected experience with widgets and improved reliability throughout the app.

            New Widgets:
            - Large widget: Daily temple visit photos with place name and visit date
            - Medium widget: Latest achievement and current year goal progress
            - Small widget: Daily inspirational quote
            
            Improvements:
            - Fixed temple visit reminder notifications
            - Updated filter icon for better clarity
            - Visit detail view now shows the temple's place image when no visit photo is attached
            - A number of bug fixes
            """,
        "5.1": """
            Bug Fixes:
            - Fixed scope control buttons (All/Visited/Not Visited) touch area issues on iOS 26 liquid glass UI
            - Fixed keyboard covering entry fields on Record Visit screen - content now auto-scrolls to keep fields visible
            
            Enhancements:
            - Entry fields now auto-select their values when tapped for easier editing (Record Visit and Settings screens)
            """,
        "5.0": """
            - Visual updates: 
                - Support for new Liquid Glass UI
                - Map pins resize smoothly as you zoom
                - Visited/Not Visited scope buttons surfaced on Places tab
                - New button icons in Visit tab header
            - Cleaner navigation: 
                - Tab bar hidden on child views
                - Inactive tab names are hidden
                - Place details from map view now independent of Places tab
                - Visit filters moved to a quick-access header button
            - Improved search with support for multiple terms.
            - Visits tab has an enhanced sort menu and sort-selected subtitle.
            - Visit photos can now be included in an export/import.
            - Customize in Settings the default message when adding a visit.
            - Stability improvements for saving visits and other bugs.
            """,
        "4.8": """
            Recently added features:
            
            * A new companion Apple Watch app displays a celestial-themed timer and gently taps your wrist at set intervals — ideal for staying attentive in a temple session.
            
            * Tapping on a Place address will now display navigation options with Apple Maps, Google Maps and Waze.
            
            * Updated the Achievements with all new, hand-drawn icons that look great in dark mode and added new Endowment and Historic Sites achievements.
            
            * New 'Announced Date' sort option on the Places tab to easily see which temples were announced at each conference.
            """
    ]

    static func notes(for version: String) -> String? {
        notesByVersion[version]
    }
}

enum DataUpdateNotes {
    private static let dateKey = "lastChangesDate"
    private static let msg1Key = "lastChangesMsg1"
    private static let msg2Key = "lastChangesMsg2"
    private static let msg3Key = "lastChangesMsg3"

    static func saveCurrent() {
        guard !changesDate.isEmpty else { return }
        let defaults = UserDefaults.standard
        defaults.set(changesDate, forKey: dateKey)
        defaults.set(changesMsg1, forKey: msg1Key)
        defaults.set(changesMsg2, forKey: msg2Key)
        defaults.set(changesMsg3, forKey: msg3Key)
    }

    static var date: String {
        UserDefaults.standard.string(forKey: dateKey) ?? ""
    }

    static var combinedMessage: String {
        let msg1 = UserDefaults.standard.string(forKey: msg1Key) ?? ""
        let msg2 = UserDefaults.standard.string(forKey: msg2Key) ?? ""
        let msg3 = UserDefaults.standard.string(forKey: msg3Key) ?? ""
        var message = msg1
        if !msg2.isEmpty {
            message.append("\n\n")
            message.append(msg2)
        }
        if !msg3.isEmpty {
            message.append("\n\n")
            message.append(msg3)
        }
        return message
    }
}
