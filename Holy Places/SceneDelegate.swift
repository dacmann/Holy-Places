//
//  SceneDelegate.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/25/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let tabs = HolyPlacesTabBarController()
        window.rootViewController = tabs
        self.window = window
        window.makeKeyAndVisible()
        AppRouter.shared.tabBar = tabs

        NotificationCenter.default.addObserver(self, selector: #selector(siriRouteRequested), name: SiriNavigation.didRequestRoute, object: nil)

        // Handle Quick Action if app was launched from one
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
        
        // Handle URL if app was cold-launched from widget tap (urlContexts only present on cold launch)
        if let url = connectionOptions.urlContexts.first?.url {
            DispatchQueue.main.async { [weak self] in
                self?.handleWidgetURL(url)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        applyPendingSiriRoute()
    }

    @objc private func siriRouteRequested() {
        applyPendingSiriRoute()
    }

    private func applyPendingSiriRoute() {
        guard let route = SiriNavigation.shared.consumeIfWindowIsReady(window?.rootViewController != nil) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.perform(route)
        }
    }

    private func perform(_ route: SiriRoute) {
        switch route {
        case .openPlace(let id):
            AppRouter.shared.openPlace(id: id)
        case .searchPlaces(let term):
            AppRouter.shared.searchPlaces(term)
        case .openVisit(let uri):
            AppRouter.shared.openVisit(objectURI: uri)
        case .searchVisits(let term):
            AppRouter.shared.searchVisits(term)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        // Reload settings to ensure background image preferences are up to date
        ad.loadSettings()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save settings
        if ad.settings == nil {
            ad.settings = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: ad.persistentContainer.viewContext) as? Settings
        }
        ad.settings?.altLocation = locationSpecific
        ad.settings?.altLocStreet = altLocStreet
        ad.settings?.altLocCity = altLocCity
        ad.settings?.altLocState = altLocState
        ad.settings?.altLocPostalCode = altLocPostalCode
        if coordAltLocation != nil {
            ad.settings?.altLocLatitude = coordAltLocation.coordinate.latitude
            ad.settings?.altLocLongitude = coordAltLocation.coordinate.longitude
        }
        ad.settings?.annualVisitGoal = Int16(annualVisitGoal)
        ad.settings?.annualBaptismGoal = Int16(annualBaptismGoal)
        ad.settings?.annualInitiatoryGoal = Int16(annualInitiatoryGoal)
        ad.settings?.annualEndowmentGoal = Int16(annualEndowmentGoal)
        ad.settings?.annualSealingGoal = Int16(annualSealingGoal)
        ad.settings?.placeFilterRow = Int16(placeFilterRow)
        ad.settings?.placeSortRow = Int16(placeSortRow)
        ad.settings?.visitFilterRow = Int16(visitFilterRow)
        ad.settings?.visitSortRow = Int16(visitSortRow)
        ad.settings?.notificationEnabled = notificationEnabled
        ad.settings?.notificationFilter = notificationFilter
        ad.settings?.notificationDelay = notificationDelayInMinutes
        ad.settings?.holyPlaceVisited = holyPlaceVisited
        ad.settings?.dateHolyPlaceVisited = dateHolyPlaceVisited
        ad.settings?.homeTextColor = homeTextColor
        ad.settings?.homeDefaultPicture = homeDefaultPicture
        ad.settings?.homeAlternatePicture = homeAlternatePicture
        ad.settings?.homeVisitPicture = homeVisitPicture
        ad.settings?.ordinanceWorker = ordinanceWorker
        ad.settings?.excludeNonOrdinanceVisits = excludeNonOrdinanceVisits
        ad.settings?.copyAddDays = copyAddDays
        ad.settings?.defaultCommentsText = defaultCommentsText
        ad.settings?.profilesEnabled = profilesEnabled
        
        // Save goals to active profile
        if profilesEnabled, let profileId = activeProfileId {
            let context = ad.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Profile")
            fetchRequest.predicate = NSPredicate(format: "profileId == %@", profileId)
            if let profile = try? context.fetch(fetchRequest).first {
                profile.setValue(Int16(annualVisitGoal), forKey: "annualVisitGoal")
                profile.setValue(Int16(annualBaptismGoal), forKey: "annualBaptismGoal")
                profile.setValue(Int16(annualInitiatoryGoal), forKey: "annualInitiatoryGoal")
                profile.setValue(Int16(annualEndowmentGoal), forKey: "annualEndowmentGoal")
                profile.setValue(Int16(annualSealingGoal), forKey: "annualSealingGoal")
                profile.setValue(excludeNonOrdinanceVisits, forKey: "excludeNonOrdinanceVisits")
            }
        }
        
        ad.saveContext()
        
        // Add Quick Launch shortcut when authorized
        let manager = CLLocationManager()
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            ad.locationServiceSetup()
        }
    }
    
    // MARK: - URL Handling (Widget Deep Links)
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleWidgetURL(url)
    }
    
    private func handleWidgetURL(_ url: URL) {
        switch url.host {
        case "place":
            if let placeName = url.pathComponents.last?.removingPercentEncoding, !placeName.isEmpty, placeName != "/" {
                AppRouter.shared.openPlace(named: placeName)
            } else {
                AppRouter.shared.select(.places)
            }
        case "visit":
            let objectIDString = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "id" })?.value?.removingPercentEncoding ?? ""
            if !objectIDString.isEmpty {
                AppRouter.shared.openVisit(objectURI: objectIDString)
            } else {
                AppRouter.shared.showVisits()
            }
        case "visits":
            AppRouter.shared.showVisits()
        case "goals":
            AppRouter.shared.select(.home)
        case "summary":
            AppRouter.shared.select(.summary)
        default:
            AppRouter.shared.select(.home)
        }
    }
    
    // MARK: - Quick Actions (Shortcut Items)
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcutItem(shortcutItem))
    }
    
    @discardableResult
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        let shortcutType = shortcutItem.type
        guard let shortcutIdentifier = ShortcutIdentifier(identifier: shortcutType) else {
            return false
        }
        return selectTabBarItemFor(shortcutIdentifier: shortcutIdentifier)
    }
    
    private func selectTabBarItemFor(shortcutIdentifier: ShortcutIdentifier) -> Bool {
        guard window?.rootViewController != nil else { return false }

        switch shortcutIdentifier {
        case .ShowNearest:
            AppRouter.shared.showNearestPlaces()
            return true
        case .OpenRandomPlace:
            AppRouter.shared.openRandomPlace()
            return true
        case .RecordVisit, .Reminder:
            AppRouter.shared.quickAddVisit()
            return true
        case .NavigateTo:
            // Open and show coordinate
            let latitude = quickLaunchItem?.coordinate.latitude
            let longitude = quickLaunchItem?.coordinate.longitude
            let url = URL(string: "http://maps.apple.com/maps?saddr=&daddr=\(latitude ?? 0.0),\(longitude ?? 0.0)")
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            return true
        default:
            return false
        }
    }
}
