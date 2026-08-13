//
//  CelebrationBoardClient.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation
import UIKit

enum CelebrationBoardClient {

    struct Submission {
        let posterId: String
        let userName: String
        let location: String
        let achievement: Achievement
        let places: [String]
    }

    enum PostResult {
        case success
        case failure(String)
    }

    static func buildSubmission(achievement: Achievement, userName: String, location: String) -> Submission? {
        guard let posterId = ProfileManager.shared.effectiveProfileId(), !posterId.isEmpty else {
            return nil
        }
        let places = AchievementPlaceListBuilder.places(for: achievement)
        return Submission(
            posterId: posterId,
            userName: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            achievement: achievement,
            places: places
        )
    }

    static func post(_ submission: Submission, completion: @escaping (PostResult) -> Void) {
        var request = URLRequest(url: CelebrationBoardConfig.apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let payload: [String: Any] = [
            "posterId": submission.posterId,
            "userName": submission.userName,
            "location": submission.location,
            "achievementId": submission.achievement.iconName,
            "achievementName": submission.achievement.name,
            "achievementDetails": submission.achievement.details,
            "achievementType": submission.achievement.achievementType ?? "",
            "threshold": submission.achievement.threshold ?? 0,
            "dateAchieved": dateFormatter.string(from: submission.achievement.achieved ?? Date()),
            "placeAchieved": submission.achievement.placeAchieved ?? "",
            "places": submission.places
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            DispatchQueue.main.async {
                completion(.failure("Could not prepare submission."))
            }
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error.localizedDescription))
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }

                if (200...299).contains(status), json?["ok"] as? Bool == true {
                    completion(.success)
                    return
                }

                if let serverMessage = json?["error"] as? String {
                    completion(.failure(serverMessage))
                    return
                }
                if let data, let body = String(data: data, encoding: .utf8), body.contains("<?php") {
                    completion(.failure("Celebration Board API is not running PHP on the server."))
                    return
                }
                completion(.failure("Server returned status \(status)."))
            }
        }.resume()
    }
}
