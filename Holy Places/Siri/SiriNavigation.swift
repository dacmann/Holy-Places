//
//  SiriNavigation.swift
//  Holy Places
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation

enum SiriRoute {
    case openPlace(id: String)
    case openVisit(uri: String)
    case searchPlaces(String)
    case searchVisits(String)
    case recordVisit(placeId: String?)
}

final class SiriNavigation {
    static let shared = SiriNavigation()
    static let didRequestRoute = Notification.Name("SiriNavigationDidRequestRoute")

    private var pending: SiriRoute?

    func request(_ route: SiriRoute) {
        pending = route
        NotificationCenter.default.post(name: Self.didRequestRoute, object: nil)
    }

    /// Leaves the route queued when the window is not ready, so a later
    /// scene activation can still open it.
    func consumeIfWindowIsReady(_ isReady: Bool) -> SiriRoute? {
        guard isReady, let route = pending else { return nil }
        pending = nil
        return route
    }
}
