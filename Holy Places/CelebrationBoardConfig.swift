//
//  CelebrationBoardConfig.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation

enum CelebrationBoardConfig {
    static let displayName = "Celebration Board"
    static let appDisplayName = "Holy Places of the Lord"
    static let apiURL = URL(string: "https://dacworld.net/holyplaces/api/celebrationboard.php")!
    static let pageURL = URL(string: "https://dacworld.net/holyplaces/celebrationboard.html")!

    /// Achievements eligible to post to the Celebration Board.
    static let eligibleIconNames: Set<String> = [
        "ach50T", "ach60T", "ach75T", "ach100T", "ach125T", "ach150T", "ach175T", "ach200T",
        "ach55H", "ach75H", "ach100H", "ach125H", "ach150H",
        "ach100B", "ach200B", "ach400B", "ach800B",
        "ach100I", "ach200I", "ach400I", "ach800I",
        "ach300E", "ach400E", "ach550E", "ach700E",
        "ach200S", "ach400S", "ach800S", "ach1600S",
        "ach200W", "ach400W", "ach800W", "ach1600W"
    ]

    private static let namesKey = "celebrationBoardNames"
    private static let locationsKey = "celebrationBoardLocations"

    static func isEligible(iconName: String) -> Bool {
        eligibleIconNames.contains(iconName)
    }

    static func savedName(for profileId: String) -> String? {
        let map = UserDefaults.standard.dictionary(forKey: namesKey) as? [String: String]
        let value = map?[profileId]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value?.isEmpty == false) ? value : nil
    }

    static func savedLocation(for profileId: String) -> String? {
        let map = UserDefaults.standard.dictionary(forKey: locationsKey) as? [String: String]
        let value = map?[profileId]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value?.isEmpty == false) ? value : nil
    }

    static func saveIdentity(name: String, location: String, for profileId: String) {
        var names = (UserDefaults.standard.dictionary(forKey: namesKey) as? [String: String]) ?? [:]
        var locations = (UserDefaults.standard.dictionary(forKey: locationsKey) as? [String: String]) ?? [:]
        names[profileId] = name.trimmingCharacters(in: .whitespacesAndNewlines)
        locations[profileId] = location.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(names, forKey: namesKey)
        UserDefaults.standard.set(locations, forKey: locationsKey)
    }
}
