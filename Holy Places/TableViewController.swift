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
    
    var sections : [(index: Int, length :Int, title: String)] = Array()
    
    func refreshTemples(){
        // grab list of temples from LDSCHurchTemples.kml file and parse the XML
        guard let myURL = NSURL(string: "http://dacworld.net/Files/HolyPlaces.xml") else {
            print("URL not defined properly")
            return
        }
        guard let parser = XMLParser(contentsOf: myURL as URL) else {
            print("Cannot Read Data")
            return
        }
        parser.delegate = self
        if !parser.parse(){
            print("Data Errors Exist:")
            let error = parser.parserError!
            print("Error Description:\(error.localizedDescription)")
            print("Line number: \(parser.lineNumber)")
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
