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
import CoreLocation

var allPlaces: [Temple] = []
var activeTemples: [Temple] = []
var historical: [Temple] = []
var construction: [Temple] = []
var visitors: [Temple] = []

class HomeVC: UIViewController, XMLParserDelegate, CLLocationManagerDelegate {

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
    var placeDataVersion = String()
    var templeSiteURL = String()
    
    var locationManager: CLLocationManager!
    var coordinateOfUser: CLLocation!
    
    @IBOutlet weak var info: UIButton!
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func storePlaces () {
        let context = getContext()
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try context.execute(request)
            print("deleting saved Places")
        } catch let error as NSError {
            print("Could not delete \(error), \(error.userInfo)")
        }
        
        //retrieve the entity
        let entity =  NSEntityDescription.entity(forEntityName: "Place", in: context)
        
        //set the entity values
        for temple in allPlaces {
            let place = NSManagedObject(entity: entity!, insertInto: context)
            place.setValue(temple.templeName, forKey: "name")
            place.setValue(temple.templeSnippet, forKey: "snippet")
            place.setValue(temple.templeAddress, forKey: "address")
            place.setValue(temple.templeCityState, forKey: "cityState")
            place.setValue(temple.templeCountry, forKey: "country")
            place.setValue(temple.templeLatitude, forKey: "latitude")
            place.setValue(temple.templeLongitude, forKey: "longitude")
            place.setValue(temple.templePhone, forKey: "phone")
            place.setValue(temple.templePictureURL, forKey: "pictureURL")
            place.setValue(temple.templeType, forKey: "type")
            place.setValue(temple.templeOrder, forKey: "order")
            place.setValue(temple.templeSiteURL, forKey: "siteURL")
            //save the object
            do {
                try context.save()
                //print("saved " + temple.templeName)
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            } catch {}
        }
        print("Saving Places completed")
    }
    
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        getPlaces()
    }
    
    func getPlaces () {
        //create a fetch request, telling it about the entity
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        
        do {
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            //I like to check the size of the returned results!
            print ("num of results = \(searchResults.count)")
            
            //You need to convert to NSManagedObject to use 'for' loops
            for place in searchResults as [NSManagedObject] {
                let latitude = place.value(forKey: "latitude") as! Double
                let longitude = place.value(forKey: "longitude") as! Double
                let temple = Temple(Name: place.value(forKey: "name") as! String, Address: place.value(forKey: "address") as! String, Snippet: place.value(forKey: "snippet") as! String, CityState: place.value(forKey: "cityState") as! String, Country: place.value(forKey: "country") as! String, Phone: place.value(forKey: "phone") as! String, Latitude: latitude, Longitude: latitude, Order: place.value(forKey: "order") as! Int16, PictureURL: place.value(forKey: "pictureURL") as! String, SiteURL: place.value(forKey: "siteURL") as! String, Type: place.value(forKey: "type") as! String, distance: CLLocation(latitude: latitude, longitude: longitude).distance(from: coordinateOfUser))
                allPlaces.append(temple)
                //print("\(place.value(forKey: "order"))")
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
    
    func refreshTemples(){
        
        // Get version of saved data
        getPlaceVersion()
        
        // grab list of temples from LDSCHurchTemples.kml file and parse the XML
        guard let myURL = NSURL(string: "http://dacworld.net/Files/HolyPlaces.xml") else {
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
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        
        
        // Check if the user allowed authorization
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse) {
            //print(locationManager.location!)
            print("Latitude: " + (locationManager.location?.coordinate.latitude.description)!)
            print("Longitude: " + (locationManager.location?.coordinate.longitude.description)!)
            coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        } else {
            print("Location not authorized")
            coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
        }

        // Do any additional setup after loading the view.
        refreshTemples()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if (!string.isEmpty){
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
            case "Version":
                if (string == placeDataVersion) {
                    print("XML Data Version has not changed")
                    parser.abortParsing()
                    break
                } else {
                    placeDataVersion = string
                    print("XML Data Version has changed - " + placeDataVersion)
                    savePlaceVersion()
                }
            default: return
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName == "Place"){
            // Determine Order
            let digits = CharacterSet.decimalDigits
            
            var number = String()
            
            for uni in templeSnippet.unicodeScalars {
                if digits.contains(uni) {
                    number += uni.escaped(asASCII: true)
                } else {
                    if (number == ""){
                        number = "200"
                    }
                    break
                }
            }
            let temple = Temple(Name: templeName, Address: templeAddress, Snippet: templeSnippet, CityState: templeCityState, Country: templeCountry, Phone: templePhone, Latitude: templeLatitude, Longitude: templeLongitude, Order: Int16(number)!, PictureURL: templePictureURL, SiteURL: templeSiteURL,Type: templeType, distance: CLLocation( latitude: templeLatitude, longitude: templeLongitude).distance(from: coordinateOfUser))
            
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
