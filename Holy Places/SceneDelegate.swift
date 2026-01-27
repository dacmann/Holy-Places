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
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // Handle Quick Action if app was launched from one
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
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
        
        ad.saveContext()
        
        // Add Quick Launch shortcut when authorized
        let manager = CLLocationManager()
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            ad.locationServiceSetup()
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
        guard let myTabBar = self.window?.rootViewController as? UITabBarController else {
            return false
        }
        
        switch shortcutIdentifier {
        case .ShowNearest:
            placeSortRow = 1
            placeFilterRow = 0
            locationSpecific = false
            myTabBar.selectedIndex = 1
            guard let nvc = myTabBar.selectedViewController as? UINavigationController else {
                return false
            }
            guard let vc = nvc.viewControllers.first as? TableViewController else {
                return false
            }
            nvc.popToRootViewController(animated: false)
            vc.nearestEnabled = true
            return vc.openForPlace(shortcutIdentifier: shortcutIdentifier)
        case .OpenRandomPlace:
            myTabBar.selectedIndex = 1
            guard let nvc = myTabBar.selectedViewController as? UINavigationController else {
                return false
            }
            guard let vc = nvc.viewControllers.first as? TableViewController else {
                return false
            }
            nvc.popToRootViewController(animated: false)
            return vc.openForPlace(shortcutIdentifier: shortcutIdentifier)
        case .RecordVisit, .Reminder:
            myTabBar.selectedIndex = 2
            guard let nvc = myTabBar.selectedViewController as? UINavigationController else {
                return false
            }
            guard let vc = nvc.viewControllers.first as? VisitTableVC else {
                return false
            }
            nvc.popToRootViewController(animated: false)
            return vc.quickAddVisit(shortcutIdentifier: shortcutIdentifier)
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
