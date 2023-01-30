//
//  AppDelegate.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications
//import StoreKit

enum ShortcutIdentifier: String {
    case ShowNearest
    case OpenRandomPlace
    case RecordVisit
    case Reminder
    case ViewPlace
    case NavigateTo
    
    init?(identifier: String) {
        guard let shortIdentifier = identifier.components(separatedBy: ".").last else {
            return nil
        }
        self.init(rawValue: shortIdentifier)
    }
}

//MARK: - Global Variables
var places: [Temple] = []
var allPlaces: [Temple] = []
var activeTemples: [Temple] = []
var historical: [Temple] = []
var construction: [Temple] = []
var announced: [Temple] = []
var allTemples: [Temple] = []
var visitors: [Temple] = []
var placeDataVersion: String?
var greatTip = String()
var greaterTip = String()
var greatestTip = String()
//var greatTipPC = SKProduct()
//var greaterTipPC = SKProduct()
//var greatestTipPC = SKProduct()
var changesDate = String()
var changesMsg1 = String()
var changesMsg2 = String()
var changesMsg3 = String()
var coordAltLocation: CLLocation!
var locationSpecific = Bool()
var altLocStreet = String()
var altLocCity = String()
var altLocState = String()
var altLocPostalCode = String()
var annualVisitGoal = 12 as Int
var placeFilterRow = Int()
var placeSortRow = Int()
var visitFilterRow = Int()
var visitSortRow = Int()
var mapFilterRow = Int()
var mapPoints: [MapPoint] = []
var detailItem: Temple?
var quickLaunchItem: Temple?
var mapVisitedFilter = Int()
var visits = [String]()
var mapCenter = CLLocationCoordinate2D()
var mapPoint = MapPoint(title: "", coordinate: mapCenter, type: "")
var mapZoomLevel = Double()
var versionChecked = false
var checkedForUpdate: Date?
var currentYear = String()
var attended = 0
var goalProgress = String()
var notificationEnabled = Bool()
var notificationFilter = Bool()
var dateHolyPlaceVisited: Date?
var holyPlaceVisited: String?
var dateFromNotification: Date?
var placeFromNotification: String?
var notificationDelayInMinutes = Int16()
var notificationData: NSDictionary?
var homeAlternatePicture: Data?
var homeVisitPicture = false
var homeVisitPictureData: Data?
var homeDefaultPicture = true
var homeTextColor = 0 as Int16
var homeVisitDate: String?
var ordinanceWorker = Bool()
var excludeNonOrdinanceVisits = Bool()
var optionsChanged = false
var visitsInTable: [Visit] = []
var selectedVisitRow = Int()
var selectedPlaceRow = Int()
var summaryQuotes: [String] = []
var distinctTemplesVisited: [String] = []
var distinctHistoricSitesVisited: [String] = []
var achievements: [Achievement] = []
var completed: [Achievement] = []
var notCompleted: [Achievement] = []
var attendedTotal = 0
var sealingsTotal = 0
var endowmentsTotal = 0
var initiatoriesTotal = 0
var confirmationsTotal = 0
var baptismsTotal = 0
var ordinancesTotal = 0
var shiftHoursTotal = 0.0
var didOrdinances = false
var copyVisit: Visit?
var copyAddDays = 7 as Int16
var ad = AppDelegate()

@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {
class AppDelegate: UIResponder, UIApplicationDelegate, XMLParserDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

    //MARK: - Variables
    var xmlParser: XMLParser!
    var eName: String = String()
    var templeName = String()
    var templeAddress = String()
    var templeSnippet = String()
    var templeCityState = String()
    var templeCountry = String()
    var templePhone = String()
    var templeLatitude = Double()
    var templeLongitude = Double()
    var templePictureURL = String()
    var templeType = String()
    var readerView = Bool()
    var infoURL = String()
    var templeSiteURL = String()
    var templeSqFt = Int32()
    var fhCode = String()
    var window: UIWindow?
    var settings: Settings?
    let locationManager = CLLocationManager()
    let notificationManager = UNUserNotificationCenter.current()
    var coordinateOfUser: CLLocation!
    var closestPlace = String()
    let distanceFilter = 10000.0 // 10,000 meters
    let visitLengthInSec = 600.0 // 10 minutes
    var visitElapsedTime: TimeInterval?
    var monitoredRegions: Dictionary<String, NSDate> = [:]
    var newFileParsed = false
    
    // MARK: - Standard Events

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        SKPaymentQueue.default().add(self)
//        UITextViewWorkaround.executeWorkaround()
        
        locationManager.delegate = self
        notificationManager.delegate = self
        
        // Change the font of the tab bar items
        let tabBarItemFont = UIFont(name: "Baskerville", size: 13) ?? UIFont.systemFont(ofSize: 13)
        let textAttributes = [NSAttributedString.Key.font: tabBarItemFont]
        
        UITabBarItem.appearance().setTitleTextAttributes(textAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(textAttributes, for: .selected)
        UITabBar.appearance().tintColor = UIColor(named: "BaptismsBlue")
        
        // Change the font and color for the navigation Bar text
        let barbuttonFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)

        let style = UINavigationBarAppearance()
        style.configureWithOpaqueBackground()
        style.buttonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor(named: "BaptismsBlue")!]
        style.doneButtonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor(named: "BaptismsBlue")!]
        style.titleTextAttributes = [
            .foregroundColor : UIColor(named: "BaptismsBlue")!, // Navigation bar title color
            .font : navbarFont // Navigation bar title font
        ]
        UINavigationBar.appearance().standardAppearance = style
        UINavigationBar.appearance().compactAppearance = style
        UINavigationBar.appearance().scrollEdgeAppearance = style
        
        if #available(iOS 15.0, *) {
            
            let tabBarItemAppearance = UITabBarItemAppearance()
            tabBarItemAppearance.normal.titleTextAttributes = textAttributes
            tabBarItemAppearance.selected.titleTextAttributes = textAttributes
            
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground
            //tabBarAppearance.
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UITabBar.appearance().standardAppearance = tabBarAppearance
            
            tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
            tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
            tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
        }
        
        //Load any saved settings
        ad = UIApplication.shared.delegate as! AppDelegate
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        
        // Get version of saved data
        getPlaceVersion()
        
        // Get Saved places
        getPlaces()
        
        // Update Places
        refreshTemples()
        
        do {
            //go get the results
            let searchResults = try context.fetch(fetchRequest)
            
            if searchResults.count > 0 {
                
                for setting in searchResults as [Settings] {
                    settings = setting
                    altLocStreet = (settings?.altLocStreet)!
                    altLocCity = (settings?.altLocCity)!
                    altLocState = (settings?.altLocState)!
                    altLocPostalCode = (settings?.altLocPostalCode)!
                    locationSpecific = (settings?.altLocation)!
                    coordAltLocation = CLLocation(latitude: (settings?.altLocLatitude)!, longitude: (settings?.altLocLongitude)!)
                    placeSortRow = Int((settings?.placeSortRow)!)
                    placeFilterRow = Int((settings?.placeFilterRow)!)
                    visitSortRow = Int((settings?.visitSortRow)!)
                    visitFilterRow = Int((settings?.visitFilterRow)!)
                    annualVisitGoal = Int((settings?.annualVisitGoal)!)
                    notificationEnabled = (settings?.notificationEnabled)!
                    notificationFilter = (settings?.notificationFilter)!
                    notificationDelayInMinutes = (settings?.notificationDelay)!
                    holyPlaceVisited  = settings?.holyPlaceVisited
                    dateHolyPlaceVisited = settings?.dateHolyPlaceVisited
                    homeTextColor = (settings?.homeTextColor)!
                    homeDefaultPicture = (settings?.homeDefaultPicture)!
                    homeAlternatePicture = settings?.homeAlternatePicture
                    homeVisitPicture = (settings?.homeVisitPicture)!
                    ordinanceWorker = (settings?.ordinanceWorker)!
                    excludeNonOrdinanceVisits = (settings?.excludeNonOrdinanceVisits)!
                    copyAddDays = (settings?.copyAddDays)!
                }
            } else {
                // nothing to do here
            }
        } catch {
            print("Error with request: \(error)")
        }
        
        // Add Quick Launch shortcut when authorized
        let manager = CLLocationManager()
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            print("Location Services Authorized")
            locationServiceSetup()
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // Save settings
        if settings == nil {
            settings = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: persistentContainer.viewContext) as? Settings
        }
        settings?.altLocation = locationSpecific
        settings?.altLocStreet = altLocStreet
        settings?.altLocCity = altLocCity
        settings?.altLocState = altLocState
        settings?.altLocPostalCode = altLocPostalCode
        if coordAltLocation != nil {
            settings?.altLocLatitude = coordAltLocation.coordinate.latitude
            settings?.altLocLongitude = coordAltLocation.coordinate.longitude
        }
        settings?.annualVisitGoal = Int16(annualVisitGoal)
        settings?.placeFilterRow = Int16(placeFilterRow)
        settings?.placeSortRow = Int16(placeSortRow)
        settings?.visitFilterRow = Int16(visitFilterRow)
        settings?.visitSortRow = Int16(visitSortRow)
        settings?.notificationEnabled = notificationEnabled
        settings?.notificationFilter = notificationFilter
        settings?.notificationDelay = notificationDelayInMinutes
        settings?.holyPlaceVisited = holyPlaceVisited
        settings?.dateHolyPlaceVisited = dateHolyPlaceVisited
        settings?.homeTextColor = homeTextColor
        settings?.homeDefaultPicture = homeDefaultPicture
        settings?.homeAlternatePicture = homeAlternatePicture
        settings?.homeVisitPicture = homeVisitPicture
        settings?.ordinanceWorker = ordinanceWorker
        settings?.excludeNonOrdinanceVisits = excludeNonOrdinanceVisits
        settings?.copyAddDays = copyAddDays
        
        //        SKPaymentQueue.default().remove(self)
        self.saveContext()
        
        // Add Quick Launch shortcut when authorized
        let manager = CLLocationManager()
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            locationServiceSetup()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    /// set orientations you want to be allowed in this property by default
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    // MARK: - Location Services
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location Update")
        coordinateOfUser = manager.location
        // Updated QuickLaunch shortcut
        DetermineClosest()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            print("Location Authorized")
            coordinateOfUser = manager.location
        } else {
            print("Location not authorized")
            coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // entered region
        // Add entrance time
        monitoredRegions[region.identifier] = NSDate()
        print("Entered region for \(region.identifier) at \(Date())")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // exited region
        print("Exited region for \(region.identifier) at \(Date())")
        // calculate visit time
        if let timeEntered = monitoredRegions[region.identifier] {
            visitElapsedTime = NSDate().timeIntervalSince(timeEntered as Date)
            //Remove entrance time
            monitoredRegions.removeValue(forKey: region.identifier)
            print("Visited \(region.identifier) for \(Int(visitElapsedTime!/60)) minutes")
        } else {
            // No entry record - phone may have been turned off
            visitElapsedTime = 999  // default value to greater than 10 minutes
            print("Visited \(region.identifier) for undetermined amount of time")
        }
        // create notification if visited more than 10 minutes
//        if Int(visitElapsedTime!) > 599 {
        // disable time crieria to see if it resolves consistency issue
            holyPlaceVisited = region.identifier
            dateHolyPlaceVisited = Date()
            shouldNotify()
//        }
    }
    
    func locationServiceSetup() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            let manager = CLLocationManager()
            switch(manager.authorizationStatus) {
            case .notDetermined, .restricted, .denied:
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Location Services Allowed")
                if notificationEnabled {
                    // Request authorization for Notifcation alerts and sounds
                    notificationManager.requestAuthorization(options: [.alert, .sound], completionHandler: { (permissionGranted, error) in
                        print(error as Any)
                    })
                }
                locationManager.startMonitoringSignificantLocationChanges()
                // Add Quick Launch Shortcut to record visit for nearest place
                DetermineClosest()
            @unknown default:
                print("Not handled")
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    // Update the Distance in the Place data arrays based on new location
    fileprivate func DetermineClosest() {
        let regionRadius = 100.0

        // Check for notification criteria
        if notificationEnabled {
            // Update distances for allPlaces (minus annunced temples) or activeTemples array based on filter
            var placesForRegionMonitoring = allPlaces.filter {!announced.contains($0)}
            
            if notificationFilter {
                // remove any non-temple regions being monitored since temple only notifications is enabled
                for region in locationManager.monitoredRegions {
                    // find region in array to determine if it is a temple
                    if let found = placesForRegionMonitoring.firstIndex(where:{$0.templeName == region.identifier}) {
                        if placesForRegionMonitoring[found].templeType != "T" {
                            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: placesForRegionMonitoring[found].coordinate.latitude, longitude: placesForRegionMonitoring[found].coordinate.longitude), radius: regionRadius, identifier: placesForRegionMonitoring[found].templeName)
                            if locationManager.monitoredRegions.contains(region) {
                                print("Removing region for \(placesForRegionMonitoring[found].templeName)")
                                locationManager.stopMonitoring(for: region)
                            }
                        }
                    }
                }
                // Change to only temples
                placesForRegionMonitoring = activeTemples
            }
            updateDistance(placesToUpdate: placesForRegionMonitoring)
            placesForRegionMonitoring.sort { Int($0.distance!) < Int($1.distance!) }
            
            // remove any regions no longer close
            for region in locationManager.monitoredRegions {
                // find region in array to determine distance
                
                if let found = placesForRegionMonitoring.firstIndex(where:{$0.templeName == region.identifier}) {
//                    print("region set for \(region.identifier) with a distance of \(placesForRegionMonitoring[found].distance!) meters")
                    if placesForRegionMonitoring[found].distance! >= distanceFilter {
                        // remove if further than distanceFilter
                        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: placesForRegionMonitoring[found].coordinate.latitude, longitude: placesForRegionMonitoring[found].coordinate.longitude), radius: regionRadius, identifier: placesForRegionMonitoring[found].templeName)
                        if locationManager.monitoredRegions.contains(region) {
                            print("Removing region for \(placesForRegionMonitoring[found].templeName)")
                            locationManager.stopMonitoring(for: region)
                        }
                    }
                }
            }

            // Update regions being monitored for up to 20 closest
            var placeCount = 0
            for place in placesForRegionMonitoring {
                placeCount += 1
                if placeCount > 20 {
                    break
                }
                if place.distance! < distanceFilter {
                    let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude), radius: regionRadius, identifier: place.templeName)
                    if locationManager.monitoredRegions.contains(region) {
                        print("Region already exists for \(place.templeName)")
                    } else {
                        print("Creating region \(placeCount) for \(place.templeName)")
                        locationManager.startMonitoring(for: region)
                    }
                }
            }
        }
        
        // Update Distance for currently viewed array in table
        updateDistance(placesToUpdate: places, true)
        if placeSortRow == 1 {
            places.sort { Int($0.distance!) < Int($1.distance!) }
        }
        
        // Set QuickLaunch object to closest place based on current location of user
        updateDistance(placesToUpdate: allPlaces)
        allPlaces.sort { Int($0.distance!) < Int($1.distance!) }
        quickLaunchItem = allPlaces[0]
        
        NotificationCenter.default.post(name: .reload, object: nil)
        
        let recordVisitShortcut = UIMutableApplicationShortcutItem(type: "$(PRODUCT_BUNDLE_IDENTIFIER).RecordVisit",
                                                        localizedTitle: "Record Visit",
                                                        localizedSubtitle: quickLaunchItem?.templeName,
                                                        icon: UIApplicationShortcutIcon(type: .compose),
                                                        userInfo: nil
        )
        
        let navigateToPlaceShortcut = UIMutableApplicationShortcutItem(type: "$(PRODUCT_BUNDLE_IDENTIFIER).NavigateTo",
                                                                       localizedTitle: "Navigate To",
                                                                       localizedSubtitle: quickLaunchItem?.templeName,
                                                                       icon: UIApplicationShortcutIcon(templateImageName: "route"),
                                                                       userInfo: nil
        )
        UIApplication.shared.shortcutItems = [recordVisitShortcut, navigateToPlaceShortcut]
        print("Quick Launch updated to \(quickLaunchItem?.templeName ?? "<place name>") with a distance of \(quickLaunchItem?.distance ?? 0)")
  
    }
    
    // Update the distances in the currently viewed array
    func updateDistance(placesToUpdate: [Temple], _ placesInView: Bool = false) {
//        print("Specified Location Used: \(placesInView)")
        for place in placesToUpdate {
            if placesInView && locationSpecific {
                place.distance = place.cllocation.distance(from: coordAltLocation!)
            } else if placesInView || coordinateOfUser == nil {
                if locationManager.location != nil {
                    coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
                } else {
                    // default to Temple Square
                    coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
                }
                place.distance = place.cllocation.distance(from: coordinateOfUser!)
            } else {
                place.distance = place.cllocation.distance(from: coordinateOfUser!)
            }
        }
    }
    
    // MARK: - Notifications
    func shouldNotify() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd, yyyy"
        let dateVisited = formatter.string(from: dateHolyPlaceVisited!)
        
        // Construct Notification
        let notifyContent = UNMutableNotificationContent()
        notifyContent.title = "Record Visit Reminder"
        notifyContent.body = """
        You visited \(holyPlaceVisited ?? "<holyPlaceName>") on \(dateVisited).
        
        Do you want to record your visit now?
        """
        notifyContent.categoryIdentifier = "recordVisitReminder"
        notifyContent.userInfo = ["place":holyPlaceVisited as Any, "dateVisited":dateHolyPlaceVisited as Any]
        notifyContent.sound = UNNotificationSound.default
        
        
        // Schedule delivery
        let notifyTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(notificationDelayInMinutes*60), repeats: false)
        let request = UNNotificationRequest(identifier: "visitReminder:\(holyPlaceVisited ?? "<holy place>")", content: notifyContent, trigger: notifyTrigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            print(error as Any)
        })
        print("Notification requested for \(holyPlaceVisited ?? "<holyPlaceName>")")
        
        // Reset notification variables
        holyPlaceVisited = nil
        dateHolyPlaceVisited = nil
        visitElapsedTime = nil
    }
    
    func updateNotification() {
        // Construct Notification
        let notifyContent = UNMutableNotificationContent()
        notifyContent.title = changesDate + " Update"
        notifyContent.body = changesMsg1
        notifyContent.categoryIdentifier = "dataUpdate"
        //notifyContent.userInfo = ["place":holyPlaceVisited as Any, "dateVisited":dateHolyPlaceVisited as Any]
        notifyContent.sound = UNNotificationSound.default
        
        // Schedule delivery
        let notifyTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(60), repeats: false)
        let request = UNNotificationRequest(identifier: "dataUpdate", content: notifyContent, trigger: notifyTrigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            print(error as Any)
        })
        print("Notification requested for data update")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        notificationData = response.notification.request.content.userInfo as NSDictionary
        if notificationData?.value(forKey: "place") != nil {
            _ = selectTabBarItemFor(shortcutIdentifier: .Reminder)
        }
        completionHandler()
    }

    // MARK: - Quick Launch
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(shouldPerformActionFor(shortcutItem: shortcutItem))
    }
    
    private func shouldPerformActionFor(shortcutItem: UIApplicationShortcutItem) -> Bool {
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
            UIApplication.shared.open(url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            return true
        default:
            return false
        }
    }


    
    //MARK:- Payment function
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//        
//        for transaction in transactions {
//            switch transaction.transactionState {
//            case .purchased:
//                // Remove transaction from queue
//                SKPaymentQueue.default().finishTransaction(transaction)
//                // Alert the user
//                let topWindow: UIWindow = UIWindow(frame: UIScreen.main.bounds)
//                topWindow.rootViewController = UIViewController()
//                topWindow.windowLevel = UIWindowLevelAlert + 1
//                let alert: UIAlertController =  UIAlertController(title: "Thanks for tip!", message: "I really appreciate your support.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
//                    topWindow.isHidden = true
//                }))
//                topWindow.makeKeyAndVisible()
//                topWindow.rootViewController?.present(alert, animated: true, completion: { _ in })
//                break
//            case .failed:
//                // Determine reason for failure
//                let message = transaction.error?.localizedDescription
//                // Remove transaction from queue
//                SKPaymentQueue.default().finishTransaction(transaction)
//                // Alert the user
//                let topWindow: UIWindow = UIWindow(frame: UIScreen.main.bounds)
//                topWindow.rootViewController = UIViewController()
//                topWindow.windowLevel = UIWindowLevelAlert + 1
//                let alert: UIAlertController =  UIAlertController(title: "Purchase Failed", message: (message)!, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
//                    topWindow.isHidden = true
//                }))
//                topWindow.makeKeyAndVisible()
//                topWindow.rootViewController?.present(alert, animated: true, completion: { _ in })
//                break
//            default:
//                break
//            }
//        }
//        
//    }
    
    //MARK: - Update Data
    // Pull down the XML file from website and parse the data
    func refreshTemples() {
            
        // Get version of saved data
        //getPlaceVersion()
        
        // determine latest version from hpVersion.xml file  --- hpVersion-v3.4
        guard let versionURL = NSURL(string: "https://dacworld.net/holyplaces/hpVersion-test.xml") else {
            print("URL not defined properly")
            return
        }
        
        let task = URLSession.shared.downloadTask(with: versionURL as URL)
        {
            (tempURL, response, error) in
            // Handle response, the download file is
            // at tempURL
            if error != nil {
                print("Cannot Read Data ERROR: \(String(describing: error))")
                //self.getPlaces()
                return
            }
            
            /*
             guard let parserVersion = XMLParser(data: data) else {
             print("Cannot Read Data")
             getPlaces()
             return
             }
             
             */
            //guard let (parserVersion, _) = try await URLSession.shared.data(from: versionURL as URL) else {
            guard let parserVersion = XMLParser(contentsOf: versionURL as URL) else {
                print("Cannot Read Data")
                //self.getPlaces()
                return
            }
            
            
            parserVersion.delegate = self
            
            if parserVersion.parse() {
                // Version is different: grab list of temples from HolyPlaces.xml file and parse the XML
                versionChecked = true
                guard let myURL = NSURL(string: "https://dacworld.net/holyplaces/HolyPlaces-test.xml") else {
                    print("URL not defined properly")
                    return
                }
                guard let parser = XMLParser(contentsOf: myURL as URL) else {
                    print("Cannot Read Data")
                    //self.getPlaces()
                    return
                }
                parser.delegate = self
                if parser.parse() {
                    // Save updated places to CoreData
                    //self.storePlaces()
                    self.newFileParsed = true
                } else {
                    print("Data parsing aborted")
                    let error = parser.parserError!
                    print("Error Description:\(error.localizedDescription)")
                    print("Line number: \(parser.lineNumber)")
                    //self.getPlaces()
                }
            } else {
                print("Data parsing aborted")
                let error = parserVersion.parserError!
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parserVersion.lineNumber)")
                // Check if initial launch with no data yet and no internet and load local XML file if so
                if placeDataVersion == nil {
                    versionChecked = true
                    guard let myURL = Bundle.main.url(forResource: "HolyPlaces", withExtension: "xml") else {
                        print("URL not defined properly")
                        return
                    }
                    guard let parser = XMLParser(contentsOf: myURL as URL) else {
                        print("Cannot Read Data")
                        //self.getPlaces()
                        return
                    }
                    print("No internet on initial launch - loading from local XML file")
                    parser.delegate = self
                    if parser.parse() {
                        // Save updated places to CoreData
                        self.storePlaces()
                    } else {
                        print("Data parsing aborted")
                        let error = parser.parserError!
                        print("Error Description:\(error.localizedDescription)")
                        print("Line number: \(parser.lineNumber)")
                        //self.getPlaces()
                    }
                }
                //else {
                //    self.getPlaces()
                //}
            }
            if self.newFileParsed {
                self.storePlaces()
                checkedForUpdate = Date()
                // if app is updated while running in background send notification
                //&& UIApplication.shared.applicationState == .background
                if changesDate != "" {
                    self.updateNotification()
                }
            }

        }
        // Start the download
        task.resume()
        
    }
    
    // didStartElement of parser
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        if elementName == "Place" {
            templeName = String()
            templeAddress = String()
            templeSnippet = String()
            templeCityState = String()
            templeCountry = String()
            templePhone = String()
            templeLatitude = Double()
            templeLongitude = Double()
            templePictureURL = String()
            templeType = String()
            templeSiteURL = String()
            readerView = Bool()
            infoURL = String()
            templeSqFt = Int32(0)
            fhCode = String()
        }
    }
    
    // foundCharacters of parser
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !string.isEmpty {
            switch eName {
            case "name": templeName += string
            case "Address": templeAddress += string
            case "Snippet": templeSnippet += string
            case "CityState": templeCityState += string
            case "Country": templeCountry += string
            case "Phone": templePhone += string
            case "latitude": templeLatitude += Double(string)!
            case "longitude": templeLongitude += Double(string)!
            case "image": templePictureURL += string
            case "type": templeType += string
            case "site_url": templeSiteURL += string
            case "readerView": readerView = Bool(string)!
            case "infoURL": infoURL += string
            case "SqFt": templeSqFt += Int32(string)!
            case "fhc": fhCode += string
            case "Version":
                if string == placeDataVersion {
                    print("XML Data Version has not changed")
                    parser.abortParsing()
                    break
                } else {
                    print("XML Data Version has changed - \(string)")
                    if versionChecked {
                        placeDataVersion = string
                        savePlaceVersion()
                        // Reset arrays
                        activeTemples.removeAll()
                        historical.removeAll()
                        visitors.removeAll()
                        construction.removeAll()
                        announced.removeAll()
                        allPlaces.removeAll()
                        allTemples.removeAll()
                    } else {
                        break
                    }
                }
            case "ChangesDate":
                changesDate += string
            case "ChangesMsg1":
                changesMsg1 += string
            case "ChangesMsg2":
                changesMsg2 += string
            case "ChangesMsg3":
                changesMsg3 += string
            default: return
            }
        }
    }
    
    // didEndElement of parser
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Place" {
            // Determine Order
            let digits = CharacterSet.decimalDigits
            
            var number = String()
            
            for uni in templeSnippet.unicodeScalars {
                if digits.contains(uni) {
                    number += uni.escaped(asASCII: true)
                } else {
                    if number == "" {
                        number = "200"
                    }
                    break
                }
            }
            let temple = Temple(Name: templeName, Address: templeAddress, Snippet: templeSnippet, CityState: templeCityState, Country: templeCountry, Phone: templePhone, Latitude: templeLatitude, Longitude: templeLongitude, Order: Int16(number)!, PictureURL: templePictureURL, SiteURL: templeSiteURL,Type: templeType, ReaderView: readerView, InfoURL: infoURL, SqFt: templeSqFt, FHCode: fhCode)
            
            allPlaces.append(temple)
            switch templeType {
            case "T":
                activeTemples.append(temple)
                allTemples.append(temple)
            case "H":
                historical.append(temple)
            case "V":
                visitors.append(temple)
            case "A":
                announced.append(temple)
                allTemples.append(temple)
            default:
                construction.append(temple)
                allTemples.append(temple)
            }
        }
    }
    
    func initAchievements() {
        achievements.removeAll()
        // Ordinances - Baptisms
        achievements.append(Achievement(Name: "Excellent! (Baptisms)", Details: "Complete 25 Baptisms", IconName: "ach25B"))
        achievements.append(Achievement(Name: "Wonderful! (Baptisms)", Details: "Complete 50 Baptisms", IconName: "ach50B"))
        achievements.append(Achievement(Name: "Incredible! (Baptisms)", Details: "Complete 100 Baptisms", IconName: "ach100B"))
        achievements.append(Achievement(Name: "Extraordinary! (Baptisms)", Details: "Complete 200 Baptisms", IconName: "ach200B"))
        achievements.append(Achievement(Name: "Astounding! (Baptisms)", Details: "Complete 400 Baptisms", IconName: "ach400B"))
        achievements.append(Achievement(Name: "Unbelievable! (Baptisms)", Details: "Complete 800 Baptisms", IconName: "ach800B"))
        // Ordinances - Initiatories
        achievements.append(Achievement(Name: "Excellent! (Initiatories)", Details: "Complete 25 Iniatories", IconName: "ach25I"))
        achievements.append(Achievement(Name: "Wonderful! (Initiatories)", Details: "Complete 50 Iniatories", IconName: "ach50I"))
        achievements.append(Achievement(Name: "Incredible! (Initiatories)", Details: "Complete 100 Iniatories", IconName: "ach100I"))
        achievements.append(Achievement(Name: "Extraordinary! (Initiatories)", Details: "Complete 200 Iniatories", IconName: "ach200I"))
        achievements.append(Achievement(Name: "Astounding! (Initiatories)", Details: "Complete 400 Iniatories", IconName: "ach400I"))
        achievements.append(Achievement(Name: "Unbelievable! (Initiatories)", Details: "Complete 800 Iniatories", IconName: "ach800I"))
        // Ordinances - Endowments
        achievements.append(Achievement(Name: "Excellent! (Endowments)", Details: "Complete 10 Endowments", IconName: "ach10E"))
        achievements.append(Achievement(Name: "Wonderful! (Endowments)", Details: "Complete 25 Endowments", IconName: "ach25E"))
        achievements.append(Achievement(Name: "Incredible! (Endowments)", Details: "Complete 50 Endowments", IconName: "ach50E"))
        achievements.append(Achievement(Name: "Extraordinary! (Endowments)", Details: "Complete 100 Endowments", IconName: "ach100E"))
        achievements.append(Achievement(Name: "Astounding! (Endowments)", Details: "Complete 200 Endowments", IconName: "ach200E"))
        achievements.append(Achievement(Name: "Unbelievable! (Endowments)", Details: "Complete 400 Endowments", IconName: "ach400E"))
        // Ordinances - Sealings
        achievements.append(Achievement(Name: "Excellent! (Sealings)", Details: "Complete 50 Sealings", IconName: "ach50S"))
        achievements.append(Achievement(Name: "Wonderful! (Sealings)", Details: "Complete 100 Sealings", IconName: "ach100S"))
        achievements.append(Achievement(Name: "Incredible! (Sealings)", Details: "Complete 200 Sealings", IconName: "ach200S"))
        achievements.append(Achievement(Name: "Extraordinary! (Sealings)", Details: "Complete 400 Sealings", IconName: "ach400S"))
        achievements.append(Achievement(Name: "Astounding! (Sealings)", Details: "Complete 800 Sealings", IconName: "ach800S"))
        achievements.append(Achievement(Name: "Unbelievable! (Sealings)", Details: "Complete 1600 Sealings", IconName: "ach1600S"))
        if ordinanceWorker {
            // Ordinance Worker
            achievements.append(Achievement(Name: "Excellent! (Ordinance Worker)", Details: "Work 50 hours in the temple", IconName: "ach50W"))
            achievements.append(Achievement(Name: "Wonderful! (Ordinance Worker)", Details: "Work 100 hours in the temple", IconName: "ach100W"))
            achievements.append(Achievement(Name: "Incredible! (Ordinance Worker)", Details: "Work 200 hours in the temple", IconName: "ach200W"))
            achievements.append(Achievement(Name: "Extraordinary! (Ordinance Worker)", Details: "Work 400 hours in the temple", IconName: "ach400W"))
            achievements.append(Achievement(Name: "Astounding! (Ordinance Worker)", Details: "Work 800 hours in the temple", IconName: "ach800W"))
            achievements.append(Achievement(Name: "Unbelievable! (Ordinance Worker)", Details: "Work 1600 hours in the temple", IconName: "ach1600W"))
        }
        // Temples
        achievements.append(Achievement(Name: "Temple Admirer", Details: "Visit 10 different temples", IconName: "ach10T"))
        achievements.append(Achievement(Name: "Temple Lover", Details: "Visit 20 different temples", IconName: "ach20T"))
        achievements.append(Achievement(Name: "Temple Devotee", Details: "Visit 30 different temples", IconName: "ach30T"))
        achievements.append(Achievement(Name: "Temple Enthusiast", Details: "Visit 40 different temples", IconName: "ach40T"))
        achievements.append(Achievement(Name: "Temple Fanatic", Details: "Visit 50 different temples", IconName: "ach50T"))
        achievements.append(Achievement(Name: "Temple Zealot", Details: "Visit 60 different temples", IconName: "ach60T"))
        achievements.append(Achievement(Name: "Temple Visionary", Details: "Visit 75 different temples", IconName: "ach75T"))
        achievements.append(Achievement(Name: "Temple Addict", Details: "Visit 100 different temples", IconName: "ach100T"))
        achievements.append(Achievement(Name: "Temple Aficionado", Details: "Visit 125 different temples", IconName: "ach125T"))
        achievements.append(Achievement(Name: "Temple Buff", Details: "Visit 150 different temples", IconName: "ach150T"))
        if activeTemples.count > 174 {
            achievements.append(Achievement(Name: "Temple Ultraist", Details: "Visit 175 different temples", IconName: "ach175T"))
        }
        if activeTemples.count > 199 {
            achievements.append(Achievement(Name: "Temple Extremist", Details: "Visit 200 different temples", IconName: "ach200T"))
        }
        // Historic Sites
        achievements.append(Achievement(Name: "History Admirer", Details: "Visit 10 different historic sites", IconName: "ach10H"))
        achievements.append(Achievement(Name: "History Lover", Details: "Visit 25 different historic sites", IconName: "ach25H"))
        achievements.append(Achievement(Name: "History Enthusiast", Details: "Visit 40 different historic sites", IconName: "ach40H"))
        achievements.append(Achievement(Name: "History Zealot", Details: "Visit 55 different historic sites", IconName: "ach55H"))
        achievements.append(Achievement(Name: "History Aficionado", Details: "Visit 70 different historic sites", IconName: "ach70H"))
        achievements.append(Achievement(Name: "History Buff", Details: "Visit 85 different historic sites", IconName: "ach85H"))
        achievements.append(Achievement(Name: "History Ultraist", Details: "Visit 99 different historic sites", IconName: "ach99H"))
    }
    
    func updateAchievement(achievement:String, dateAchieved:Date, placeAchieved:String) {
        if let location = achievements.firstIndex(where:{$0.iconName == achievement}) {
            // Only update if not already achieved
            if achievements[location].achieved == nil {
                achievements[location].achieved = dateAchieved
                achievements[location].placeAchieved = placeAchieved
            }
        }
    }
    
    //MARK: - Core Data
    // Required for CoreData
    func getContext () -> NSManagedObjectContext {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return ad.persistentContainer.viewContext
    }
    
    func getVisits () {
        let context = getContext()
        var latestTempleVisited = ""
        var dateLastVisited = ""
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        var year = "1830"
        var month = 1
        
        let yearFormat = DateFormatter()
        yearFormat.dateFormat = "yyyy"
        let monthFormat = DateFormatter()
        monthFormat.dateFormat = "MM"
        
        attendedTotal = 0
        sealingsTotal = 0
        endowmentsTotal = 0
        initiatoriesTotal = 0
        confirmationsTotal = 0
        baptismsTotal = 0
        ordinancesTotal = 0
        shiftHoursTotal = 0.0
        didOrdinances = false
        
        initAchievements()
        distinctHistoricSitesVisited.removeAll()
        distinctTemplesVisited.removeAll()
        
        do {
            // Get All visits
            visits.removeAll()
            var searchResults = try context.fetch(fetchRequest)
            for visit in searchResults as [Visit] {
                // populate year if needed
                if visit.year == nil {
                    visit.year = yearFormat.string(from: visit.dateVisited!)
                    //save the object
                    do {
                        try context.save()
                    } catch let error as NSError  {
                        print("Could not save \(error), \(error.userInfo)")
                    } catch {}
                }
                visits.append(visit.holyPlace!)
            }
            // get temple visits
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            var sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            searchResults = try getContext().fetch(fetchRequest)
            
            let userCalendar = Calendar.current
            var currentYearStart = DateComponents()
            currentYearStart.year = Int(currentYear)
            currentYearStart.day = 1
            currentYearStart.month = 1
            let currentYearDate = userCalendar.date(from: currentYearStart)!
            
            attended = 0
            for visit in searchResults as [Visit] {
                //print((temple.value(forKey: "dateVisited") as! Date).daysBetweenDate(toDate: Date()))
                // check for ordinaces performed in the last year
                if (visit.dateVisited?.daysBetweenDate(toDate: Date()))! < currentYearDate.daysBetweenDate(toDate: Date()) {
                    // check for ordinancs when excluded
                    if excludeNonOrdinanceVisits {
                        if visit.baptisms > 0 || visit.confirmations > 0 || visit.initiatories > 0 || visit.endowments > 0 || visit.sealings > 0 {
                            attended += 1
                        }
                    } else {
                        attended += 1
                    }
                }
                if latestTempleVisited == "" {
                    latestTempleVisited = visit.holyPlace!
                    dateLastVisited = formatter.string(from: visit.dateVisited! as Date)
                }
            }
            
            goalProgress = "\(attended) of \(annualVisitGoal) Visits"
            // Update UserDefaults for Widget
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue(goalProgress, forKey: "goalProgress")
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue(latestTempleVisited, forKey: "latestTempleVisited")
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue(dateLastVisited, forKey: "dateLastVisited")
            
            // get random visit picture
            fetchRequest.predicate = NSPredicate(format: "picture != nil")
            searchResults = try getContext().fetch(fetchRequest)
            if searchResults.count > 0 {
                let randomIndex = Int(arc4random_uniform(UInt32(searchResults.count)))
                let visit = searchResults[randomIndex] as Visit
                homeVisitPictureData = visit.picture!
                homeVisitDate = formatter.string(from: visit.dateVisited!)
            }
            
            // Achievements
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            searchResults = try getContext().fetch(fetchRequest)
            
            for visit in searchResults as [Visit] {
                // count ordinances for each temple visited
                // add to total counts
                
                sealingsTotal += Int(visit.sealings)
                endowmentsTotal += Int(visit.endowments)
                initiatoriesTotal += Int(visit.initiatories)
                confirmationsTotal += Int(visit.confirmations)
                baptismsTotal += Int(visit.baptisms)
                shiftHoursTotal += visit.shiftHrs
                
                // Check if ordnances were performed at this visit
                if Int(visit.baptisms) > 0 || Int(visit.confirmations) > 0 || Int(visit.initiatories) > 0 || Int(visit.endowments) > 0 || Int(visit.sealings) > 0 {
                    didOrdinances = true
                } else {
                    didOrdinances = false
                }
                
                if excludeNonOrdinanceVisits {
                    if didOrdinances {
                        attendedTotal += 1
                    }
                } else {
                    attendedTotal += 1
                }
                
                // determine unique temples visited
                if !distinctTemplesVisited.contains(visit.holyPlace!) {
                    distinctTemplesVisited.append(visit.holyPlace!)
                    if distinctTemplesVisited.count == 10 {
                        updateAchievement(achievement:"ach10T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 20 {
                        updateAchievement(achievement:"ach20T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 30 {
                        updateAchievement(achievement:"ach30T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 40 {
                        updateAchievement(achievement:"ach40T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 50 {
                        updateAchievement(achievement:"ach50T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 60 {
                        updateAchievement(achievement:"ach60T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 75 {
                        updateAchievement(achievement:"ach75T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 100 {
                        updateAchievement(achievement:"ach100T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 125 {
                        updateAchievement(achievement:"ach125T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 150 {
                        updateAchievement(achievement:"ach150T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 175 {
                        updateAchievement(achievement:"ach175T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 200 {
                        updateAchievement(achievement:"ach200T", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                    }
                }
                
                // Check for Ordinance Achievements
                switch baptismsTotal {
                case 25 ... 49:
                    updateAchievement(achievement: "ach25B", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 50 ... 99:
                    updateAchievement(achievement: "ach50B", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100B", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200B", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400B", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 800...:
                    updateAchievement(achievement: "ach800B", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                default:
                    break
                }
                
                switch initiatoriesTotal {
                case 25 ... 49:
                    updateAchievement(achievement: "ach25I", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 50 ... 99:
                    updateAchievement(achievement: "ach50I", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100I", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200I", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400I", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 800... :
                    updateAchievement(achievement: "ach800I", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                default:
                    break
                }
                
                switch endowmentsTotal {
                case 10 ... 24:
                    updateAchievement(achievement: "ach10E", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 25 ... 49:
                    updateAchievement(achievement: "ach25E", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 50 ... 99:
                    updateAchievement(achievement: "ach50E", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100E", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200E", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 400... :
                    updateAchievement(achievement: "ach400E", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                default:
                    break
                }
                
                switch sealingsTotal {
                case 50 ... 99:
                    updateAchievement(achievement: "ach50S", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100S", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200S", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400S", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 800 ... 1599:
                    updateAchievement(achievement: "ach800S", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 1600... :
                    updateAchievement(achievement: "ach1600S", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                default:
                    break
                }
                
                switch shiftHoursTotal {
                case 50 ... 99:
                    updateAchievement(achievement: "ach50W", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100W", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200W", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400W", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 800 ... 1599:
                    updateAchievement(achievement: "ach800W", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                case 1600... :
                    updateAchievement(achievement: "ach1600W", dateAchieved: visit.dateVisited!, placeAchieved: visit.holyPlace!)
                default:
                    break
                }
                
                //  Check for consecutive month achievements if ordinaces performed
                if didOrdinances {
                    let monthVisited = Int(monthFormat.string(from: visit.dateVisited!))
                    let yearVisited = yearFormat.string(from: visit.dateVisited!)
                    if (monthVisited == 1) {
                        // reset the year to year of visit
                        year = yearVisited
                        month = 1
                    }
                    if monthVisited == 12 && month == 12 && yearVisited == year {
                        // Check if all twelve months had visits
                        achievements.append(Achievement(Name: "Temple Consistent - \(yearVisited)", Details: "Ordinances completed each month", IconName: "ach12MT", Achieved: visit.dateVisited!, PlaceAchieved: visit.holyPlace!))
                        month = 0
                    }
                    if monthVisited == month + 1 && yearVisited == year {
                        // check if subsequent month has a visit and increment month
                        month += 1
                    }
                }
            }
            
            
            // Check for Historic Sites Achievement
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
            fetchRequest.sortDescriptors = [sortDescriptor]
            searchResults = try getContext().fetch(fetchRequest)
            for site in searchResults as [Visit] {
                // determine unique temples visited
                if !distinctHistoricSitesVisited.contains(site.holyPlace!) {
                    distinctHistoricSitesVisited.append(site.holyPlace!)
                    if distinctHistoricSitesVisited.count == 10 {
                        updateAchievement(achievement:"ach10H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 25 {
                        updateAchievement(achievement:"ach25H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 40 {
                        updateAchievement(achievement:"ach40H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 55 {
                        updateAchievement(achievement:"ach55H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 70 {
                        updateAchievement(achievement:"ach70H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 85 {
                        updateAchievement(achievement:"ach85H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 99 {
                        updateAchievement(achievement:"ach99H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    
                }
            }
            
            
            // divide array into achieved and not achieved
            completed = achievements.filter { if $0.achieved != nil {
                return true
            } else {
                return false
                }
            }
            notCompleted = achievements.filter { if $0.achieved == nil {
                return true
            } else {
                return false
                }
            }
            
            for achievement in notCompleted as [Achievement] {
                // Parse icon name to determine progress level
                // first remove 'ach'
                let ach = achievement.iconName.replacingOccurrences(of: "ach", with: "")
                // Get type from last letter of string
                let achType = ach.suffix(1)
                // remove type letter and convert to Float
                let achCnt = Float(ach.replacingOccurrences(of: achType, with: ""))
                // Set progress level by dividing number achived by achievement number
                switch achType {
                case "T":
                    achievement.progress = Float(distinctTemplesVisited.count)/achCnt!
                    achievement.remaining = Int(achCnt!) - distinctTemplesVisited.count
                case "H":
                    achievement.progress = Float(distinctHistoricSitesVisited.count)/achCnt!
                    achievement.remaining = Int(achCnt!) - distinctHistoricSitesVisited.count
                case "B":
                    achievement.progress = Float(baptismsTotal)/achCnt!
                    achievement.remaining = Int(achCnt!) - baptismsTotal
                case "I":
                    achievement.progress = Float(initiatoriesTotal)/achCnt!
                    achievement.remaining = Int(achCnt!) - initiatoriesTotal
                case "E":
                    achievement.progress = Float(endowmentsTotal)/achCnt!
                    achievement.remaining = Int(achCnt!) - endowmentsTotal
                case "S":
                    achievement.progress = Float(sealingsTotal)/achCnt!
                    achievement.remaining = Int(achCnt!) - sealingsTotal
                case "W":
                    achievement.progress = Float(shiftHoursTotal)/achCnt!
                    achievement.remaining = Int(achCnt!) - Int(shiftHoursTotal)
                default:
                    print("none")
                }
            }
            // sort the achievements by date achieved
            completed.sort(by: { $0.achieved?.compare(($1.achieved)!) == .orderedDescending })
            // sort the non-achievements by progress
            notCompleted.sort(by: { Int($0.progress!*100) > Int($1.progress!*100) })
            
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    // Save the Place data in CoreData
    func storePlaces () {
        let context = getContext()
        
        //retrieve the entity
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        
        //set the entity values
        for temple in allPlaces {
            // Check if Place picture is already saved locally
            fetchRequest.predicate = NSPredicate(format: "name == %@", temple.templeName)
            do {
                let searchResults = try context.fetch(fetchRequest)
                if searchResults.count > 0 {
                    for place in searchResults as [Place] {
                        place.snippet = temple.templeSnippet
                        place.address = temple.templeAddress
                        place.cityState = temple.templeCityState
                        place.country = temple.templeCountry
                        place.latitude = temple.templeLatitude
                        place.longitude = temple.templeLongitude
                        place.phone = temple.templePhone
                        if temple.templePictureURL != place.pictureURL {
                            place.pictureURL = temple.templePictureURL
                            // Delete saved picture if URL changed
                            place.pictureData = nil
                            print("Picture changed for \(temple.templeName)")
                        }
                        place.type = temple.templeType
                        place.order = temple.templeOrder
                        place.siteURL = temple.templeSiteURL
                        place.readerView = temple.readerView
                        place.infoURL = temple.infoURL
                        place.sqFt = temple.templeSqFt!
                        place.fhCode = temple.fhCode
                    }
                } else {
                    // Not found so add the new Place
                    let place =  NSEntityDescription.insertNewObject(forEntityName: "Place", into: context) as! Place
                    place.name = temple.templeName
                    place.snippet = temple.templeSnippet
                    place.address = temple.templeAddress
                    place.cityState = temple.templeCityState
                    place.country = temple.templeCountry
                    place.latitude = temple.templeLatitude
                    place.longitude = temple.templeLongitude
                    place.phone = temple.templePhone
                    place.pictureURL = temple.templePictureURL
                    place.type = temple.templeType
                    place.order = temple.templeOrder
                    place.siteURL = temple.templeSiteURL
                    place.readerView = temple.readerView
                    place.infoURL = temple.infoURL
                    place.sqFt = temple.templeSqFt!
                    place.fhCode = temple.fhCode
                    print("Added \(temple.templeName)")
                }
                //save the object
                do {
                    try context.save()
                } catch let error as NSError  {
                    print("Could not save \(error), \(error.userInfo)")
                } catch {}
                
                
            } catch {
                print("Error with request: \(error)")
            }
            
        }
        // Check for orphans
        let fetchRequest2: NSFetchRequest<Place> = Place.fetchRequest()
        do {
            //go get the results
            let searchResults2 = try getContext().fetch(fetchRequest2)
            
            // If there are more records saved than in the array populated from the xml, look for orphans
            if searchResults2.count > allPlaces.count {
                for place in searchResults2 as [Place] {
                    if !allPlaces.contains(where: { $0.templeName == place.name }) {
                        // Delete the orphan
                        print("Deleting orphaned entry of \(String(describing: place.name))")
                        context.delete(place)
                        //save the delete
                        do {
                            try context.save()
                        } catch let error as NSError  {
                            print("Could not save \(error), \(error.userInfo)")
                        } catch {}
                    }
                }
            }
        } catch {
            print("Error with request: \(error)")
        }
        print("Saving Places completed")
    }
    
    // Save the version from the HolyPlaces.xml in CoreData
    func savePlaceVersion () {
        let context = getContext()
        
        //retrieve the entity
        let entity =  NSEntityDescription.entity(forEntityName: "PlaceVersions", in: context)
        
        // Delete the existing data
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PlaceVersions")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try context.execute(request)
            print("deleting saved PlaceVersions")
        } catch let error as NSError {
            print("Could not delete \(error), \(error.userInfo)")
        }
        
        //set the entity values
        let version = NSManagedObject(entity: entity!, insertInto: context)
        version.setValue(placeDataVersion, forKey: "versionNum")
        //save the object
        do {
            try context.save()
            print("saved version")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {}
        
    }
    
    // Retrieve the version of the Place data from CoreData
    func getPlaceVersion () {
        let fetchRequest: NSFetchRequest<PlaceVersions> = PlaceVersions.fetchRequest()
        
        do {
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            //I like to check the size of the returned results!
            print ("num of results = \(searchResults.count)")
            
            //You need to convert to NSManagedObject to use 'for' loops
            for version in searchResults as [NSManagedObject] {
                placeDataVersion = version.value(forKey: "versionNum") as? String
                print("Place Data Version: " + placeDataVersion!)
            }
        } catch {
            print("Error with request: \(error)")
        }
        
    }
    
    
    // Get the Place data from CoreData and build the various Place arrays
    func getPlaces () {
        // Load from XML if first time launched.
        if placeDataVersion == nil {
            versionChecked = true
            guard let myURL = Bundle.main.url(forResource: "HolyPlaces", withExtension: "xml") else {
                print("URL not defined properly")
                return
            }
            guard let parser = XMLParser(contentsOf: myURL as URL) else {
                print("Cannot Read Data")
                //self.getPlaces()
                return
            }
            print("No internet on initial launch - loading from local XML file")
            parser.delegate = self
            if parser.parse() {
                // Save updated places to CoreData
                self.storePlaces()
            } else {
                print("Data parsing aborted")
                let error = parser.parserError!
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parser.lineNumber)")
                //self.getPlaces()
            }
        }
        //create a fetch request, telling it about the entity
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        
        do {
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            //I like to check the size of the returned results!
            print ("num of results = \(searchResults.count)")
            
            // clear out arrays
            activeTemples.removeAll()
            historical.removeAll()
            visitors.removeAll()
            construction.removeAll()
            announced.removeAll()
            allPlaces.removeAll()
            allTemples.removeAll()
            
            for place in searchResults {
                let temple = Temple(Name: place.name, Address: place.address, Snippet: place.snippet, CityState: place.cityState, Country: place.country, Phone: place.phone, Latitude: place.latitude, Longitude: place.longitude, Order: place.order, PictureURL: place.pictureURL, SiteURL: place.siteURL, Type: place.type, ReaderView: place.readerView, InfoURL: place.infoURL!, SqFt: place.sqFt, FHCode: place.fhCode)
                allPlaces.append(temple)
                switch temple.templeType {
                case "T":
                    activeTemples.append(temple)
                    allTemples.append(temple)
                case "H":
                    historical.append(temple)
                case "V":
                    visitors.append(temple)
                case "A":
                    announced.append(temple)
                    allTemples.append(temple)
                default:
                    construction.append(temple)
                    allTemples.append(temple)
                }
            }
            print("All places: " + allPlaces.count.description)
            print("Active temples: " + activeTemples.count.description)
            print("Historical sites: " + historical.count.description)
            print("Visitors' Centers: " + visitors.count.description)
            print("Under Construction: " + construction.count.description)
            print("Announced: " + announced.count.description)
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    func downloadImage() {
        let context = getContext()
        
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        
        do {
            //go get the results
            let searchResults = try context.fetch(fetchRequest)
            print("Checking for pictures to download...")
            for place in searchResults {
                // Check for picture data and skip if found
                if place.pictureData != nil {
                    continue
                }
                
                // Get picture from URL
                let pictureURL = URL(string: place.pictureURL!)!
                print("Downloading picture for \(place.name ?? "place name")...")
                URLSession.shared.dataTask(with: pictureURL) { (data, response, error) in
                    guard
                        let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                        let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                        let data = data, error == nil
                        else {
                            return
                    }
                    DispatchQueue.main.async() { () -> Void in
                        // Save image data to Pictures
                        print("Saving picture for \(place.name ?? "place name")...")
                        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "name == %@", place.name!)
                        do {
                            let searchResults = try context.fetch(fetchRequest)
                            if searchResults.count > 0 {
                                for place in searchResults as [Place] {
                                    place.pictureData = data as Data
                                    do {
                                        try context.save()
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                    } catch {}
                                }
                            }
                        } catch {
                            print("Error with request: \(error)")
                        }
                    }
                    }.resume()
            }
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "HolyData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

//******************************************************************
// MARK: - Workaround for the Xcode 11.2 bug
//******************************************************************
//@objc
//class UITextViewWorkaround : NSObject {
//
//    static func executeWorkaround() {
//        if #available(iOS 13.2, *) {
//        } else {
//            let className = "_UITextLayoutView"
//            let theClass = objc_getClass(className)
//            if theClass == nil {
//                let classPair: AnyClass? = objc_allocateClassPair(UIView.self, className, 0)
//                objc_registerClassPair(classPair!)
//            }
//        }
//    }
//
//}
