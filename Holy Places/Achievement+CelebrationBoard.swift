//
//  Achievement+CelebrationBoard.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Achievement {
    var isCelebrationBoardEligible: Bool {
        CelebrationBoardConfig.isEligible(iconName: iconName)
    }

    /// Achievement type letter: T, H, B, I, E, S, W (nil for Temple Consistent / unknown).
    var achievementType: String? {
        guard iconName.hasPrefix("ach") else { return nil }
        let body = String(iconName.dropFirst(3))
        guard let last = body.last, last.isLetter else { return nil }
        // Temple Consistent icons look like "12MT2024"
        if body.contains("MT") { return nil }
        return String(last)
    }

    var threshold: Int? {
        guard iconName.hasPrefix("ach") else { return nil }
        var body = String(iconName.dropFirst(3))
        if body.contains("MT") { return nil }
        if let last = body.last, last.isLetter {
            body.removeLast()
        }
        return Int(body)
    }
}

enum AchievementPlaceListBuilder {

    /// Distinct places that contributed to the achievement, up through unlock.
    static func places(for achievement: Achievement) -> [String] {
        guard let type = achievement.achievementType,
              let threshold = achievement.threshold,
              let unlockDate = achievement.achieved else {
            return []
        }

        let context = ad.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        let sort = NSSortDescriptor(key: "dateVisited", ascending: true)
        fetchRequest.sortDescriptors = [sort]

        var predicates: [NSPredicate] = [
            NSPredicate(format: "dateVisited <= %@", unlockDate as NSDate)
        ]
        if let profilePredicate = ProfileManager.shared.visitProfilePredicate() {
            predicates.append(profilePredicate)
        }

        switch type {
        case "T":
            predicates.append(NSPredicate(format: "type == %@ OR type == %@", "T", "C"))
        case "H":
            predicates.append(NSPredicate(format: "type == %@", "H"))
        case "B", "I", "E", "S", "W":
            predicates.append(NSPredicate(format: "type == %@ OR type == %@", "T", "C"))
        default:
            return []
        }

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        guard let visits = try? context.fetch(fetchRequest) else { return [] }

        var distinct: [String] = []
        for visit in visits {
            let placeName = ad.canonicalName(for: visit.holyPlace ?? "")
            guard !placeName.isEmpty else { continue }

            switch type {
            case "T", "H":
                if !distinct.contains(placeName) {
                    distinct.append(placeName)
                    if distinct.count >= threshold { return distinct }
                }
            case "B":
                if visit.baptisms > 0 && !distinct.contains(placeName) {
                    distinct.append(placeName)
                }
            case "I":
                if visit.initiatories > 0 && !distinct.contains(placeName) {
                    distinct.append(placeName)
                }
            case "E":
                if visit.endowments > 0 && !distinct.contains(placeName) {
                    distinct.append(placeName)
                }
            case "S":
                if visit.sealings > 0 && !distinct.contains(placeName) {
                    distinct.append(placeName)
                }
            case "W":
                if visit.shiftHrs > 0 && !distinct.contains(placeName) {
                    distinct.append(placeName)
                }
            default:
                break
            }
        }
        return distinct
    }
}
