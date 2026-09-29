//
//  SiriEntities.swift
//  Holy Places
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import AppIntents
import CoreData
import CoreSpotlight
import Foundation

@available(iOS 27.0, *)
struct PlaceEntity: AppEntity, IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Holy Place")
    static var defaultQuery = PlaceEntityQuery()

    var id: String
    var name: String
    var city: String
    var country: String
    var typeCode: String
    var typeName: String
    var historicalNames: String
    var snippet: String

    /// Names a person might say, so Spotlight can resolve "Rome temple" to "Rome Italy Temple".
    private var spokenAliases: [String] {
        var aliases = historicalNames
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
        aliases.append(name)
        if name.hasSuffix(" Temple") {
            let shortName = String(name.dropLast(" Temple".count))
            aliases.append(shortName)
            aliases.append("\(shortName) Temple")
        }
        if !city.isEmpty {
            aliases.append(city)
        }
        var seen = Set<String>()
        return aliases.filter { seen.insert($0.lowercased()).inserted }
    }

    var displayRepresentation: DisplayRepresentation {
        let subtitle = [city, country].filter { !$0.isEmpty }.joined(separator: ", ")
        if subtitle.isEmpty {
            return DisplayRepresentation(title: "\(name)")
        }
        return DisplayRepresentation(title: "\(name)", subtitle: "\(subtitle)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.displayName = name
        attributes.contentDescription = snippet
        attributes.city = city
        attributes.country = country
        let aliases = spokenAliases
        if !aliases.isEmpty {
            attributes.keywords = aliases
            attributes.alternateNames = aliases
        }
        return attributes
    }

    init(temple: Temple) {
        id = PlaceEntity.stableID(for: temple)
        name = temple.templeName
        city = temple.templeCityState
        country = temple.templeCountry
        typeCode = temple.templeType
        typeName = PlaceEntity.typeName(for: temple.templeType)
        historicalNames = temple.oldNames.joined(separator: "\n")
        snippet = temple.templeSnippet
    }

    static func stableID(for temple: Temple) -> String {
        let trimmed = temple.templeId.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? temple.templeName : trimmed
    }

    static func identifier(for temple: Temple) -> EntityIdentifier {
        EntityIdentifier(for: PlaceEntity(temple: temple))
    }

    static func typeName(for code: String) -> String {
        switch code {
        case "T":
            return "Temple"
        case "H":
            return "Historical Site"
        case "A":
            return "Announced Temple"
        case "C":
            return "Temple Under Construction"
        case "V":
            return "Visitors' Center"
        default:
            return "Holy Place"
        }
    }

    @MainActor
    static func ensureCatalogLoaded() {
        if allPlaces.isEmpty {
            ad.getPlaces()
        }
    }

    @MainActor
    static func all() -> [PlaceEntity] {
        allPlaces
            .map { PlaceEntity(temple: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @MainActor
    static func find(_ id: String) -> PlaceEntity? {
        guard let temple = temple(id: id) else { return nil }
        return PlaceEntity(temple: temple)
    }

    @MainActor
    static func temple(id: String) -> Temple? {
        allPlaces.first { stableID(for: $0) == id }
    }

    @MainActor
    static func resolving(name: String, on date: Date) -> PlaceEntity? {
        let canonical = ad.canonicalName(for: name)
        guard let temple = allPlaces.first(where: { candidate in
            candidate.templeName == name
                || candidate.templeName == canonical
                || candidate.effectiveName(for: date) == name
                || candidate.oldNames.contains(name)
        }) else { return nil }
        return PlaceEntity(temple: temple)
    }

    @MainActor
    static func matching(_ string: String) -> [PlaceEntity] {
        let terms = significantTerms(in: stringByRemovingSpokenDate(string))
        guard !terms.isEmpty else { return [] }
        let phrase = terms.joined(separator: " ")
        var bestScore = 0
        var best: [PlaceEntity] = []
        for temple in allPlaces {
            let name = temple.templeName.lowercased()
            let haystack = temple.listSearchText.lowercased()
            guard terms.allSatisfy({ haystack.contains($0) }) else { continue }
            let score: Int
            if name.contains(phrase) {
                score = 3
            } else if terms.allSatisfy({ name.contains($0) }) {
                score = 2
            } else {
                score = 1
            }
            if score < bestScore { continue }
            let entity = PlaceEntity(temple: temple)
            if score > bestScore {
                bestScore = score
                best = [entity]
            } else {
                best.append(entity)
            }
        }
        return best.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func searchTerms(in string: String) -> [String] {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
    }

    /// Words that should not block a place match, plus "temple" when a more specific word remains.
    static func significantTerms(in string: String) -> [String] {
        let terms = searchTerms(in: string).compactMap { term -> String? in
            let cleaned = term.lowercased().trimmingCharacters(in: .punctuationCharacters)
            guard !cleaned.isEmpty, !fillerWords.contains(cleaned) else { return nil }
            return cleaned
        }
        let specific = terms.filter { !commandWords.contains($0) && !dateWords.contains($0) && Int($0) == nil }
        return specific.isEmpty ? terms : specific
    }

    /// Pulls a spoken date out of a place phrase such as "Rome temple on September 1" and remembers it for the visit.
    @MainActor
    static func stringByRemovingSpokenDate(_ text: String) -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = detector.matches(in: text, options: [], range: range).first(where: { result in
            guard result.date != nil, let swiftRange = Range(result.range, in: text) else { return false }
            return looksLikeSpokenDate(String(text[swiftRange]))
        }), let detected = match.date, let swiftRange = Range(match.range, in: text) else { return text }
        capturedSpokenDate = (detected, Date())
        var stripped = text
        stripped.removeSubrange(swiftRange)
        return stripped
    }

    @MainActor
    static func consumeCapturedSpokenDate() -> Date? {
        defer { capturedSpokenDate = nil }
        guard let capturedSpokenDate, Date().timeIntervalSince(capturedSpokenDate.at) < 30 else { return nil }
        return capturedSpokenDate.value
    }

    private static func looksLikeSpokenDate(_ snippet: String) -> Bool {
        let text = snippet.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard text.count >= 3 else { return false }
        if text.contains(where: \.isLetter) { return true }
        return text.contains("/") || text.contains("-")
    }

    @MainActor private static var capturedSpokenDate: (value: Date, at: Date)?

    private static let fillerWords: Set<String> = ["a", "an", "the", "to", "at", "in", "my", "of", "for", "me", "please", "on"]
    private static let commandWords: Set<String> = [
        "add", "record", "log", "visit", "visits", "temple", "temples", "holy", "place", "places"
    ]
    private static let dateWords: Set<String> = [
        "yesterday", "today", "tomorrow", "last", "next", "this", "ago", "dated",
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
        "january", "february", "march", "april", "may", "june", "july", "august",
        "september", "october", "november", "december"
    ]
}

@available(iOS 27.0, *)
struct PlaceEntityQuery: EntityStringQuery, IndexedEntityQuery {
    func entities(for identifiers: [PlaceEntity.ID]) async throws -> [PlaceEntity] {
        await MainActor.run {
            PlaceEntity.ensureCatalogLoaded()
            return identifiers.compactMap { PlaceEntity.find($0) }
        }
    }

    func entities(matching string: String) async throws -> [PlaceEntity] {
        await MainActor.run {
            PlaceEntity.ensureCatalogLoaded()
            return PlaceEntity.matching(string)
        }
    }

    func suggestedEntities() async throws -> [PlaceEntity] {
        await MainActor.run {
            PlaceEntity.ensureCatalogLoaded()
            return PlaceEntity.all()
        }
    }

    func reindexEntities(for identifiers: [PlaceEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        let entities = await MainActor.run {
            identifiers.compactMap { PlaceEntity.find($0) }
        }
        if !entities.isEmpty {
            try await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await HolyPlacesSpotlightIndexer.reindexPlaces()
    }
}

@available(iOS 27.0, *)
struct VisitEntity: AppEntity, IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Visit")
    static var defaultQuery = VisitEntityQuery()

    var id: String
    var placeName: String
    var date: Date
    var comments: String
    var profileName: String
    var baptisms: Int
    var confirmations: Int
    var initiatories: Int
    var endowments: Int
    var sealings: Int

    var displayRepresentation: DisplayRepresentation {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var subtitle = formatter.string(from: date)
        if profilesEnabled, !profileName.isEmpty {
            subtitle += " · \(profileName)"
        }
        return DisplayRepresentation(title: "\(placeName)", subtitle: "\(subtitle)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.displayName = placeName
        attributes.contentCreationDate = date
        let note = comments.trimmingCharacters(in: .whitespacesAndNewlines)
        attributes.contentDescription = note.isEmpty ? placeName : String(note.prefix(4000))
        return attributes
    }

    init(visit: Visit, profileName: String) {
        id = visit.objectID.uriRepresentation().absoluteString
        placeName = visit.holyPlace ?? ""
        date = visit.dateVisited ?? Date()
        comments = visit.comments ?? ""
        self.profileName = profileName
        baptisms = Int(visit.baptisms)
        confirmations = Int(visit.confirmations)
        initiatories = Int(visit.initiatories)
        endowments = Int(visit.endowments)
        sealings = Int(visit.sealings)
    }

    @MainActor
    static func identifier(for visit: Visit) -> EntityIdentifier {
        let name = profileName(for: visit.profileId)
        return EntityIdentifier(for: VisitEntity(visit: visit, profileName: name))
    }

    @MainActor
    static func profileName(for profileId: String?) -> String {
        guard let profileId, let profile = ProfileManager.shared.profileById(profileId) else { return "" }
        return profile.value(forKey: "name") as? String ?? ""
    }

    @MainActor
    static func profileNames() -> [String: String] {
        Dictionary(uniqueKeysWithValues: ProfileManager.shared.allProfiles().compactMap { profile -> (String, String)? in
            guard let id = profile.value(forKey: "profileId") as? String else { return nil }
            return (id, profile.value(forKey: "name") as? String ?? "")
        })
    }

    @MainActor
    static func make(from visit: Visit, names: [String: String]? = nil) -> VisitEntity {
        let lookup = names ?? profileNames()
        let name = lookup[visit.profileId ?? ""] ?? ""
        return VisitEntity(visit: visit, profileName: name)
    }

    @MainActor
    static func allForIndexing() -> [VisitEntity] {
        let names = profileNames()
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.propertiesToFetch = ["holyPlace", "dateVisited", "comments", "profileId", "baptisms", "confirmations", "initiatories", "endowments", "sealings"]
        let visits = (try? ad.getContext().fetch(request)) ?? []
        return visits.map { make(from: $0, names: names) }
    }

    @MainActor
    static func find(_ id: String) -> VisitEntity? {
        guard let visit = visit(uri: id) else { return nil }
        return make(from: visit)
    }

    @MainActor
    static func visit(uri: String) -> Visit? {
        guard let url = URL(string: uri),
              let objectID = ad.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url),
              let visit = try? ad.getContext().existingObject(with: objectID) as? Visit else {
            return nil
        }
        return visit
    }

    @MainActor
    static func matching(_ string: String, profileId: String?) -> [VisitEntity] {
        let terms = PlaceEntity.searchTerms(in: string)
        let names = profileNames()
        return fetched(profileId: profileId).compactMap { visit in
            guard !terms.isEmpty else { return make(from: visit, names: names) }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateText = visit.dateVisited.map { formatter.string(from: $0) } ?? ""
            let haystack = "\(visit.holyPlace ?? "") \(visit.comments ?? "") \(dateText)".lowercased()
            guard terms.allSatisfy({ haystack.contains($0.lowercased()) }) else { return nil }
            return make(from: visit, names: names)
        }
    }

    @MainActor
    static func hasCommentMatch(_ string: String) -> Bool {
        let terms = PlaceEntity.searchTerms(in: string)
        guard !terms.isEmpty else { return false }
        return fetched(profileId: nil).contains { visit in
            let comments = visit.comments ?? ""
            return terms.allSatisfy { comments.range(of: $0, options: .caseInsensitive) != nil }
        }
    }

    @MainActor
    private static func fetched(profileId: String?) -> [Visit] {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        request.propertiesToFetch = ["holyPlace", "dateVisited", "comments", "profileId", "baptisms", "confirmations", "initiatories", "endowments", "sealings", "type"]
        if let profileId {
            request.predicate = NSPredicate(format: "profileId == %@", profileId)
        } else if let predicate = ProfileManager.shared.visitProfilePredicate() {
            request.predicate = predicate
        }
        return (try? ad.getContext().fetch(request)) ?? []
    }
}

@available(iOS 27.0, *)
struct VisitEntityQuery: EntityStringQuery, IndexedEntityQuery {
    func entities(for identifiers: [VisitEntity.ID]) async throws -> [VisitEntity] {
        await MainActor.run {
            identifiers.compactMap { VisitEntity.find($0) }
        }
    }

    func entities(matching string: String) async throws -> [VisitEntity] {
        await MainActor.run {
            VisitEntity.matching(string, profileId: nil)
        }
    }

    func suggestedEntities() async throws -> [VisitEntity] {
        await MainActor.run {
            Array(VisitEntity.matching("", profileId: nil).prefix(20))
        }
    }

    func reindexEntities(for identifiers: [VisitEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        let entities = await MainActor.run {
            identifiers.compactMap { VisitEntity.find($0) }
        }
        if !entities.isEmpty {
            try await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await HolyPlacesSpotlightIndexer.reindexVisits()
    }
}

@available(iOS 27.0, *)
struct ProfileEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Profile")
    static var defaultQuery = ProfileEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    @MainActor
    static func find(_ id: String) -> ProfileEntity? {
        guard let profile = ProfileManager.shared.profileById(id),
              let name = profile.value(forKey: "name") as? String else { return nil }
        return ProfileEntity(id: id, name: name)
    }

    @MainActor
    static func all() -> [ProfileEntity] {
        ProfileManager.shared.allProfiles().compactMap { profile in
            guard let id = profile.value(forKey: "profileId") as? String else { return nil }
            let name = profile.value(forKey: "name") as? String ?? ""
            return ProfileEntity(id: id, name: name)
        }
    }
}

@available(iOS 27.0, *)
struct ProfileEntityQuery: EntityStringQuery {
    func entities(for identifiers: [ProfileEntity.ID]) async throws -> [ProfileEntity] {
        await MainActor.run {
            identifiers.compactMap { ProfileEntity.find($0) }
        }
    }

    func entities(matching string: String) async throws -> [ProfileEntity] {
        await MainActor.run {
            let needle = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return ProfileEntity.all().filter { profile in
                needle.isEmpty || profile.name.range(of: needle, options: .caseInsensitive) != nil
            }
        }
    }

    func suggestedEntities() async throws -> [ProfileEntity] {
        await MainActor.run { ProfileEntity.all() }
    }
}

@available(iOS 27.0, *)
enum HolyPlacesSpotlightIndexer {
    static func reindexAll() async {
        try? await reindexPlaces()
        try? await reindexVisits()
    }

    static func reindexPlaces() async throws {
        let entities = await MainActor.run { PlaceEntity.all() }
        guard !entities.isEmpty else { return }
        let index = CSSearchableIndex.default()
        try await index.deleteAppEntities(ofType: PlaceEntity.self)
        try await index.indexAppEntities(entities)
    }

    static func reindexVisits() async throws {
        let entities = await MainActor.run { VisitEntity.allForIndexing() }
        let index = CSSearchableIndex.default()
        try await index.deleteAppEntities(ofType: VisitEntity.self)
        if !entities.isEmpty {
            try await index.indexAppEntities(entities)
        }
    }
}
