//
//  SiriIntents.swift
//  Holy Places
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import AppIntents
import CoreData
import Foundation
import UIKit

@available(iOS 27.0, *)
enum HolyPlacesIntentError: LocalizedError {
    case placeNotFound
    case noPlaces

    var errorDescription: String? {
        switch self {
        case .placeNotFound:
            return "That holy place could not be found."
        case .noPlaces:
            return "No holy places are available yet."
        }
    }
}

@available(iOS 27.0, *)
struct RecordVisitIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Visit"
    static var description = IntentDescription("Record a visit to a temple or other holy place, including the date and any ordinances.")
    static var openAppWhenRun = false

    @Parameter(title: "Place")
    var place: PlaceEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Baptisms")
    var baptisms: Int?

    @Parameter(title: "Confirmations")
    var confirmations: Int?

    @Parameter(title: "Initiatories")
    var initiatories: Int?

    @Parameter(title: "Endowments")
    var endowments: Int?

    @Parameter(title: "Sealings")
    var sealings: Int?

    /// Asked only when an active-temple visit did not already name any ordinance counts.
    @Parameter(title: "Performed Ordinances")
    var performedOrdinances: Bool?

    @Parameter(title: "Notes")
    var notes: String?

    @Parameter(title: "Profile")
    var profile: ProfileEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Record a visit to \(\.$place)") {
            \.$date
            \.$baptisms
            \.$confirmations
            \.$initiatories
            \.$endowments
            \.$sealings
            \.$notes
            \.$profile
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let visitDate = date ?? Date()
        let isActiveTemple = await MainActor.run {
            PlaceEntity.temple(id: place.id)?.templeType == "T"
        }
        let counts = try await resolvedOrdinanceCounts(isActiveTemple: isActiveTemple)
        let providedNotes: String?
        if notes == nil {
            providedNotes = try await $notes.requestValue("Any notes to include? Say none to skip.")
        } else {
            providedNotes = notes
        }
        let comment = Self.normalizedNotes(providedNotes)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let spokenDate = formatter.string(from: visitDate)
        try await requestConfirmation(
            actionName: .add,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: confirmationPrompt(on: spokenDate, counts: counts, notes: comment)))
        )

        let savedName: String = try await MainActor.run {
            guard let temple = PlaceEntity.temple(id: place.id) else {
                throw HolyPlacesIntentError.placeNotFound
            }
            let isTemple = temple.templeType == "T"
            let profileId = profile?.id ?? ProfileManager.shared.effectiveProfileId() ?? ""
            let record = VisitRecord(
                holyPlace: temple.effectiveName(for: visitDate),
                placeType: temple.templeType,
                date: visitDate,
                baptisms: isTemple ? clampedCount(counts.baptisms) : 0,
                confirmations: isTemple ? clampedCount(counts.confirmations) : 0,
                initiatories: isTemple ? clampedCount(counts.initiatories) : 0,
                endowments: isTemple ? clampedCount(counts.endowments) : 0,
                sealings: isTemple ? clampedCount(counts.sealings) : 0,
                comments: comment,
                shiftHours: 0,
                isFavorite: false,
                imageData: nil,
                profileIds: [profileId]
            )
            try VisitStore.record(record)
            return record.holyPlace
        }

        return .result(dialog: "Recorded a visit to \(savedName) on \(spokenDate).")
    }

    /// Prompts for ordinance counts only when the person has not already named any.
    private func resolvedOrdinanceCounts(isActiveTemple: Bool) async throws -> OrdinanceCounts {
        guard isActiveTemple else {
            return OrdinanceCounts(baptisms: 0, confirmations: 0, initiatories: 0, endowments: 0, sealings: 0)
        }
        let anySpecified = [baptisms, confirmations, initiatories, endowments, sealings].contains { $0 != nil }
        if anySpecified {
            return OrdinanceCounts(
                baptisms: baptisms ?? 0,
                confirmations: confirmations ?? 0,
                initiatories: initiatories ?? 0,
                endowments: endowments ?? 0,
                sealings: sealings ?? 0
            )
        }
        let didPerform: Bool
        if let performedOrdinances {
            didPerform = performedOrdinances
        } else {
            didPerform = try await $performedOrdinances.requestValue("Did you perform any ordinances?")
        }
        guard didPerform else {
            return OrdinanceCounts(baptisms: 0, confirmations: 0, initiatories: 0, endowments: 0, sealings: 0)
        }
        return OrdinanceCounts(
            baptisms: try await $baptisms.requestValue("How many baptisms? Say zero for none."),
            confirmations: try await $confirmations.requestValue("How many confirmations? Say zero for none."),
            initiatories: try await $initiatories.requestValue("How many initiatories? Say zero for none."),
            endowments: try await $endowments.requestValue("How many endowments? Say zero for none."),
            sealings: try await $sealings.requestValue("How many sealings? Say zero for none.")
        )
    }

    private func confirmationPrompt(on spokenDate: String, counts: OrdinanceCounts, notes: String) -> String {
        var prompt = "Record a visit to \(place.name) on \(spokenDate)"
        let ordinances = [
            spokenCount(counts.baptisms, singular: "baptism", plural: "baptisms"),
            spokenCount(counts.confirmations, singular: "confirmation", plural: "confirmations"),
            spokenCount(counts.initiatories, singular: "initiatory", plural: "initiatories"),
            spokenCount(counts.endowments, singular: "endowment", plural: "endowments"),
            spokenCount(counts.sealings, singular: "sealing", plural: "sealings")
        ].compactMap { $0 }
        if !ordinances.isEmpty {
            prompt += ", with \(ordinances.joined(separator: ", "))"
        }
        if !notes.isEmpty {
            prompt += ". Notes: \(notes)"
        }
        prompt += "?"
        return prompt
    }

    private struct OrdinanceCounts {
        var baptisms: Int
        var confirmations: Int
        var initiatories: Int
        var endowments: Int
        var sealings: Int
    }

    private func spokenCount(_ count: Int?, singular: String, plural: String) -> String? {
        guard let count, count > 0 else { return nil }
        return "\(count) \(count == 1 ? singular : plural)"
    }

    private static func normalizedNotes(_ notes: String?) -> String {
        let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch trimmed.lowercased() {
        case "", "none", "no", "no notes", "no note", "skip", "nothing":
            return ""
        default:
            return trimmed
        }
    }

    private func clampedCount(_ value: Int?) -> Int16 {
        Int16(clamping: max(0, value ?? 0))
    }
}

@available(iOS 27.0, *)
struct NavigateToPlaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate to Holy Place"
    static var description = IntentDescription("Get driving directions to a holy place. Uses the nearest place when no place is named.")
    static var openAppWhenRun = true

    @Parameter(title: "Place")
    var place: PlaceEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Navigate to \(\.$place)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let destination: (name: String, latitude: Double, longitude: Double) = try await MainActor.run {
            if let place {
                guard let temple = PlaceEntity.temple(id: place.id) else {
                    throw HolyPlacesIntentError.placeNotFound
                }
                return (temple.templeName, temple.templeLatitude, temple.templeLongitude)
            }
            ad.updateDistance(placesToUpdate: allPlaces)
            guard let nearest = allPlaces.min(by: {
                ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude)
            }) else {
                throw HolyPlacesIntentError.noPlaces
            }
            return (nearest.templeName, nearest.templeLatitude, nearest.templeLongitude)
        }

        if let url = URL(string: "http://maps.apple.com/maps?saddr=&daddr=\(destination.latitude),\(destination.longitude)") {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
        return .result(dialog: "Directions to \(destination.name).")
    }
}

@available(iOS 27.0, *)
struct GoalProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Temple Goal Progress"
    static var description = IntentDescription("Report progress on this year's temple and ordinance goals.")
    static var openAppWhenRun = false

    @Parameter(title: "Profile")
    var profile: ProfileEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Goal progress for \(\.$profile)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let spoken = await MainActor.run {
            HolyPlacesSpokenStats.spokenGoalProgress(profileId: profile?.id)
        }
        return .result(dialog: "\(spoken)")
    }
}

@available(iOS 27.0, *)
struct VisitSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Visit Summary"
    static var description = IntentDescription("Report how many holy places and temples have been visited.")
    static var openAppWhenRun = false

    @Parameter(title: "Profile")
    var profile: ProfileEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Visit summary for \(\.$profile)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let spoken = await MainActor.run {
            HolyPlacesSpokenStats.visitSummary(profileId: profile?.id)
        }
        return .result(dialog: "\(spoken)")
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenPlaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Holy Place"
    static var description = IntentDescription("Open a holy place in Holy Places.")

    @Parameter(title: "Place")
    var target: PlaceEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SiriNavigation.shared.request(.openPlace(id: target.id))
        }
        return .result()
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenVisitIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Visit"
    static var description = IntentDescription("Open a recorded visit in Holy Places.")

    @Parameter(title: "Visit")
    var target: VisitEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SiriNavigation.shared.request(.openVisit(uri: target.id))
        }
        return .result()
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.searchInApp)
struct SearchHolyPlacesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Holy Places"
    static var description = IntentDescription("Search holy places and visit notes.")
    static var searchScopes: [StringSearchScope] = [.general]

    @Parameter(title: "Criteria")
    var criteria: StringSearchCriteria

    func perform() async throws -> some IntentResult {
        let term = criteria.term
        let route: SiriRoute = await MainActor.run {
            if PlaceEntity.matching(term).isEmpty && VisitEntity.hasCommentMatch(term) {
                return .searchVisits(term)
            }
            return .searchPlaces(term)
        }
        await MainActor.run {
            SiriNavigation.shared.request(route)
        }
        return .result()
    }
}

@available(iOS 27.0, *)
struct HolyPlacesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordVisitIntent(),
            phrases: [
                "Record a temple visit in \(.applicationName)",
                "Record a visit in \(.applicationName)"
            ],
            shortTitle: "Record Visit",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: NavigateToPlaceIntent(),
            phrases: [
                "Navigate to the nearest temple in \(.applicationName)",
                "Directions to the nearest temple in \(.applicationName)"
            ],
            shortTitle: "Nearest Temple",
            systemImageName: "location"
        )
        AppShortcut(
            intent: GoalProgressIntent(),
            phrases: [
                "Temple goal progress in \(.applicationName)",
                "How am I doing on my temple goal in \(.applicationName)"
            ],
            shortTitle: "Goal Progress",
            systemImageName: "target"
        )
        AppShortcut(
            intent: VisitSummaryIntent(),
            phrases: [
                "How many temples have I visited in \(.applicationName)",
                "Visit summary in \(.applicationName)"
            ],
            shortTitle: "Visit Summary",
            systemImageName: "list.bullet"
        )
    }
}

@available(iOS 27.0, *)
enum HolyPlacesSpokenStats {
    @MainActor
    static func spokenGoalProgress(profileId: String?) -> String {
        let activeId = ProfileManager.shared.effectiveProfileId()
        let requested = profileId ?? activeId
        let text: String
        if requested == nil || requested == activeId {
            ad.getVisits()
            text = goalProgress
        } else {
            text = goalProgressText(for: requested!)
        }
        return spokenGoal(text, profileId: requested)
    }

    @MainActor
    static func visitSummary(profileId: String?) -> String {
        let requested = profileId ?? ProfileManager.shared.effectiveProfileId()
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        if let requested {
            request.predicate = NSPredicate(format: "profileId == %@", requested)
        }
        let results = (try? ad.getContext().fetch(request)) ?? []
        var places = Set<String>()
        var temples = Set<String>()
        for visit in results {
            guard let name = visit.holyPlace else { continue }
            let canonical = ad.canonicalName(for: name)
            places.insert(canonical)
            if visit.type == "T" || visit.type == "C" {
                temples.insert(canonical)
            }
        }

        let who = profileLabel(profileId: requested)
        if places.isEmpty {
            if let who {
                return "\(who) has not recorded any visits yet."
            }
            return "You have not recorded any visits yet."
        }
        let placeWord = places.count == 1 ? "holy place" : "holy places"
        let templeWord = temples.count == 1 ? "temple" : "temples"
        if let who {
            return "\(who) has visited \(places.count) \(placeWord), including \(temples.count) \(templeWord)."
        }
        return "You have visited \(places.count) \(placeWord), including \(temples.count) \(templeWord)."
    }

    @MainActor
    private static func goalProgressText(for profileId: String) -> String {
        guard let profile = ProfileManager.shared.profileById(profileId) else { return "SET GOAL" }
        let visitGoal = intValue(profile, "annualVisitGoal")
        let baptismGoal = intValue(profile, "annualBaptismGoal")
        let initiatoryGoal = intValue(profile, "annualInitiatoryGoal")
        let endowmentGoal = intValue(profile, "annualEndowmentGoal")
        let sealingGoal = intValue(profile, "annualSealingGoal")
        let excludeEmpty = profile.value(forKey: "excludeNonOrdinanceVisits") as? Bool ?? false

        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND profileId == %@", "T", profileId)
        request.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        let results = (try? ad.getContext().fetch(request)) ?? []

        let userCalendar = Calendar.current
        var currentYearStart = DateComponents()
        currentYearStart.year = Int(currentYear)
        currentYearStart.day = 1
        currentYearStart.month = 1
        let currentYearDate = userCalendar.date(from: currentYearStart) ?? Date()

        var attended = 0
        var baptisms = 0
        var initiatories = 0
        var endowments = 0
        var sealings = 0
        for visit in results {
            guard let visitDate = visit.dateVisited else { continue }
            guard visitDate.daysBetweenDate(toDate: Date()) < currentYearDate.daysBetweenDate(toDate: Date()) else { continue }
            if excludeEmpty {
                if visit.baptisms > 0 || visit.confirmations > 0 || visit.initiatories > 0 || visit.endowments > 0 || visit.sealings > 0 {
                    attended += 1
                }
            } else {
                attended += 1
            }
            baptisms += Int(visit.baptisms) + Int(visit.confirmations)
            initiatories += Int(visit.initiatories)
            endowments += Int(visit.endowments)
            sealings += Int(visit.sealings)
        }

        var text = ""
        if visitGoal > 0 {
            text = "\(attended) of \(visitGoal) Visits\n"
        }
        if baptismGoal > 0 {
            text += "\(baptisms) of \(baptismGoal) Bapt/Conf\n"
        }
        if initiatoryGoal > 0 {
            text += "\(initiatories) of \(initiatoryGoal) Initiatories\n"
        }
        if endowmentGoal > 0 {
            text += "\(endowments) of \(endowmentGoal) Endowments\n"
        }
        if sealingGoal > 0 {
            text += "\(sealings) of \(sealingGoal) Sealings"
        }
        return text.isEmpty ? "SET GOAL" : text
    }

    @MainActor
    private static func spokenGoal(_ text: String, profileId: String?) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = profileLabel(profileId: profileId)
        if trimmed.isEmpty || trimmed == "SET GOAL" {
            if let who {
                return "\(who) has not set a goal for this year."
            }
            return "You have not set a goal for this year."
        }
        let spoken = trimmed.replacingOccurrences(of: "\n", with: ". ")
        if let who {
            return "\(who)'s goal progress: \(spoken)."
        }
        return "Goal progress: \(spoken)."
    }

    @MainActor
    private static func profileLabel(profileId: String?) -> String? {
        guard profilesEnabled else { return nil }
        if let profileId, let profile = ProfileEntity.find(profileId) {
            return profile.name
        }
        return ProfileManager.shared.activeProfileName()
    }

    private static func intValue(_ object: NSManagedObject, _ key: String) -> Int {
        if let value = object.value(forKey: key) as? Int { return value }
        if let value = object.value(forKey: key) as? Int16 { return Int(value) }
        if let value = object.value(forKey: key) as? NSNumber { return value.intValue }
        return 0
    }
}
