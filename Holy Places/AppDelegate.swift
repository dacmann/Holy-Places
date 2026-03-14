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
import WidgetKit
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
var annualVisitGoal = Int()
var annualBaptismGoal = Int()
var annualInitiatoryGoal = Int()
var annualEndowmentGoal = Int()
var annualSealingGoal = Int()
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
var uniqueTempleTotal = 0
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
var defaultCommentsText = "Attended with..."
var ad = AppDelegate()
var theme = "3830"
var themeChanged = false
var templeColor: UIColor = UIColor(named: "Temples"+theme) ?? UIColor.black
var historicalColor: UIColor  = UIColor(named: "Historical"+theme) ?? UIColor.black
var announcedColor: UIColor  = UIColor(named: "Announced"+theme) ?? UIColor.black
var constructionColor: UIColor  = UIColor(named: "Construction"+theme) ?? UIColor.black
var visitorCenterColor: UIColor  = UIColor(named: "VisitorCenters"+theme) ?? UIColor.black
var defaultColor: UIColor  = UIColor(named: "DefaultText") ?? UIColor.black

@main
//class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {
class AppDelegate: UIResponder, UIApplicationDelegate, XMLParserDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

    //MARK: - Variables
    var xmlParser: XMLParser!
    var eName: String = String()
    var templeId = String()
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
    var needsVisitRefresh = true
    var oldNames: [String] = []
    var oldName = String()
    let regionEntryTimesKey = "regionEntryTimes"
    
    // MARK: - Region Entry Time Persistence
    
    /// Save region entry time to UserDefaults for persistence across app termination
    func saveRegionEntryTime(regionIdentifier: String, entryTime: Date) {
        var entryTimes = UserDefaults.standard.dictionary(forKey: regionEntryTimesKey) as? [String: Date] ?? [:]
        entryTimes[regionIdentifier] = entryTime
        UserDefaults.standard.set(entryTimes, forKey: regionEntryTimesKey)
        // Also update in-memory dictionary
        monitoredRegions[regionIdentifier] = entryTime as NSDate
        print("Saved entry time for \(regionIdentifier)")
    }
    
    /// Load region entry time from UserDefaults
    func loadRegionEntryTime(regionIdentifier: String) -> Date? {
        // First check in-memory dictionary
        if let time = monitoredRegions[regionIdentifier] {
            return time as Date
        }
        // Fall back to UserDefaults (in case app was terminated)
        if let entryTimes = UserDefaults.standard.dictionary(forKey: regionEntryTimesKey) as? [String: Date] {
            return entryTimes[regionIdentifier]
        }
        return nil
    }
    
    /// Remove region entry time from UserDefaults and in-memory dictionary
    func removeRegionEntryTime(regionIdentifier: String) {
        // Remove from in-memory dictionary
        monitoredRegions.removeValue(forKey: regionIdentifier)
        // Remove from UserDefaults
        var entryTimes = UserDefaults.standard.dictionary(forKey: regionEntryTimesKey) as? [String: Date] ?? [:]
        entryTimes.removeValue(forKey: regionIdentifier)
        UserDefaults.standard.set(entryTimes, forKey: regionEntryTimesKey)
        print("Removed entry time for \(regionIdentifier)")
    }
    
    /// Restore in-memory dictionary from UserDefaults on app launch
    func restoreRegionEntryTimes() {
        if let entryTimes = UserDefaults.standard.dictionary(forKey: regionEntryTimesKey) as? [String: Date] {
            for (identifier, time) in entryTimes {
                monitoredRegions[identifier] = time as NSDate
            }
            print("Restored \(entryTimes.count) region entry times from UserDefaults")
        }
    }
    
    /// Request state for all currently monitored regions to detect if user is already inside
    /// This handles the case where the app was terminated while the user was inside a region
    func requestStateForMonitoredRegions() {
        let monitoredRegionCount = locationManager.monitoredRegions.count
        if monitoredRegionCount > 0 {
            print("Requesting state for \(monitoredRegionCount) monitored regions")
            for region in locationManager.monitoredRegions {
                locationManager.requestState(for: region)
            }
        }
    }
    
    // MARK: - Standard Events

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        SKPaymentQueue.default().add(self)
//        UITextViewWorkaround.executeWorkaround()
        
        locationManager.delegate = self
        notificationManager.delegate = self
        
        ValueTransformer.setValueTransformer(StringArrayTransformer(), forName: NSValueTransformerName("StringArrayTransformer"))
        
        // Configure tab bar appearance for iOS 15.6+
        let tabBarItemFont = UIFont(name: "Baskerville", size: 13) ?? UIFont.systemFont(ofSize: 13)
        let textAttributes = [NSAttributedString.Key.font: tabBarItemFont]
        
        let tabBarItemAppearance = UITabBarItemAppearance()
        // Hide title for normal (unselected) state, show for selected state
        tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: tabBarItemFont, NSAttributedString.Key.foregroundColor: UIColor.clear]
        tabBarItemAppearance.selected.titleTextAttributes = textAttributes
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
        
        UITabBar.appearance().tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        
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
        
        //Load any saved settings
        ad = UIApplication.shared.delegate as! AppDelegate
        
        // Get version of saved data
        getPlaceVersion()
        
        // populate place arrays
        getPlaces()
        
        // Update Places
        // letting this now be handled only from home tab
        // refreshTemples()
        
        loadSettings()
        
        // Restore persisted region entry times (in case app was terminated while user was inside a region)
        restoreRegionEntryTimes()
        
        // Request notification authorization at app launch if notifications are enabled
        // This ensures authorization is requested even if location was already authorized
        if notificationEnabled {
            notificationManager.requestAuthorization(options: [.alert, .sound]) { (permissionGranted, error) in
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                } else {
                    print("Notification authorization granted: \(permissionGranted)")
                }
            }
        }
        
        // Add Quick Launch shortcut when authorized
        let manager = CLLocationManager()
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            print("Location Services Authorized")
            locationServiceSetup()
            // Check if user is already inside any monitored regions (handles app termination case)
            requestStateForMonitoredRegions()
        }
        
        // Load quotes early for widget use
        loadSummaryQuotes()
        
        return true
    }
    
    // Load summary quotes from XML for widget
    func loadSummaryQuotes() {
        if summaryQuotes.count == 0 {
            guard let myURL = Bundle.main.url(forResource: "SummaryQuotes", withExtension: "xml") else {
                print("SummaryQuotes URL not defined properly")
                return
            }
            do {
                let xmlData = try Data(contentsOf: myURL)
                let xmlString = String(data: xmlData, encoding: .utf8) ?? ""
                
                // Simple regex-based parsing for Quote elements
                let pattern = "<Quote>(.*?)</Quote>"
                let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
                let range = NSRange(xmlString.startIndex..., in: xmlString)
                let matches = regex.matches(in: xmlString, options: [], range: range)
                
                for match in matches {
                    if let quoteRange = Range(match.range(at: 1), in: xmlString) {
                        let quote = String(xmlString[quoteRange])
                            .replacingOccurrences(of: "*", with: "\r\n")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        summaryQuotes.append(quote)
                    }
                }
                print("Loaded \(summaryQuotes.count) quotes for widget")
            } catch {
                print("Error loading SummaryQuotes: \(error)")
                summaryQuotes.append("\"The supreme benefits of membership in the Church can only be realized through the exalting ordinances of the temple.\"\r\n~ Russell M. Nelson ~")
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func loadSettings() {
        let context = ad.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        
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
                    annualBaptismGoal = Int((settings?.annualBaptismGoal)!)
                    annualInitiatoryGoal = Int((settings?.annualInitiatoryGoal)!)
                    annualEndowmentGoal = Int((settings?.annualEndowmentGoal)!)
                    annualSealingGoal = Int((settings?.annualSealingGoal)!)
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
                    defaultCommentsText = settings?.defaultCommentsText ?? "Attended with..."
                }
            } else {
                // nothing to do here
            }
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // Note: With UIScene lifecycle, most of this logic is now handled in SceneDelegate.sceneDidEnterBackground
        // This method is only called if not using scenes (iOS 12 and earlier)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        // Note: With UIScene lifecycle, this is now handled in SceneDelegate.sceneWillEnterForeground
        // This method is only called if not using scenes (iOS 12 and earlier)
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
        // Add entrance time (persisted to UserDefaults for reliability across app termination)
        let entryTime = Date()
        saveRegionEntryTime(regionIdentifier: region.identifier, entryTime: entryTime)
        print("Entered region for \(region.identifier) at \(entryTime)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // exited region
        print("Exited region for \(region.identifier) at \(Date())")
        // calculate visit time (using persisted entry time for reliability)
        if let timeEntered = loadRegionEntryTime(regionIdentifier: region.identifier) {
            visitElapsedTime = Date().timeIntervalSince(timeEntered)
            // Remove entrance time from both memory and UserDefaults
            removeRegionEntryTime(regionIdentifier: region.identifier)
            print("Visited \(region.identifier) for \(Int(visitElapsedTime!/60)) minutes")
        } else {
            // No entry record - phone may have been turned off or entry was never recorded
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
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started monitoring region: \(region.identifier)")
        // Check current state to handle case where user is already inside the region
        manager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed to monitor region: \(region?.identifier ?? "unknown") - Error: \(error.localizedDescription)")
        // Log additional details for debugging
        if let clError = error as? CLError {
            switch clError.code {
            case .regionMonitoringDenied:
                print("Region monitoring denied - check location permissions")
            case .regionMonitoringFailure:
                print("Region monitoring failure - may have exceeded 20 region limit")
            case .regionMonitoringSetupDelayed:
                print("Region monitoring setup delayed")
            default:
                print("Other CLError: \(clError.code.rawValue)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("User is currently inside region: \(region.identifier)")
            // If we don't have an entry time recorded, record it now
            if loadRegionEntryTime(regionIdentifier: region.identifier) == nil {
                saveRegionEntryTime(regionIdentifier: region.identifier, entryTime: Date())
                print("Recorded entry time for region user was already inside: \(region.identifier)")
            }
        case .outside:
            print("User is currently outside region: \(region.identifier)")
        case .unknown:
            print("User's state for region \(region.identifier) is unknown")
        @unknown default:
            print("Unknown region state")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let manager = CLLocationManager()
        switch(manager.authorizationStatus) {
        case .restricted, .denied:
            print("Access Denied/Restricted")
            UserDefaults.standard.set(false, forKey: "addVisitClosestPlace")
            UserDefaults.standard.set(true, forKey: "locationNotAllowed")
            UserDefaults.standard.set(false, forKey: "locationAllowed")
        case .notDetermined:
            print("Access Not Determined")
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location Services Allowed")
            UserDefaults.standard.set(true, forKey: "locationAllowed")
            UserDefaults.standard.set(false, forKey: "locationNotAllowed")
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
    }
    
    func locationServiceSetup() {
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // Update the Distance in the Place data arrays based on new location
    func DetermineClosest() {
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
        if !allPlaces.isEmpty {
            quickLaunchItem = allPlaces[0]
        }
        
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
        
        
        // Schedule delivery (ensure delay is at least 1 second to avoid crash/failure)
        let delayInSeconds = max(1, Int(notificationDelayInMinutes) * 60)
        let notifyTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delayInSeconds), repeats: false)
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
        // Get the window from the active scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let myTabBar = window.rootViewController as? UITabBarController else {
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

    
    //MARK: - Update Data
    // Pull down the XML file from website and parse the data
    func refreshTemples() {
            
        // Get version of saved data
        //getPlaceVersion()
        
        // determine latest version from hpVersion.xml file  --- hpVersion-v3.4
        guard let versionURL = NSURL(string: "https://dacworld.net/holyplaces/hpVersion.xml") else {
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
            
            guard let parserVersion = XMLParser(contentsOf: versionURL as URL) else {
                print("Cannot Read Data")
                //self.getPlaces()
                return
            }
            
            
            parserVersion.delegate = self
            
            if parserVersion.parse() {
                // Version is different: grab list of temples from HolyPlaces.xml file and parse the XML
                versionChecked = true
                guard let myURL = NSURL(string: "https://dacworld.net/holyplaces/HolyPlaces.xml") else {
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
                    self.newFileParsed = true
                } else {
                    print("Data parsing aborted")
                    let error = parser.parserError!
                    print("Error Description:\(error.localizedDescription)")
                    print("Line number: \(parser.lineNumber)")
                    //self.getPlaces()
                }
            } else {
                checkedForUpdate = Date()
                print("Data parsing aborted")
                let error = parserVersion.parserError!
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parserVersion.lineNumber)")
            }
        }
        // Start the download
        task.resume()
        
    }
    
    // didStartElement of parser
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        if elementName == "Place" {
            templeId = String()
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
            oldNames = []
        }
        
        if elementName == "oldName" {
            oldName = ""
        }
    }
    
    // foundCharacters of parser
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !string.isEmpty {
            switch eName {
            case "ID": templeId += string
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
            case "oldName": oldName += string
            case "Version":
                if string == placeDataVersion {
                    print("XML Data Version has not changed")
                    parser.abortParsing()
                    break
                } else {
                    print("XML Data Version has changed - \(string)")
                    if versionChecked {
                        placeDataVersion = string
                        //savePlaceVersion() - moving to same time as saving of all data updates
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
        if elementName == "oldName" {
            let trimmed = oldName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                oldNames.append(trimmed)
            }
        }

        if elementName == "Place" {
            // Extract Announced Date from snippet
            var announcedDate: Date? = nil
            let snippetLower = templeSnippet.lowercased()

            if let range = snippetLower.range(of: #"announced\s+\d{1,2}\s+[a-z]+\s+\d{4}"#, options: .regularExpression) {
                let dateStr = String(snippetLower[range]).replacingOccurrences(of: "announced ", with: "")
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMMM yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                announcedDate = formatter.date(from: dateStr.capitalized)
            }

            // Log if announced date not parsed
            if (templeType == "T" || templeType == "C" || templeType == "A") && announcedDate == nil {
                print("⚠️ Could not parse announced date for: \(templeName) — Snippet: \(templeSnippet)")
            }

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
            let temple = Temple(
                Id: templeId,
                Name: templeName,
                Address: templeAddress,
                Snippet: templeSnippet,
                CityState: templeCityState,
                Country: templeCountry,
                Phone: templePhone,
                Latitude: templeLatitude,
                Longitude: templeLongitude,
                Order: Int16(number)!,
                AnnouncedDate: announcedDate,
                PictureURL: templePictureURL,
                SiteURL: templeSiteURL,
                Type: templeType,
                ReaderView: readerView,
                InfoURL: infoURL,
                SqFt: templeSqFt,
                FHCode: fhCode
            )
            temple.oldNames = oldNames // ✅ pass collected old names
            
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
        achievements.append(Achievement(Name: "Amazing! (Endowments)", Details: "Complete 150 Endowments", IconName: "ach150E"))
        achievements.append(Achievement(Name: "Astounding! (Endowments)", Details: "Complete 200 Endowments", IconName: "ach200E"))
        achievements.append(Achievement(Name: "Phenomenal! (Endowments)", Details: "Complete 300 Endowments", IconName: "ach300E"))
        achievements.append(Achievement(Name: "Unbelievable! (Endowments)", Details: "Complete 400 Endowments", IconName: "ach400E"))
        achievements.append(Achievement(Name: "Miraculous! (Endowments)", Details: "Complete 550 Endowments", IconName: "ach550E"))
        achievements.append(Achievement(Name: "Celestial! (Endowments)", Details: "Complete 700 Endowments", IconName: "ach700E"))
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
        achievements.append(Achievement(Name: "Temple Legend", Details: "Visit 175 different temples", IconName: "ach175T"))
        achievements.append(Achievement(Name: "Temple Extremist", Details: "Visit 200 different temples", IconName: "ach200T"))
        
        // Historic Sites
        achievements.append(Achievement(Name: "History Admirer", Details: "Visit 10 different historic sites", IconName: "ach10H"))
        achievements.append(Achievement(Name: "History Lover", Details: "Visit 25 different historic sites", IconName: "ach25H"))
        achievements.append(Achievement(Name: "History Devotee", Details: "Visit 40 different historic sites", IconName: "ach40H"))
        achievements.append(Achievement(Name: "History Enthusiast", Details: "Visit 55 different historic sites", IconName: "ach55H"))
        achievements.append(Achievement(Name: "History Zealot", Details: "Visit 75 different historic sites", IconName: "ach75H"))
        achievements.append(Achievement(Name: "History Aficionado", Details: "Visit 100 different historic sites", IconName: "ach100H"))
        achievements.append(Achievement(Name: "History Buff", Details: "Visit 125 different historic sites", IconName: "ach125H"))
        achievements.append(Achievement(Name: "History Legend", Details: "Visit 150 different historic sites", IconName: "ach150H"))
        
        // Temple Consistent for current year
        achievements.append(Achievement(Name: "Temple Consistent - \(currentYear)", Details: "Ordinances completed each month", IconName: "ach12MT\(currentYear)"))
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
    
    // Compress and resize image for widget storage (max 400x400, JPEG quality 0.6)
    func compressImageForWidget(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        let maxSize: CGFloat = 400
        var newSize = image.size
        
        // Calculate new size maintaining aspect ratio
        if image.size.width > maxSize || image.size.height > maxSize {
            let widthRatio = maxSize / image.size.width
            let heightRatio = maxSize / image.size.height
            let ratio = min(widthRatio, heightRatio)
            newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        }
        
        // Use UIGraphicsImageRenderer for better color profile handling
        let renderer = UIGraphicsImageRenderer(size: newSize, format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            return format
        }())
        
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // Compress as JPEG
        return resizedImage.jpegData(compressionQuality: 0.6)
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
        var currentYearMonths = 1
        var attended = 0
        var baptisms = 0
        var initiatories = 0
        var endowments = 0
        var sealings = 0
        
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
            var needsSave = false
            var searchResults = try context.fetch(fetchRequest)
            for visit in searchResults as [Visit] {
                if visit.year == nil, let dateVisited = visit.dateVisited {
                    visit.year = yearFormat.string(from: dateVisited)
                    needsSave = true
                }
                if let placeName = visit.holyPlace {
                    visits.append(placeName)
                }
            }
            if needsSave {
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save \(error), \(error.userInfo)")
                }
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
                guard let visitDate = visit.dateVisited else { continue }
                let placeName = visit.holyPlace ?? ""
                
                if visitDate.daysBetweenDate(toDate: Date()) < currentYearDate.daysBetweenDate(toDate: Date()) {
                    if excludeNonOrdinanceVisits {
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
                if latestTempleVisited == "" {
                    latestTempleVisited = placeName
                    dateLastVisited = formatter.string(from: visitDate)
                }
            }
            goalProgress = ""
            if Int(annualVisitGoal) > 0 {
                goalProgress = "\(attended) of \(annualVisitGoal) Visits\n"
            }
            if Int(annualBaptismGoal) > 0 {
                goalProgress += "\(baptisms) of \(annualBaptismGoal) Bapt/Conf\n"
            }
            if Int(annualInitiatoryGoal) > 0 {
                goalProgress += "\(initiatories) of \(annualInitiatoryGoal) Initiatories\n"
            }
            if Int(annualEndowmentGoal) > 0 {
                goalProgress += "\(endowments) of \(annualEndowmentGoal) Endowments\n"
            }
            if Int(annualSealingGoal) > 0 {
                goalProgress += "\(sealings) of \(annualSealingGoal) Sealings"
            }
            if goalProgress == "" {
                goalProgress = "SET GOAL"
            }
            
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
                if let pictureData = visit.picture {
                    homeVisitPictureData = pictureData
                }
                if let visitDate = visit.dateVisited {
                    homeVisitDate = formatter.string(from: visitDate)
                }
            }
            
            // NEW: Save widget image data on background thread to avoid UI lag
            // First, capture the data we need from Core Data (must be on main thread)
            var favoriteVisits: [(picture: Data, placeName: String, date: String, dateVisited: Date, visitObjectID: String)] = []
            var regularVisits: [(picture: Data, placeName: String, date: String, dateVisited: Date, visitObjectID: String)] = []
            
            for visit in searchResults as [Visit] {
                if let pictureData = visit.picture, let dateVisited = visit.dateVisited {
                    let visitObjectID = visit.objectID.uriRepresentation().absoluteString
                    let visitData = (
                        picture: pictureData,
                        placeName: visit.holyPlace ?? "",
                        date: formatter.string(from: dateVisited),
                        dateVisited: dateVisited,
                        visitObjectID: visitObjectID
                    )
                    
                    // Prioritize favorites
                    if visit.isFavorite {
                        favoriteVisits.append(visitData)
                    } else {
                        regularVisits.append(visitData)
                    }
                }
            }
            
            // Sort both arrays by date (most recent first)
            favoriteVisits.sort { $0.dateVisited > $1.dateVisited }
            regularVisits.sort { $0.dateVisited > $1.dateVisited }
            
            // Combine: favorites first, then regular visits, limit to 30
            var visitDataForWidget: [(picture: Data, placeName: String, date: String, visitObjectID: String)] = []
            visitDataForWidget.append(contentsOf: favoriteVisits.map { ($0.picture, $0.placeName, $0.date, $0.visitObjectID) })
            visitDataForWidget.append(contentsOf: regularVisits.map { ($0.picture, $0.placeName, $0.date, $0.visitObjectID) })
            visitDataForWidget = Array(visitDataForWidget.prefix(30))
            
            // Fetch place data for widget (including last visited date)
            // Build a lookup of latest visit date per place with a single query
            var latestVisitByPlace: [String: Date] = [:]
            let allVisitsRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            allVisitsRequest.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
            if let allVisitsResults = try? getContext().fetch(allVisitsRequest) {
                for v in allVisitsResults {
                    guard let name = v.holyPlace, let date = v.dateVisited else { continue }
                    if latestVisitByPlace[name] == nil {
                        latestVisitByPlace[name] = date
                    }
                }
            }
            
            // Exclude announced temples (type=A)
            let placeRequest: NSFetchRequest<Place> = Place.fetchRequest()
            placeRequest.predicate = NSPredicate(format: "pictureData != nil AND (type != %@ OR type == nil)", "A")
            var placeDataForWidget: [(picture: Data, placeName: String, lastVisited: String)] = []
            if let placesWithImages = try? getContext().fetch(placeRequest) {
                for place in placesWithImages {
                    if let pictureData = place.pictureData, let placeName = place.name {
                        var lastVisitedStr = "Not yet visited"
                        if let visitDate = latestVisitByPlace[placeName] {
                            lastVisitedStr = formatter.string(from: visitDate)
                        }
                        placeDataForWidget.append((
                            picture: pictureData,
                            placeName: placeName,
                            lastVisited: lastVisitedStr
                        ))
                    }
                }
            }
            // Randomly select 30 place images
            if placeDataForWidget.count > 30 {
                placeDataForWidget.shuffle()
                placeDataForWidget = Array(placeDataForWidget.prefix(30))
            }
            
            // Process images on background thread
            DispatchQueue.global(qos: .utility).async {
                let sharedDefaults = UserDefaults(suiteName: "group.net.dacworld.holyplaces")
                
                // Compress visit photos
                var visitPhotoArray: [[String: Any]] = []
                for visitData in visitDataForWidget {
                    if let compressedData = self.compressImageForWidget(visitData.picture) {
                        visitPhotoArray.append([
                            "picture": compressedData.base64EncodedString(),
                            "placeName": visitData.placeName,
                            "date": visitData.date,
                            "visitObjectID": visitData.visitObjectID
                        ])
                    }
                }
                if let encoded = try? JSONSerialization.data(withJSONObject: visitPhotoArray) {
                    sharedDefaults?.setValue(encoded, forKey: "widgetVisitPhotos")
                }
                
                // Compress place images
                var placeImageArray: [[String: Any]] = []
                for placeData in placeDataForWidget {
                    if let compressedData = self.compressImageForWidget(placeData.picture) {
                        placeImageArray.append([
                            "picture": compressedData.base64EncodedString(),
                            "placeName": placeData.placeName,
                            "date": placeData.lastVisited
                        ])
                    }
                }
                if let encoded = try? JSONSerialization.data(withJSONObject: placeImageArray) {
                    sharedDefaults?.setValue(encoded, forKey: "widgetPlaceImages")
                }
                
                // Reload widgets (can be called from background thread)
                WidgetCenter.shared.reloadAllTimelines()
            }
            
            // Achievements
            fetchRequest.predicate = NSPredicate(format: "type == %@ OR type == %@", "T", "C")
            sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            searchResults = try getContext().fetch(fetchRequest)
            
            for visit in searchResults as [Visit] {
                guard let visitDate = visit.dateVisited else { continue }
                let placeName = visit.holyPlace ?? ""
                
                sealingsTotal += Int(visit.sealings)
                endowmentsTotal += Int(visit.endowments)
                initiatoriesTotal += Int(visit.initiatories)
                confirmationsTotal += Int(visit.confirmations)
                baptismsTotal += Int(visit.baptisms)
                shiftHoursTotal += visit.shiftHrs
                
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
                
                if !distinctTemplesVisited.contains(placeName) {
                    distinctTemplesVisited.append(placeName)
                    if distinctTemplesVisited.count == 10 {
                        updateAchievement(achievement:"ach10T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 20 {
                        updateAchievement(achievement:"ach20T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 30 {
                        updateAchievement(achievement:"ach30T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 40 {
                        updateAchievement(achievement:"ach40T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 50 {
                        updateAchievement(achievement:"ach50T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 60 {
                        updateAchievement(achievement:"ach60T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 75 {
                        updateAchievement(achievement:"ach75T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 100 {
                        updateAchievement(achievement:"ach100T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 125 {
                        updateAchievement(achievement:"ach125T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 150 {
                        updateAchievement(achievement:"ach150T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 175 {
                        updateAchievement(achievement:"ach175T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                    if distinctTemplesVisited.count == 200 {
                        updateAchievement(achievement:"ach200T", dateAchieved: visitDate, placeAchieved: placeName)
                    }
                }
                
                if baptismsTotal >= 25 {
                    updateAchievement(achievement: "ach25B", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if baptismsTotal >= 50 {
                    updateAchievement(achievement: "ach50B", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if baptismsTotal >= 100 {
                    updateAchievement(achievement: "ach100B", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if baptismsTotal >= 200 {
                    updateAchievement(achievement: "ach200B", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if baptismsTotal >= 400 {
                    updateAchievement(achievement: "ach400B", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if baptismsTotal >= 800 {
                    updateAchievement(achievement: "ach800B", dateAchieved: visitDate, placeAchieved: placeName)
                }
                
                if initiatoriesTotal >= 25 {
                    updateAchievement(achievement: "ach25I", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if initiatoriesTotal >= 50 {
                    updateAchievement(achievement: "ach50I", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if initiatoriesTotal >= 100 {
                    updateAchievement(achievement: "ach100I", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if initiatoriesTotal >= 200 {
                    updateAchievement(achievement: "ach200I", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if initiatoriesTotal >= 400 {
                    updateAchievement(achievement: "ach400I", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if initiatoriesTotal >= 800 {
                    updateAchievement(achievement: "ach800I", dateAchieved: visitDate, placeAchieved: placeName)
                }
                
                if endowmentsTotal >= 10 {
                    updateAchievement(achievement: "ach10E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 25 {
                    updateAchievement(achievement: "ach25E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 50 {
                    updateAchievement(achievement: "ach50E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 100 {
                    updateAchievement(achievement: "ach100E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 150 {
                    updateAchievement(achievement: "ach150E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 200 {
                    updateAchievement(achievement: "ach200E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 300 {
                    updateAchievement(achievement: "ach300E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 400 {
                    updateAchievement(achievement: "ach400E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 550 {
                    updateAchievement(achievement: "ach550E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if endowmentsTotal >= 700 {
                    updateAchievement(achievement: "ach700E", dateAchieved: visitDate, placeAchieved: placeName)
                }
                
                if sealingsTotal >= 50 {
                    updateAchievement(achievement: "ach50S", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if sealingsTotal >= 100 {
                    updateAchievement(achievement: "ach100S", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if sealingsTotal >= 200 {
                    updateAchievement(achievement: "ach200S", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if sealingsTotal >= 400 {
                    updateAchievement(achievement: "ach400S", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if sealingsTotal >= 800 {
                    updateAchievement(achievement: "ach800S", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if sealingsTotal >= 1600 {
                    updateAchievement(achievement: "ach1600S", dateAchieved: visitDate, placeAchieved: placeName)
                }
                
                if shiftHoursTotal >= 50 {
                    updateAchievement(achievement: "ach50W", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if shiftHoursTotal >= 100 {
                    updateAchievement(achievement: "ach100W", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if shiftHoursTotal >= 200 {
                    updateAchievement(achievement: "ach200W", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if shiftHoursTotal >= 400 {
                    updateAchievement(achievement: "ach400W", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if shiftHoursTotal >= 800 {
                    updateAchievement(achievement: "ach800W", dateAchieved: visitDate, placeAchieved: placeName)
                }
                if shiftHoursTotal >= 1600 {
                    updateAchievement(achievement: "ach1600W", dateAchieved: visitDate, placeAchieved: placeName)
                }
                
                if didOrdinances {
                    let monthVisited = Int(monthFormat.string(from: visitDate))
                    let yearVisited = yearFormat.string(from: visitDate)
                    if (monthVisited == 1) {
                        year = yearVisited
                        month = 1
                    }
                    if monthVisited == month + 1 && yearVisited == year {
                        month += 1
                    }
                    if monthVisited == 12 && month == 12 && yearVisited == year {
                        achievements.append(Achievement(Name: "Temple Consistent - \(yearVisited)", Details: "Ordinances completed each month", IconName: "ach12MT\(yearVisited)", Achieved: visitDate, PlaceAchieved: placeName))
                        month = 0
                    }
                    if monthVisited == currentYearMonths + 1 && yearVisited == currentYear {
                        currentYearMonths += 1
                    }
                }
            }
            
            
            // Check for Historic Sites Achievement
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
            fetchRequest.sortDescriptors = [sortDescriptor]
            searchResults = try getContext().fetch(fetchRequest)
            for site in searchResults as [Visit] {
                guard let siteDate = site.dateVisited else { continue }
                let siteName = site.holyPlace ?? ""
                
                if !distinctHistoricSitesVisited.contains(siteName) {
                    distinctHistoricSitesVisited.append(siteName)
                    if distinctHistoricSitesVisited.count == 10 {
                        updateAchievement(achievement:"ach10H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 25 {
                        updateAchievement(achievement:"ach25H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 40 {
                        updateAchievement(achievement:"ach40H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 55 {
                        updateAchievement(achievement:"ach55H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 75 {
                        updateAchievement(achievement:"ach75H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 100 {
                        updateAchievement(achievement:"ach100H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 125 {
                        updateAchievement(achievement:"ach125H", dateAchieved: siteDate, placeAchieved: siteName)
                    }
                    if distinctHistoricSitesVisited.count == 150 {
                        updateAchievement(achievement:"ach150H", dateAchieved: siteDate, placeAchieved: siteName)
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
                    // Temple Consistent
                    if (currentYearMonths + 1 < Int(monthFormat.string(from: Date()))!) {
                        // Achievement failed for this year so remove it from Not Completed Progress
                        if let location = notCompleted.firstIndex(where:{$0.iconName == "ach12MT\(currentYear)"}) {
                            // Only update if not already achieved
                            notCompleted.remove(atOffsets: IndexSet(integer: location))
                        }
                    } else {
                        achievement.progress = Float(currentYearMonths)/12
                        achievement.remaining = 12 - Int(currentYearMonths)
                    }
                    
                }
            }
            // sort the achievements by date achieved, then by achievement level (higher first) when dates are equal
            completed.sort(by: {
                let dateComparison = $0.achieved?.compare(($1.achieved)!)
                if dateComparison == .orderedSame {
                    // Extract achievement number from iconName (e.g., "ach50B" -> 50)
                    let num0 = Int($0.iconName.replacingOccurrences(of: "ach", with: "").dropLast()) ?? 0
                    let num1 = Int($1.iconName.replacingOccurrences(of: "ach", with: "").dropLast()) ?? 0
                    return num0 > num1
                }
                return dateComparison == .orderedDescending
            })
            // sort the non-achievements by progress
            notCompleted.sort(by: { Int($0.progress!*100) > Int($1.progress!*100) })
            
            // Save achievement and quote widget data on background thread
            let achIconName = completed.first?.iconName ?? "ach10T"
            let achName = completed.first?.name ?? ""
            let capturedQuotes = summaryQuotes
            DispatchQueue.global(qos: .utility).async {
                let sharedDefaultsAch = UserDefaults(suiteName: "group.net.dacworld.holyplaces")
                sharedDefaultsAch?.setValue(achIconName, forKey: "widgetAchievementIcon")
                sharedDefaultsAch?.setValue(achName, forKey: "widgetAchievementName")
                
                let shortQuotes = capturedQuotes.filter { $0.count <= 200 }
                if !shortQuotes.isEmpty {
                    if let quotesData = try? JSONEncoder().encode(shortQuotes) {
                        sharedDefaultsAch?.setValue(quotesData, forKey: "widgetQuotes")
                    }
                } else if !capturedQuotes.isEmpty {
                    let truncatedQuotes = capturedQuotes.map { quote -> String in
                        if quote.count <= 200 { return quote }
                        return String(quote.prefix(197)) + "..."
                    }
                    if let quotesData = try? JSONEncoder().encode(truncatedQuotes) {
                        sharedDefaultsAch?.setValue(quotesData, forKey: "widgetQuotes")
                    }
                }
                
                WidgetCenter.shared.reloadAllTimelines()
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        needsVisitRefresh = false
    }
    
    // Save the Place data in CoreData
    func storePlaces () {
        let context = getContext()
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        var renamedVisits = false // ✅ Track if any visits were updated

        for temple in allPlaces {
            // Match by name first
            fetchRequest.predicate = NSPredicate(format: "name == %@", temple.templeName)
            do {
                var searchResults = try context.fetch(fetchRequest)

                if searchResults.isEmpty {
                    // No match by name, try matching by old name
                    for oldName in temple.oldNames {
                        fetchRequest.predicate = NSPredicate(format: "name == %@", oldName)
                        let legacyMatches = try context.fetch(fetchRequest)
                        if let matchedPlace = legacyMatches.first {
                            print("⤴️ Name changed from \(matchedPlace.name ?? "?") to \(temple.templeName)")
                            matchedPlace.name = temple.templeName
                            matchedPlace.placeID = temple.templeId

                            // ✅ Update visits using this old name
                            let visitFetch: NSFetchRequest<Visit> = Visit.fetchRequest()
                            visitFetch.predicate = NSPredicate(format: "holyPlace == %@", oldName)
                            let matchedVisits = try context.fetch(visitFetch)
                            for visit in matchedVisits {
                                visit.holyPlace = temple.templeName
                                renamedVisits = true
                                print("🔁 Renamed visit from \(oldName) to \(temple.templeName)")
                            }

                            searchResults = [matchedPlace] // treat as found
                            break
                        }
                    }
                }

                if searchResults.count > 0 {
                    for place in searchResults {
                        place.placeID = temple.templeId
                        place.snippet = temple.templeSnippet
                        place.address = temple.templeAddress
                        place.cityState = temple.templeCityState
                        place.country = temple.templeCountry
                        place.latitude = temple.templeLatitude
                        place.longitude = temple.templeLongitude
                        place.phone = temple.templePhone
                        if temple.templePictureURL != place.pictureURL {
                            place.pictureURL = temple.templePictureURL
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
                        place.setValue(Array(Set(temple.oldNames)), forKey: "oldNames")
                        
                        // ✅ Proactively rename visits using old names (even if Place already existed)
                        for oldName in temple.oldNames {
                            if oldName != temple.templeName {
                                let visitFetch: NSFetchRequest<Visit> = Visit.fetchRequest()
                                visitFetch.predicate = NSPredicate(format: "holyPlace == %@", oldName)
                                let matchedVisits = try context.fetch(visitFetch)
                                for visit in matchedVisits {
                                    print("🔁 Proactively renamed visit from \(oldName) to \(temple.templeName)")
                                    visit.holyPlace = temple.templeName
                                    renamedVisits = true
                                }
                            }
                        }
                    }
                } else {
                    // Not found by name or old name, so insert new
                    let place = NSEntityDescription.insertNewObject(forEntityName: "Place", into: context) as! Place
                    place.placeID = temple.templeId
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
                    place.setValue(Array(Set(temple.oldNames)), forKey: "oldNames")
                    print("Added \(temple.templeName)")
                }

                try context.save()
            } catch {
                print("Error with request or saving: \(error)")
            }
        }

        // Orphan cleanup
        let fetchRequest2: NSFetchRequest<Place> = Place.fetchRequest()
        do {
            let searchResults2 = try context.fetch(fetchRequest2)
            if searchResults2.count > allPlaces.count {
                for place in searchResults2 {
                    if !allPlaces.contains(where: { $0.templeName == place.name }) {
                        print("Deleting orphaned entry of \(place.name ?? "unknown")")
                        context.delete(place)
                    }
                }
                try context.save()
            }
        } catch {
            print("Error during orphan cleanup: \(error)")
        }

        print("Saving Places completed")
        downloadImage()

        // ✅ Re-run getVisits() if any visit names were updated
        if renamedVisits {
            print("🔁 Temple names updated. Reloading visits...")
            getVisits()
        }
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
                return
            }
            print("Initial launch - loading from local XML file")
            parser.delegate = self
            if parser.parse() {
                // Save updated places to CoreData
                storePlaces()
                savePlaceVersion()
            } else {
                print("Data parsing aborted")
                let error = parser.parserError!
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parser.lineNumber)")
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
                var announcedDate: Date? = nil
                let snippetLower = (place.snippet ?? "").lowercased()

                if let range = snippetLower.range(of: #"announced\s+\d{1,2}\s+[a-z]+\s+\d{4}"#, options: .regularExpression) {
                    let dateStr = String(snippetLower[range]).replacingOccurrences(of: "announced ", with: "")
                    let formatter = DateFormatter()
                    formatter.dateFormat = "d MMMM yyyy"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    announcedDate = formatter.date(from: dateStr.capitalized)
                }

                // Optional logging
                if ["T", "C", "A"].contains(place.type ?? "") && announcedDate == nil {
                    print("⚠️ Could not parse announced date for: \(place.name ?? "?") — Snippet: \(place.snippet ?? "nil")")
                }

                let temple = Temple(
                    Id: place.placeID ?? "",
                    Name: place.name,
                    Address: place.address,
                    Snippet: place.snippet,
                    CityState: place.cityState,
                    Country: place.country,
                    Phone: place.phone,
                    Latitude: place.latitude,
                    Longitude: place.longitude,
                    Order: place.order,
                    AnnouncedDate: announcedDate,
                    PictureURL: place.pictureURL,
                    SiteURL: place.siteURL,
                    Type: place.type,
                    ReaderView: place.readerView,
                    InfoURL: place.infoURL ?? "",
                    SqFt: place.sqFt,
                    FHCode: place.fhCode
                )
                temple.oldNames = (place.oldNames as? [String]) ?? []
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
                //print("Downloading picture for \(place.name ?? "place name")...")
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
                        //print("Saving picture for \(place.name ?? "place name")...")
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
        let context = self.persistentContainer.viewContext
        
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
