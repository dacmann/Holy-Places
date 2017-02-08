//
//  TableViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreLocation

class TableViewController: UITableViewController, SendOptionsDelegate, CLLocationManagerDelegate {
    
    var places: [Temple] = []
    var placeType = Int()
    var sortType = Int()
    var nearestEnabled = Bool()
    var sortByCountry = Bool()
    var sections : [(index: Int, length :Int, title: String)] = Array()
    var locationManager: CLLocationManager!
    var coordinateOfUser: CLLocation!
    
    // Set variable based Filter Option selected on Options view
    func FilterOptions(row: Int) {
        placeType = row
    }
    
    // Set variables based on Sort Option selected on Options view
    func SortOptions(row: Int) {
        sortType = row
        nearestEnabled = false
        sortByCountry = false
        if sortType == 1 {
            nearestEnabled = true
        } else if sortType == 2 {
            sortByCountry = true
        }
    }
    
    // Determine Filters and sort criteria and build indexes if required
    func setup () {
                
        //print(placeType)
        switch placeType {
        case 0:
            self.navigationItem.title = "Holy Places"
            places = allPlaces
        case 1:
            self.navigationItem.title = "Active Temples"
            places = activeTemples
        case 2:
            self.navigationItem.title = "Historical Sites"
            places = historical
        case 3:
            self.navigationItem.title = "Visitors' Centers"
            places = visitors
        default:
            self.navigationItem.title = "Temples Under Construction"
            places = construction
        }
        
        // Sort by
        //temples.sort { $0.templeOrder < $1.templeOrder }
        
        //reset sections array
        sections.removeAll()
        
        //create index for array
        var index = 0
        if nearestEnabled {
            updateDistance()
            places.sort { Int($0.distance!) < Int($1.distance!) }
            let newSection = (index: 1, length: places.count, title: "")
            sections.append(newSection)
        } else if sortByCountry {
            // Sort by Country and then by Name
            places.sort {
                let countryComparisonResult = $0.templeCountry.compare($1.templeCountry)
                if countryComparisonResult == .orderedSame {
                    return $0.templeName < $1.templeName
                }
                return countryComparisonResult == .orderedAscending
            }
            // Create sections and index
            for i in (0 ..< (places.count + 1) ) {
                var commonCountry = ""
                if places.count != i {
                    if places[i].templeCountry.lowercased() == places[index].templeCountry.lowercased() {
                        commonCountry = places[i].templeCountry.lowercased()
                    }
                }
                if commonCountry.isEmpty || places.count == i {
                    let string = places[index].templeCountry + " (" + (i - index).description + ")"
                    let title = "\(string)"
                    let newSection = (index: index, length: i - index, title: title)
                    sections.append(newSection)
                    index = i;
                }
            }
        } else {
            // Create sections and index for default Alphabetical
            var commonPrefix = ""
            for i in (0 ..< (places.count + 1) ) {
                if (places.count != i){
                    commonPrefix = places[i].templeName.commonPrefix(with: places[index].templeName, options: .caseInsensitive)
                }
                //print(temples.count)
                if commonPrefix.isEmpty || places.count == i {
                    let string = places[index].templeName.uppercased()
                    let firstCharacter = string[string.startIndex]
                    let title = "\(firstCharacter)"
                    let newSection = (index: index, length: i - index, title: title)
                    sections.append(newSection)
                    index = i;
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setup()
        self.tableView.reloadData()
    }
    
    // Update the Distance in the Place data arrays based on new location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location Update")
        coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        if nearestEnabled {
            updateDistance()
            self.tableView.reloadData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            //print(locationManager.location!)
            coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
            if nearestEnabled {
                updateDistance()
                self.tableView.reloadData()
            }
        }
    }
    
    // Update the distances in the currently viewed array
    func updateDistance() {
        print("Update Distance")
        //print(coordinateOfUser)
        for place in places {
            place.distance = place.cllocation.distance(from: coordinateOfUser!)
            //print(place.templeName + " - " + (place.distance?.description)!)
            //print(place.cllocation)
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
            //print("Latitude: " + (locationManager.location?.coordinate.latitude.description)!)
            //print("Longitude: " + (locationManager.location?.coordinate.longitude.description)!)
            coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        } else {
            print("Location not authorized")
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0;//Choose your custom row height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].length
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var index = Int()

        if nearestEnabled {
            index = indexPath.row
        } else {
            index = sections[indexPath.section].index + indexPath.row
        }
        let temple = places[index]
        cell.textLabel?.text = temple.templeName
        if nearestEnabled {
            cell.detailTextLabel?.text = Int((temple.distance)! * 0.000621371).description + " Mi - " + temple.templeSnippet
        } else {
            cell.detailTextLabel?.text = temple.templeSnippet
        }
        cell.textLabel?.font = UIFont(name: "Baskerville", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Baskerville", size: 14)
        
        switch temple.templeType {
        case "T":
            cell.textLabel?.textColor = UIColor.ocean()
        case "H":
            cell.textLabel?.textColor = UIColor.moss()
        case "C":
            cell.textLabel?.textColor = UIColor.mocha()
        case "V":
            cell.textLabel?.textColor = UIColor.asparagus()
        default:
            cell.textLabel?.textColor = UIColor.lead()
        }
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if nearestEnabled {
            return nil
        }
        return sections.map {$0.title[(title?.startIndex)!].description}
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                var index = Int()
                if nearestEnabled {
                    index = indexPath.row
                } else {
                    index = sections[indexPath.section].index + indexPath.row
                }
                let temple = places[index]
                let controller = (segue.destination as! DetailViewController)
                controller.detailItem = temple
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
        if segue.identifier == "showOptions" {
            let controller: OptionsVC = segue.destination as! OptionsVC
            controller.delegateOptions = self
            controller.sortSelected = sortType
            controller.filterSelected = placeType
        }
    }

}
