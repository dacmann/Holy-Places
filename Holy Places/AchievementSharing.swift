//
//  AchievementSharing.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import UIKit
import SwiftUI

extension UIViewController {

    /// Snapshot completed achievement icon names before calling `getVisits()`.
    func snapshotCompletedAchievementIcons() -> Set<String> {
        Set(completed.map { $0.iconName })
    }

    /// Returns achievements unlocked since the snapshot (matched from current `completed`).
    func newlyUnlockedAchievements(since previousIcons: Set<String>) -> [Achievement] {
        completed.filter { $0.achieved != nil && !previousIcons.contains($0.iconName) }
    }

    func presentAchievementUnlocked(achievements: [Achievement], then continuation: @escaping () -> Void) {
        guard !achievements.isEmpty else {
            continuation()
            return
        }
        let vc = AchievementUnlockedVC(achievements: achievements, onFinished: continuation)
        present(vc, animated: true)
    }

    func handleAchievementShareAction(for achievement: Achievement, sourceView: UIView?) {
        if achievement.isCelebrationBoardEligible {
            let sheet = UIAlertController(title: achievement.name, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: "Share Achievement", style: .default) { [weak self] _ in
                self?.shareAchievementImage(achievement, sourceView: sourceView)
            })
            sheet.addAction(UIAlertAction(title: "Post to \(CelebrationBoardConfig.displayName)", style: .default) { [weak self] _ in
                self?.beginCelebrationBoardPost(for: achievement)
            })
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            if let pop = sheet.popoverPresentationController {
                pop.sourceView = sourceView
                pop.sourceRect = sourceView?.bounds ?? .zero
            }
            present(sheet, animated: true)
        } else {
            shareAchievementImage(achievement, sourceView: sourceView)
        }
    }

    func shareAchievementImage(_ achievement: Achievement, sourceView: UIView?) {
        let activity = UIActivityViewController(
            activityItems: AchievementShareImageRenderer.shareItems(for: achievement),
            applicationActivities: nil
        )
        if let pop = activity.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView?.bounds ?? CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        present(activity, animated: true)
    }

    func beginCelebrationBoardPost(for achievement: Achievement) {
        guard let profileId = ProfileManager.shared.effectiveProfileId() else {
            let alert = UIAlertController(
                title: CelebrationBoardConfig.displayName,
                message: "No active profile is available for posting.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(
            title: CelebrationBoardConfig.displayName,
            message: "Enter the name and location to show publicly with this achievement.",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Full name"
            field.textContentType = .name
            field.text = CelebrationBoardConfig.savedName(for: profileId)
            field.autocapitalizationType = .words
        }
        alert.addTextField { field in
            field.placeholder = "Where you live"
            field.textContentType = .addressCity
            field.text = CelebrationBoardConfig.savedLocation(for: profileId)
            field.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Post", style: .default) { [weak self] _ in
            let name = alert.textFields?[0].text ?? ""
            let location = alert.textFields?[1].text ?? ""
            self?.submitCelebrationBoardPost(achievement: achievement, name: name, location: location, profileId: profileId)
        })
        present(alert, animated: true)
    }

    private func submitCelebrationBoardPost(achievement: Achievement, name: String, location: String, profileId: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedLocation.isEmpty else {
            let alert = UIAlertController(
                title: CelebrationBoardConfig.displayName,
                message: "Please enter your name and where you live.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        guard let submission = CelebrationBoardClient.buildSubmission(
            achievement: achievement,
            userName: trimmedName,
            location: trimmedLocation
        ) else {
            let alert = UIAlertController(
                title: CelebrationBoardConfig.displayName,
                message: "Unable to prepare submission.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let loading = UIAlertController(title: "Posting…", message: nil, preferredStyle: .alert)
        present(loading, animated: true)

        CelebrationBoardClient.post(submission) { [weak self] result in
            loading.dismiss(animated: true) {
                switch result {
                case .success:
                    CelebrationBoardConfig.saveIdentity(name: trimmedName, location: trimmedLocation, for: profileId)
                    let alert = UIAlertController(
                        title: CelebrationBoardConfig.displayName,
                        message: "Your achievement was posted successfully.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                case .failure(let message):
                    let alert = UIAlertController(
                        title: "Post Failed",
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
