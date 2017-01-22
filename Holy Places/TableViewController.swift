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
    var nearestEnabled = Bool()
    var sections : [(index: Int, length :Int, title: String)] = Array()
    var locationManager: CLLocationManager!
    var coordinateOfUser: CLLocationCoordinate2D!
    
    func FilterOptions(row: Int) {
        placeType = row
    }
    
    func NearestEnabled(nearest: Bool) {
        nearestEnabled = nearest
    }
    
    
    func setup () {
                
        print(placeType)
        switch placeType {
        case 0:
            self.navigationItem.title = "LDS Holy Places"
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
        if nearestEnabled {
            places.sort { Int($0.distance!) < Int($1.distance!) }
            let newSection = (index: 1, length: places.count, title: "")
            sections.append(newSection)
        } else {
            var index = 0
            var commonPrefix = ""
            for i in (0 ..< (places.count + 1) ) {
                if (places.count != i){
                    commonPrefix = places[i].templeName.commonPrefix(with: places[index].templeName, options: .caseInsensitive)
                }
                //print(temples.count)
                if ( commonPrefix.isEmpty || places.count == i) {
                    let string = places[index].templeName.uppercased();
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print(locationManager.location!)
            coordinateOfUser = locationManager.location?.coordinate
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
            coordinateOfUser = locationManager.location?.coordinate
        } else {
            print("Location not authorized")
        }
        
        //setup()

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

        var index = Int()

        if nearestEnabled {
            index = indexPath.row
        } else {
            index = sections[indexPath.section].index + indexPath.row
        }
        let temple = places[index]
        cell.textLabel?.text = temple.templeName
        if nearestEnabled {
            cell.detailTextLabel?.text = Int((temple.distance)! * 0.000621371).description + " Miles"
        } else {
            cell.detailTextLabel?.text = temple.templeSnippet
        }

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
            controller.nearestEnabled = nearestEnabled
            controller.filterSelected = placeType
        }
    }

}
