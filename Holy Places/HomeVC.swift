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

var temples: [Temple] = []

class HomeVC: UIViewController, XMLParserDelegate {

    var xmlParser: XMLParser!
    var eName: String = String()
    var templeName = String()
    var templeAddress = String()
    var templeSnippet = String()
    var templeCityState = String()
    var templeCountry = String()
    var templePhone = String()
    var templeLatitude = String()
    var templeLongitude = String()
    var templePictureURL = String()
    var templeType = String()
    var placeDataVersion = String()
    
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
        for temple in temples {
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
                let temple = Temple()
                temple.templeName = place.value(forKey: "name") as! String
                temple.templeSnippet = place.value(forKey: "snippet") as! String
                temple.templeAddress = place.value(forKey: "address") as! String
                temple.templeCityState = place.value(forKey: "cityState") as! String
                temple.templeCountry = place.value(forKey: "country") as! String
                temple.templePhone = place.value(forKey: "phone") as! String
                temple.templeLatitude = place.value(forKey: "latitude") as! String
                temple.templeLongitude = place.value(forKey: "longitude") as! String
                temple.templePictureURL = place.value(forKey: "pictureURL") as! String
                temple.templeType = place.value(forKey: "type") as! String
                temple.templeOrder = place.value(forKey: "order") as! Int16
                temples.append(temple)
                //print("\(place.value(forKey: "order"))")
            }
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
            templeLatitude = String()
            templeLongitude = String()
            templePictureURL = String()
            templeType = String()
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
            case "latitude": templeLatitude += string
            case "longitude": templeLongitude += string
            case "lct_img": templePictureURL += string
            case "type": templeType += string
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
            let temple = Temple()
            temple.templeName = templeName
            temple.templeSnippet = templeSnippet
            temple.templeAddress = templeAddress
            temple.templeCityState = templeCityState
            temple.templeCountry = templeCountry
            temple.templePhone = templePhone
            temple.templeLatitude = templeLatitude
            temple.templeLongitude = templeLongitude
            temple.templePictureURL = templePictureURL
            temple.templeType = templeType
            
            // Determine Order
            let digits = CharacterSet.decimalDigits
            
            var number = String()
            
            for uni in temple.templeSnippet.unicodeScalars {
                if digits.contains(uni) {
                    number += uni.escaped(asASCII: true)
                } else {
                    if (number == ""){
                        number = "200"
                    }
                    break
                }
            }
            //print(number)
            temple.templeOrder = Int16(number)!
            
            temples.append(temple)
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
