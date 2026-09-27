//
//  VisitStore.swift
//  Holy Places
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreData
import Foundation

struct VisitRecord {
    var holyPlace: String
    var placeType: String
    var date: Date?
    var baptisms: Int16
    var confirmations: Int16
    var initiatories: Int16
    var endowments: Int16
    var sealings: Int16
    var comments: String
    var shiftHours: Double
    var isFavorite: Bool
    var imageData: Data?
    var profileIds: Set<String>
}

enum VisitStoreError: LocalizedError {
    case createFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "Could not create the visit."
        case .saveFailed:
            return "Could not save the visit."
        }
    }
}

enum VisitStore {
    @discardableResult
    static func record(_ record: VisitRecord) throws -> [Visit] {
        let context = ad.persistentContainer.viewContext
        let profileIds = record.profileIds.isEmpty
            ? [ProfileManager.shared.effectiveProfileId() ?? ""]
            : Array(record.profileIds)
        let year = ad.calendarYearString(for: record.date ?? Date())
        var saved: [Visit] = []

        for profileId in profileIds {
            guard let visit = NSEntityDescription.insertNewObject(forEntityName: "Visit", into: context) as? Visit else {
                context.rollback()
                throw VisitStoreError.createFailed
            }
            visit.holyPlace = record.holyPlace
            visit.baptisms = record.baptisms
            visit.confirmations = record.confirmations
            visit.initiatories = record.initiatories
            visit.endowments = record.endowments
            visit.sealings = record.sealings
            visit.comments = record.comments
            visit.dateVisited = record.date
            visit.year = year
            visit.type = record.placeType
            visit.shiftHrs = record.shiftHours
            visit.isFavorite = record.isFavorite
            visit.profileId = profileId
            visit.picture = record.imageData
            saved.append(visit)
        }

        guard !saved.isEmpty else { throw VisitStoreError.createFailed }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw VisitStoreError.saveFailed
        }

        ad.needsVisitRefresh = true
        ad.getVisits()
        if #available(iOS 27.0, *) {
            Task { try? await HolyPlacesSpotlightIndexer.reindexVisits() }
        }
        return saved
    }
}

enum VisitDonation {
    static func donateRecordedVisit(
        holyPlace: String,
        date: Date,
        profileId: String?,
        baptisms: Int,
        confirmations: Int,
        initiatories: Int,
        endowments: Int,
        sealings: Int,
        notes: String
    ) {
        guard #available(iOS 27.0, *) else { return }
        let name = holyPlace
        let visitDate = date
        let profile = profileId
        Task { @MainActor in
            guard let place = PlaceEntity.resolving(name: name, on: visitDate) else { return }
            let intent = RecordVisitIntent()
            intent.place = place
            intent.date = visitDate
            intent.baptisms = baptisms
            intent.confirmations = confirmations
            intent.initiatories = initiatories
            intent.endowments = endowments
            intent.sealings = sealings
            intent.notes = notes
            if let profile, let profileEntity = ProfileEntity.find(profile) {
                intent.profile = profileEntity
            }
            _ = try? await intent.donate()
        }
    }
}
