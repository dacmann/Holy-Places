//
//  TableViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class TableViewController: UITableViewController, XMLParserDelegate {
    
    var xmlParser: XMLParser!
    var temples: [Temple] = []
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
    
    var sections : [(index: Int, length :Int, title: String)] = Array()
    
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
                print("saved " + temple.templeName)
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            } catch {
                
            }
        }

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
        
        // Sort by
        //temples.sort { $0.templeOrder < $1.templeOrder }
        
        //create index for array
        var index = 0
        var commonPrefix = ""
        for i in (0 ..< (temples.count + 1) ) {
            if (temples.count != i){
                commonPrefix = temples[i].templeName.commonPrefix(with: temples[index].templeName, options: .caseInsensitive)
            }
            //print(temples.count)
            if ( commonPrefix.isEmpty || temples.count == i) {
                let string = temples[index].templeName.uppercased();
                let firstCharacter = string[string.startIndex]
                let title = "\(firstCharacter)"
                let newSection = (index: index, length: i - index, title: title)
                sections.append(newSection)
                index = i;
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshTemples()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].length
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let temple = temples[sections[indexPath.section].index + indexPath.row]
        
        cell.textLabel?.text = temple.templeName
        cell.detailTextLabel?.text = temple.templeSnippet

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections.map {$0.title}
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
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
                    placeDataVersion += string
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
                        number = "1000"
                    }
                    break
                }
            }
            //print(number)
            temple.templeOrder = Int16(number)!
            
            temples.append(temple)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let temple = temples[sections[indexPath.section].index + indexPath.row]
                let controller = (segue.destination as! DetailViewController)
                controller.detailItem = temple
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

}
