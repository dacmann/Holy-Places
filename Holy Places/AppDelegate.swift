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
//import StoreKit

enum ShortcutIdentifier: String {
    case ShowNearest
    case OpenRandomPlace
    case RecordVisit
    
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
var visitors: [Temple] = []
var placeDataVersion = String()
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

@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {
class AppDelegate: UIResponder, UIApplicationDelegate, XMLParserDelegate, CLLocationManagerDelegate {

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
    var window: UIWindow?
    var settings: Settings?
    let locationManager = CLLocationManager()
    var coordinateOfUser: CLLocation!
    var closestPlace = String()
    var shortcutAdded = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        SKPaymentQueue.default().add(self)
        
        locationManager.delegate = self
        
        // Change the font and color for the navigation Bar text
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)
        let barbuttonFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let tabBarItemFont = UIFont(name: "Baskerville", size: 12) ?? UIFont.systemFont(ofSize: 12)
        
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.font: navbarFont, NSAttributedStringKey.foregroundColor:UIColor.lead()]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: barbuttonFont, NSAttributedStringKey.foregroundColor:UIColor.ocean()], for: UIControlState.normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: barbuttonFont, NSAttributedStringKey.foregroundColor:UIColor.ocean()], for: UIControlState.highlighted)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: tabBarItemFont], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: tabBarItemFont], for: .selected)

        UINavigationBar.appearance().tintColor = UIColor.ocean()
        UITabBar.appearance().tintColor = UIColor.ocean()
        
        //Load any saved settings
        let context = persistentContainer.viewContext
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
                }
            } else {
                annualVisitGoal = 0
                // nothing to do here
            }
        } catch {
            print("Error with request: \(error)")
        }
        
        // Update Places
        refreshTemples()
        
        locationServiceSetup()
        
        return true
    }
    
    // MARK: - Location Services
    
    func locationServiceSetup() {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Location Services Allowed")
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startMonitoringSignificantLocationChanges()
                
                if shortcutAdded == false {
                    // Add Quick Launch Shortcut to record visit for nearest place
                    updateDistance(placesToUpdate: allPlaces)
                    allPlaces.sort { Int($0.distance!) < Int($1.distance!) }
                    quickLaunchItem = allPlaces[0]
                    let shortcut = UIMutableApplicationShortcutItem(type: "$(PRODUCT_BUNDLE_IDENTIFIER).RecordVisit",
                                                                    localizedTitle: "Record Visit",
                                                                    localizedSubtitle: quickLaunchItem?.templeName,
                                                                    icon: UIApplicationShortcutIcon(type: .compose),
                                                                    userInfo: nil
                    )
                    UIApplication.shared.shortcutItems = [shortcut]
                    shortcutAdded = true
                }
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    // Update the Distance in the Place data arrays based on new location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location Update")
        if locationManager.location != nil {
            coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
            
            // Update the Dynamic Quick Launch
            updateDistance(placesToUpdate: allPlaces)
            allPlaces.sort { Int($0.distance!) < Int($1.distance!) }
            quickLaunchItem = allPlaces[0]
            print("Quick Launch updated to \(allPlaces[0].templeName) with a distance of \(allPlaces[0].distance ?? 0)")
            let existingShortcutItems = UIApplication.shared.shortcutItems ?? []
            let anExistingShortcutItem = existingShortcutItems[0]
            var updatedShortcutItems = existingShortcutItems
            let aMutableShortcutItem = anExistingShortcutItem.mutableCopy() as! UIMutableApplicationShortcutItem
            aMutableShortcutItem.localizedSubtitle = quickLaunchItem?.templeName
            updatedShortcutItems[0] = aMutableShortcutItem
            UIApplication.shared.shortcutItems = updatedShortcutItems
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            print("Location Authorized")
            if locationManager.location != nil {
                coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
            }
        } else {
            print("Location not authorized")
            coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
        }
    }
    
    // Update the distances in the currently viewed array
    func updateDistance(placesToUpdate: [Temple]) {

        for place in placesToUpdate {
            if locationSpecific {
                place.distance = place.cllocation.distance(from: coordAltLocation!)
            } else {
                if coordinateOfUser == nil {
                    if locationManager.location != nil {
                        coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
                    } else {
                        coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
                    }
                }
                place.distance = place.cllocation.distance(from: coordinateOfUser!)
            }
        }
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
        case .RecordVisit:
            myTabBar.selectedIndex = 2
            guard let nvc = myTabBar.selectedViewController as? UINavigationController else {
                return false
            }
            guard let vc = nvc.viewControllers.first as? VisitTableVC else {
                return false
            }
            nvc.popToRootViewController(animated: false)
            return vc.quickAddVisit(shortcutIdentifier: shortcutIdentifier)
        }
    }

    // MARK: - Standard Events
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
        
//        SKPaymentQueue.default().remove(self)
        self.saveContext()
        
        // Add Quick Launch shortcut
        locationServiceSetup()
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
    func refreshTemples(){
        
        // Get version of saved data
        getPlaceVersion()
        
        // determine latest version from hpVersion.xml file
        guard let versionURL = NSURL(string: "http://dacworld.net/holyplaces/hpVersion.xml") else {
            print("URL not defined properly")
            return
        }
        guard let parserVersion = XMLParser(contentsOf: versionURL as URL) else {
            print("Cannot Read Data")
            getPlaces()
            return
        }
        
        parserVersion.delegate = self
        if parserVersion.parse() {
            // Version is different: grab list of temples from HolyPlaces.xml file and parse the XML
            versionChecked = true
            guard let myURL = NSURL(string: "http://dacworld.net/holyplaces/HolyPlaces.xml") else {
                print("URL not defined properly")
                return
            }
            guard let parser = XMLParser(contentsOf: myURL as URL) else {
                print("Cannot Read Data")
                getPlaces()
                return
            }
            parser.delegate = self
            if parser.parse() {
                // Save updated places to CoreData
                storePlaces()
            } else {
                print("Data parsing aborted")
                let error = parser.parserError!
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parser.lineNumber)")
                getPlaces()
            }
        } else {
            print("Data parsing aborted")
            let error = parserVersion.parserError!
            print("Error Description:\(error.localizedDescription)")
            print("Line number: \(parserVersion.lineNumber)")
            getPlaces()
        }
        checkedForUpdate = Date()
        //        checkedForUpdate = Date().addingTimeInterval(-86401.0)
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
                        allPlaces.removeAll()
                    } else {
                        break
                    }
                }
            case "ChangesDate":
                changesDate = string
            case "ChangesMsg1":
                changesMsg1 = string
            case "ChangesMsg2":
                changesMsg2 = string
            case "ChangesMsg3":
                changesMsg3 = string
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
            let temple = Temple(Name: templeName, Address: templeAddress, Snippet: templeSnippet, CityState: templeCityState, Country: templeCountry, Phone: templePhone, Latitude: templeLatitude, Longitude: templeLongitude, Order: Int16(number)!, PictureURL: templePictureURL, SiteURL: templeSiteURL,Type: templeType, ReaderView: readerView, InfoURL: infoURL, SqFt: templeSqFt)
            
            allPlaces.append(temple)
            switch templeType {
            case "T":
                activeTemples.append(temple)
            case "H":
                historical.append(temple)
            case "V":
                visitors.append(temple)
            default:
                construction.append(temple)
            }
        }
    }
    
    //MARK: - Core Data
    // Required for CoreData
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func getVisits () {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        do {
            // get temple visits
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            let searchResults = try getContext().fetch(fetchRequest)
            
            let userCalendar = Calendar.current
            var currentYearStart = DateComponents()
            currentYearStart.year = Int(currentYear)
            currentYearStart.day = 1
            currentYearStart.month = 1
            let currentYearDate = userCalendar.date(from: currentYearStart)!
            
            attended = 0
            for temple in searchResults as [NSManagedObject] {
                //print((temple.value(forKey: "dateVisited") as! Date).daysBetweenDate(toDate: Date()))
                // check for ordinaces performed in the last year
                if (temple.value(forKey: "dateVisited") as! Date).daysBetweenDate(toDate: Date()) < currentYearDate.daysBetweenDate(toDate: Date()) {
                    attended += 1
                }
            }
            
            goalProgress = "\(attended) of \(annualVisitGoal) Visits"
            // Update UserDefaults for Widget
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue(goalProgress, forKey: "goalProgress")
            
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
                placeDataVersion = version.value(forKey: "versionNum") as! String
                print("Place Data Version: " + placeDataVersion)
            }
        } catch {
            print("Error with request: \(error)")
        }
        
    }
    
    
    // Get the Place data from CoreData and build the various Place arrays
    func getPlaces () {
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
            allPlaces.removeAll()
            
            for place in searchResults {
                let temple = Temple(Name: place.name, Address: place.address, Snippet: place.snippet, CityState: place.cityState, Country: place.country, Phone: place.phone, Latitude: place.latitude, Longitude: place.longitude, Order: place.order, PictureURL: place.pictureURL, SiteURL: place.siteURL, Type: place.type, ReaderView: place.readerView, InfoURL: place.infoURL!, SqFt: place.sqFt)
                allPlaces.append(temple)
                switch temple.templeType {
                case "T":
                    activeTemples.append(temple)
                case "H":
                    historical.append(temple)
                case "V":
                    visitors.append(temple)
                default:
                    construction.append(temple)
                }
            }
            print("All places: " + allPlaces.count.description)
            print("Active temples: " + activeTemples.count.description)
            print("Historical sites: " + historical.count.description)
            print("Visitors' Centers: " + visitors.count.description)
            print("Under Construction: " + construction.count.description)
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

