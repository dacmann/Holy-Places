//
//  HomeVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/14/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import Foundation
import CoreData
//import StoreKit
import CoreLocation

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
var mapVisitedFilter = Int()
var visits = [String]()
var mapCenter = CLLocationCoordinate2D()
var mapPoint = MapPoint(title: "", coordinate: mapCenter, type: "")
var mapZoomLevel = Double()
var versionChecked = false

//class HomeVC: UIViewController, XMLParserDelegate, SKProductsRequestDelegate {
class HomeVC: UIViewController, XMLParserDelegate {
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
    var currentYear = String()
    var attended = 0
    var checkedForUpdate: Date?
    var infoURL = String()
    var templeSiteURL = String()
    var templeSqFt = Int32()
    //MARK: - Outlets & Actions
    @IBOutlet weak var info: UIButton!
    @IBOutlet weak var goal: UIButton!
    @IBOutlet weak var goalTitle: UILabel!
    
    
    @IBAction func shareHolyPlaces(_ sender: UIButton) {
        // Button to share Holy Places app
        let textToShare = "Holy Places - LDS Temples and Historic Sites by Derek Cordon"
        
        if let myWebsite = NSURL(string: "https://itunes.apple.com/us/app/holy-places-lds-temples-historic/id1200184537?mt=8") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    //MARK: - Core Data
    // Required for CoreData
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
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
    
    //MARK: - Standard Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        currentYear = formatter.string(from: Date())
        
        // Grab In-App purchase information
//        fetchProducts(matchingIdentifiers: ["GreatTip99", "GreaterTip299", "GreatestTip499"])
        
        // Update Places
        refreshTemples()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Determine if check hasn't occurred today
//        print(checkedForUpdate?.daysBetweenDate(toDate: Date()) as Any)
        if (checkedForUpdate?.daysBetweenDate(toDate: Date()))! > 0 {
            refreshTemples()
        }
        
        // Check for update and pop message
        if changesDate != "" {
            var changesMsg = changesMsg1
            if changesMsg2 != ""
            {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg2)
            }
            if changesMsg3 != ""
            {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg3)
            }
            let alert = UIAlertController(title: changesDate + " Update", message: changesMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            // clear out message now that it has been presented
            changesDate = ""
        }
        
        goalTitle.text = "\(currentYear) Goal Progress"
        // Adjust spacing of letters of Goal Progress
        let attributedString = NSMutableAttributedString(string: goalTitle.text!)
        attributedString.addAttribute(NSAttributedStringKey.kern, value: CGFloat(3.0), range: NSRange(location: 0, length: attributedString.length))
        goalTitle.attributedText = attributedString
        
        if annualVisitGoal == 0 {
            goal.setTitle("SET GOAL", for: .normal)
        } else {
            getVisits()
            goal.setTitle("\(attended) of \(annualVisitGoal) Visits", for: .normal)
        }
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
            
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    //MARK: - Update Data
    // Pull down the XML file from website and parse the data
    func refreshTemples(){
        
        // Get version of saved data
        getPlaceVersion()

        // determine latest version from hpVersion.xml file
        guard let versionURL = NSURL(string: "http://dacworld.net/holyplaces/hpVersion-test.xml") else {
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
            guard let myURL = NSURL(string: "http://dacworld.net/holyplaces/HolyPlaces-test.xml") else {
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
    //MARK: - In-App Purchases
//    var productRequest: SKProductsRequest!
//    
//    // Fetch information about your products from the App Store.
//    func fetchProducts(matchingIdentifiers identifiers: [String]) {
//        // Create a set for your product identifiers.
//        let productIdentifiers = Set(identifiers)
//        // Initialize the product request with the above set.
//        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
//        productRequest.delegate = self
//        
//        // Send the request to the App Store.
//        productRequest.start()
//    }
//    
//    // Get the App Store's response
//    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
//        // Parse products retrieved from StoreKit
//        if response.products.count > 0 {
//            // Use availableProducts to populate UI.
//            let availableProducts = response.products
//            
//            // format price for local currency
//            let formatter = NumberFormatter()
//            formatter.numberStyle = .currency
//            formatter.locale = availableProducts[0].priceLocale
//            
//            greatTip = availableProducts[0].localizedTitle + "\n" + formatter.string(from: availableProducts[0].price)!
//            greatTipPC = availableProducts[0]
//            greaterTip = availableProducts[1].localizedTitle + "\n" + formatter.string(from: availableProducts[1].price)!
//            greaterTipPC = availableProducts[1]
//            greatestTip = availableProducts[2].localizedTitle + "\n" + formatter.string(from: availableProducts[2].price)!
//            greatestTipPC = availableProducts[2]
//        }
//    }

}
