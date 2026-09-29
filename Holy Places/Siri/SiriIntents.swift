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
    var place: PlaceEntity?

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Baptisms", default: nil)
    var baptisms: Int?

    @Parameter(title: "Confirmations", default: nil)
    var confirmations: Int?

    @Parameter(title: "Initiatories", default: nil)
    var initiatories: Int?

    @Parameter(title: "Endowments", default: nil)
    var endowments: Int?

    @Parameter(title: "Sealings", default: nil)
    var sealings: Int?

    /// Spoken reply when an active-temple visit did not already name a count.
    @Parameter(title: "Ordinance Details")
    var ordinanceDetails: String?

    @Parameter(title: "Notes")
    var notes: String?

    @Parameter(title: "Baptism Answer")
    var baptismAnswer: String?

    @Parameter(title: "Confirmation Answer")
    var confirmationAnswer: String?

    @Parameter(title: "Initiatory Answer")
    var initiatoryAnswer: String?

    @Parameter(title: "Endowment Answer")
    var endowmentAnswer: String?

    @Parameter(title: "Sealing Answer")
    var sealingAnswer: String?

    @Parameter(title: "Profile")
    var profile: ProfileEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Record a visit to \(\.$place) on \(\.$date)") {
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
        let place = try await resolvedPlace()
        let capturedDate = await MainActor.run { PlaceEntity.consumeCapturedSpokenDate() }
        let visitDate = date ?? capturedDate ?? Date()
        let counts = try await resolvedOrdinanceCounts(isActiveTemple: place.typeCode == "T")
        let providedNotes: String?
        if notes == nil {
            providedNotes = try await $notes.requestValue("What notes should I save with this visit? Say none to skip.")
        } else {
            providedNotes = notes
        }
        let comment = Self.normalizedNotes(providedNotes)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let spokenDate = formatter.string(from: visitDate)
        try await requestConfirmation(
            actionName: .add,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: confirmationPrompt(for: place.name, on: spokenDate, counts: counts, notes: comment)))
        )

        let savedName: String = try await MainActor.run {
            PlaceEntity.ensureCatalogLoaded()
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

    /// Uses counts already spoken in the first request. Otherwise asks once and parses the reply.
    private func resolvedOrdinanceCounts(isActiveTemple: Bool) async throws -> OrdinanceCounts {
        guard isActiveTemple else { return .noneRecorded }
        let alreadySpoken = OrdinanceCounts(
            baptisms: Self.positive(baptisms),
            confirmations: Self.positive(confirmations),
            initiatories: Self.positive(initiatories),
            endowments: Self.positive(endowments),
            sealings: Self.positive(sealings)
        )
        if alreadySpoken.hasAny { return alreadySpoken }

        let reply: String
        if let ordinanceDetails, !ordinanceDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reply = ordinanceDetails
        } else {
            reply = try await $ordinanceDetails.requestValue("Which ordinances did you perform, and how many? Say none to skip.")
        }
        let parsed = OrdinanceSpeech.parse(reply)
        if parsed.skipped { return .noneRecorded }
        return OrdinanceCounts(
            baptisms: try await resolvedCount(parsed.baptisms, ask: parsed.shouldAsk(.baptisms), answer: baptismAnswer) {
                try await $baptismAnswer.requestValue("How many baptisms? Say zero for none.")
            },
            confirmations: try await resolvedCount(parsed.confirmations, ask: parsed.shouldAsk(.confirmations), answer: confirmationAnswer) {
                try await $confirmationAnswer.requestValue("How many confirmations? Say zero for none.")
            },
            initiatories: try await resolvedCount(parsed.initiatories, ask: parsed.shouldAsk(.initiatories), answer: initiatoryAnswer) {
                try await $initiatoryAnswer.requestValue("How many initiatories? Say zero for none.")
            },
            endowments: try await resolvedCount(parsed.endowments, ask: parsed.shouldAsk(.endowments), answer: endowmentAnswer) {
                try await $endowmentAnswer.requestValue("How many endowments? Say zero for none.")
            },
            sealings: try await resolvedCount(parsed.sealings, ask: parsed.shouldAsk(.sealings), answer: sealingAnswer) {
                try await $sealingAnswer.requestValue("How many sealings? Say zero for none.")
            }
        )
    }

    private func resolvedCount(
        _ parsed: OrdinanceSpeech.SpokenCount,
        ask: Bool,
        answer: String?,
        request: () async throws -> String
    ) async throws -> Int {
        switch parsed {
        case .number(let count):
            return count
        case .needsNumber, .unmentioned:
            guard ask else { return 0 }
            let spoken = try await spokenCountAnswer(answer, request: request)
            return OrdinanceSpeech.count(in: spoken) ?? 0
        }
    }

    private func spokenCountAnswer(
        _ answer: String?,
        request: () async throws -> String
    ) async throws -> String {
        if let answer {
            let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return try await request()
    }

    private func resolvedPlace() async throws -> PlaceEntity {
        if let place { return place }
        return try await $place.requestValue("Which holy place did you visit?")
    }

    private func confirmationPrompt(for placeName: String, on spokenDate: String, counts: OrdinanceCounts, notes: String) -> String {
        var prompt = "Record a visit to \(placeName) on \(spokenDate)"
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
        prompt += "."
        if !notes.isEmpty {
            prompt += " Notes: \(notes)."
        }
        prompt += " Save this visit?"
        return prompt
    }

    private struct OrdinanceCounts {
        var baptisms: Int
        var confirmations: Int
        var initiatories: Int
        var endowments: Int
        var sealings: Int

        static let noneRecorded = OrdinanceCounts(baptisms: 0, confirmations: 0, initiatories: 0, endowments: 0, sealings: 0)

        var hasAny: Bool {
            baptisms > 0 || confirmations > 0 || initiatories > 0 || endowments > 0 || sealings > 0
        }
    }

    private static func positive(_ value: Int?) -> Int {
        guard let value, value > 0 else { return 0 }
        return value
    }

    private func spokenCount(_ count: Int?, singular: String, plural: String) -> String? {
        guard let count, count > 0 else { return nil }
        return "\(count) \(count == 1 ? singular : plural)"
    }

    private static func normalizedNotes(_ notes: String?) -> String {
        let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch trimmed.lowercased() {
        case "", "none", "no", "skip", "nothing":
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
private enum OrdinanceSpeech {
    enum Kind {
        case baptisms
        case confirmations
        case initiatories
        case endowments
        case sealings
    }

    enum SpokenCount: Equatable {
        case unmentioned
        case needsNumber
        case number(Int)
    }

    struct Result {
        var skipped = false
        var askAll = false
        var baptisms: SpokenCount = .unmentioned
        var confirmations: SpokenCount = .unmentioned
        var initiatories: SpokenCount = .unmentioned
        var endowments: SpokenCount = .unmentioned
        var sealings: SpokenCount = .unmentioned

        func shouldAsk(_ kind: Kind) -> Bool {
            if askAll { return true }
            switch kind {
            case .baptisms: return baptisms == .needsNumber
            case .confirmations: return confirmations == .needsNumber
            case .initiatories: return initiatories == .needsNumber
            case .endowments: return endowments == .needsNumber
            case .sealings: return sealings == .needsNumber
            }
        }

        mutating func set(_ kind: Kind, to count: SpokenCount) {
            switch kind {
            case .baptisms: baptisms = count
            case .confirmations: confirmations = count
            case .initiatories: initiatories = count
            case .endowments: endowments = count
            case .sealings: sealings = count
            }
        }
    }

    static func parse(_ reply: String) -> Result {
        let tokens = tokens(in: reply)
        let phrase = tokens.joined(separator: " ")
        if tokens.isEmpty || skipPhrases.contains(phrase) {
            return Result(skipped: true)
        }
        if affirmativePhrases.contains(phrase) {
            return Result(askAll: true)
        }

        var result = Result()
        var namedAny = false
        for (index, token) in tokens.enumerated() {
            guard let kind = kind(for: token) else { continue }
            namedAny = true
            if let number = nearbyNumber(in: tokens, around: index) {
                result.set(kind, to: .number(number))
            } else {
                result.set(kind, to: .needsNumber)
            }
        }
        if !namedAny {
            result.askAll = true
        }
        return result
    }

    static func count(in reply: String) -> Int? {
        let tokens = tokens(in: reply)
        let phrase = tokens.joined(separator: " ")
        if skipPhrases.contains(phrase) || phrase == "zero" { return 0 }
        for index in tokens.indices {
            if let number = spokenNumber(in: tokens, endingAt: index) {
                return number
            }
        }
        return nil
    }

    private static func kind(for token: String) -> Kind? {
        switch token {
        case "baptism", "baptisms":
            return .baptisms
        case "confirmation", "confirmations":
            return .confirmations
        case "initiatory", "initiatories":
            return .initiatories
        case "endowment", "endowments":
            return .endowments
        case "sealing", "sealings":
            return .sealings
        default:
            return nil
        }
    }

    private static func nearbyNumber(in tokens: [String], around index: Int) -> Int? {
        if let number = numberScanning(tokens, from: index - 1, step: -1, stopAt: 0) {
            return number
        }
        return numberScanning(tokens, from: index + 1, step: 1, stopAt: tokens.count - 1)
    }

    private static func numberScanning(_ tokens: [String], from start: Int, step: Int, stopAt end: Int) -> Int? {
        guard !tokens.isEmpty, step != 0 else { return nil }
        var index = start
        while step > 0 ? index <= end : index >= end {
            let token = tokens[index]
            if kind(for: token) != nil { return nil }
            if let number = spokenNumber(in: tokens, endingAt: index) {
                return number
            }
            if !ignoredTokens.contains(token) { return nil }
            index += step
        }
        return nil
    }

    private static func spokenNumber(in tokens: [String], endingAt index: Int) -> Int? {
        guard tokens.indices.contains(index) else { return nil }
        let token = tokens[index]
        if let digits = Int(token) { return digits }
        if token.contains("-") {
            let parts = token.split(separator: "-").map(String.init)
            if parts.count == 2, let tens = tensWords[parts[0]], let ones = onesWords[parts[1]], ones > 0 {
                return tens + ones
            }
        }
        if let ones = onesWords[token] {
            if index > 0, let tens = tensWords[tokens[index - 1]], ones > 0 {
                return tens + ones
            }
            return ones
        }
        if let tens = tensWords[token] {
            if index + 1 < tokens.count, let ones = onesWords[tokens[index + 1]], ones > 0 {
                return tens + ones
            }
            return tens
        }
        return nil
    }

    private static func tokens(in text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-")).inverted)
            .filter { !$0.isEmpty }
    }

    private static let skipPhrases: Set<String> = ["none", "no", "skip", "nothing"]
    private static let affirmativePhrases: Set<String> = ["yes", "yeah", "yep", "yea"]
    private static let ignoredTokens: Set<String> = ["and", "a", "an", "the", "of", "with", "yes", "yeah", "yep", "yea"]
    private static let onesWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19
    ]
    private static let tensWords: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90
    ]
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
enum VisitPhrase {
    static func isRecordRequest(_ text: String) -> Bool {
        let normalized = normalize(text)
        let startsCommand = normalized.hasPrefix("add ") || normalized.hasPrefix("record ") || normalized.hasPrefix("log ")
        return startsCommand && normalized.contains("visit")
    }

    /// Place words left after a record-visit command. An ordinary place name is returned unchanged.
    static func placeText(from text: String) -> String {
        var normalized = normalize(text)
        for suffix in [" in holy places", " holy places"] where normalized.hasSuffix(suffix) {
            normalized.removeLast(suffix.count)
        }
        let prefixes = [
            "add a temple visit to ",
            "record a temple visit to ",
            "add a visit to ",
            "record a visit to ",
            "log a visit to ",
            "add temple visit to ",
            "record temple visit to ",
            "add visit to ",
            "record visit to ",
            "add a temple visit",
            "record a temple visit",
            "add a visit",
            "record a visit",
            "log a visit",
            "add visit",
            "record visit"
        ]
        for prefix in prefixes where normalized.hasPrefix(prefix) {
            normalized.removeFirst(prefix.count)
            break
        }
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
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
        if VisitPhrase.isRecordRequest(term) {
            let spoken = VisitPhrase.placeText(from: term)
            await MainActor.run {
                PlaceEntity.ensureCatalogLoaded()
                let placeId = spoken.isEmpty ? nil : PlaceEntity.matching(spoken).first?.id
                SiriNavigation.shared.request(.recordVisit(placeId: placeId))
            }
            return .result()
        }
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
                "Add a visit to \(\.$place) in \(.applicationName)",
                "Record a visit to \(\.$place) in \(.applicationName)",
                "Add a temple visit to \(\.$place) in \(.applicationName)",
                "Record a temple visit to \(\.$place) in \(.applicationName)"
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
