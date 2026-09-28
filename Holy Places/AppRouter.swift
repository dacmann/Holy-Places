//
//  AppRouter.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreLocation
import UIKit

enum AppTab: Int {
    case home = 0
    case places = 1
    case visits = 2
    case summary = 3
    case map = 4
}

struct PlacesRoute: Equatable {
    var templeId: String?
    var placeName: String?
    var search: String?
    var nearest = false
    var random = false
    var token = UUID()
}

struct VisitsRoute: Equatable {
    var objectURI: String?
    var search: String?
    var quickAdd = false
    var token = UUID()
}

func stablePlaceID(_ temple: Temple) -> String {
    let trimmed = temple.templeId.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? temple.templeName : trimmed
}

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    weak var tabBar: UITabBarController?

    @Published var placesRoute: PlacesRoute?
    @Published var visitsRoute: VisitsRoute?

    func select(_ tab: AppTab) {
        tabBar?.selectedIndex = tab.rawValue
    }

    func openPlace(id: String) {
        select(.places)
        placesRoute = PlacesRoute(templeId: id)
    }

    func openPlace(named name: String) {
        select(.places)
        placesRoute = PlacesRoute(placeName: name)
    }

    func searchPlaces(_ term: String) {
        select(.places)
        placesRoute = PlacesRoute(search: term)
    }

    func showNearestPlaces() {
        placeSortRow = 1
        placeFilterRow = 0
        locationSpecific = false
        select(.places)
        placesRoute = PlacesRoute(nearest: true)
    }

    func openRandomPlace() {
        select(.places)
        placesRoute = PlacesRoute(random: true)
    }

    func openVisit(objectURI: String) {
        select(.visits)
        visitsRoute = VisitsRoute(objectURI: objectURI)
    }

    func searchVisits(_ term: String) {
        select(.visits)
        visitsRoute = VisitsRoute(search: term)
    }

    func quickAddVisit() {
        select(.visits)
        visitsRoute = VisitsRoute(quickAdd: true)
    }

    func showVisits() {
        select(.visits)
    }
}
