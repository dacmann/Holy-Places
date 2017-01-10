//
//  TableViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController, XMLParserDelegate {
    
    var xmlParser: XMLParser!
    var temples: [Temple] = []
    var eName: String = String()
    var templeName = String()
    var templeAddress = String()
    var templeSnippet = String()
    var templeDescription = String()
    var templeLatitude = String()
    var templeLongitude = String()
        
    func refreshTemples(){
        
        guard let myURL = NSURL(string: "http://dacworld.net/Files/LDSChurchTemples.kml") else {
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

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshTemples()
        tableView.contentInset.top = 20
        tableView.scrollIndicatorInsets.top = 20

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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return temples.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let temple = temples[indexPath.row]
        
        cell.textLabel?.text = temple.templeName
        cell.detailTextLabel?.text = temple.templeSnippet

        return cell
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        if elementName == "Placemark" {
            templeName = String()
            templeAddress = String()
            templeSnippet = String()
            templeDescription = String()
            templeLatitude = String()
            templeLongitude = String()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if (!string.isEmpty){
            switch eName {
            case "name": templeName += string
            case "address": templeAddress += string
            case "Snippet": templeSnippet += string
            case "description": templeDescription += string
            case "latitude": templeLatitude += string
            case "longitude": templeLongitude += string
            default: return
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName == "Placemark"){
            let temple = Temple()
            temple.templeName = templeName
            temple.templeSnippet = templeSnippet
            temple.templeAddress = templeAddress
            temple.templeDescription = templeDescription
            temple.templeLatitude = templeLatitude
            temple.templeLongitude = templeLongitude
            
            temples.append(temple)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let temple = temples[indexPath.row]
                let controller = (segue.destination as! DetailViewController)
                controller.detailItem = temple
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

}
