//
//  TableViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

extension TableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchText: searchController.searchBar.text!, scope: scope)
    }
}

extension TableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

class TableViewController: UITableViewController, SendOptionsDelegate, CLLocationManagerDelegate {
    //MARK: - Variables and Outlets
    var nearestEnabled = Bool()
    var sortByCountry = Bool()
    var sortByDedicationDate = Bool()
    var sections : [(index: Int, length :Int, title: String)] = Array()
    let locationManager = CLLocationManager()
    var coordinateOfUser: CLLocation!
    

    @IBOutlet weak var locationButton: UIBarButtonItem!
    
    // MARK: - SendOptions
    // Set variable based Filter Option selected on Options view
    func FilterOptions(row: Int) {
        placeFilterRow = row
    }
    
    // Set variables based on Sort Option selected on Options view
    func SortOptions(row: Int) {
        placeSortRow = row
        nearestEnabled = false
        sortByCountry = false
        sortByDedicationDate = false
        if placeSortRow == 1 {
            nearestEnabled = true
            locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startMonitoringSignificantLocationChanges()
        } else if placeSortRow == 2 {
            sortByCountry = true
        } else if placeSortRow == 3 {
            sortByDedicationDate = true
        }
    }
    
    //MARK: - CoreData
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    // Retrieve the Visits data from CoreData
    func getVisits () {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        do {
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            //I like to check the size of the returned results!
            //print ("num of results = \(searchResults.count)")
            
            //You need to convert to NSManagedObject to use 'for' loops
            for visit in searchResults as [NSManagedObject] {
                visits.append(visit.value(forKey: "holyPlace") as! String)
            }
        } catch {
            print("Error with request: \(error)")
        }
        
    }
    
    //MARK: - Search Controller Code
    let searchController = UISearchController(searchResultsController: nil)
    var filteredPlaces = [Temple]()
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        // Reset places to full array
        switch placeFilterRow {
        case 0:
            places = allPlaces
        case 1:
            places = activeTemples
        case 2:
            places = historical
        case 3:
            places = visitors
        default:
            places = construction
        }
        // Search on Place name, City or State and now snippet
        filteredPlaces = places.filter { place in
            let categoryMatch = (scope == "All") || (scope == "Visited" && visits.contains(place.templeName)) || (scope == "Not Visited" && !(visits.contains(place.templeName)))
            return categoryMatch && (place.templeName.lowercased().contains(searchText.lowercased()) || place.templeCityState.lowercased().contains(searchText.lowercased()) || place.templeCountry.lowercased().contains(searchText.lowercased()) || place.templeSnippet.lowercased().contains(searchText.lowercased()) || searchText.isEmpty)
        }
        // Update table to reflect filtered results
        setup()
        tableView.reloadData()
    }
    
    //MARK: - Filters and Sort
    // Determine Filters and sort criteria and build indexes if required
    func setup () {
        var title = String()
        var subTitle = ""
        
        switch placeFilterRow {
        case 0:
            title = "Holy Places"
            places = allPlaces
        case 1:
            title = "Active Temples"
            places = activeTemples
        case 2:
            title = "Historical Sites"
            places = historical
        case 3:
            title = "Visitors' Centers"
            places = visitors
        default:
            title = "Construction"
            places = construction
        }

        // If search bar is active use filteredPlaces instead
        if searchController.isActive {
            places = filteredPlaces
        }
        
        //reset sections array
        sections.removeAll()
        
        if places.count > 0 {
             //create index for array
            var index = 0
            if nearestEnabled {
                if locationSpecific {
                    if altLocState != "" || altLocCity != "" {
                        subTitle = "Nearest to \(altLocCity) \(altLocState)"
                    } else if altLocPostalCode != "" {
                        subTitle = "Nearest to \(altLocPostalCode)"
                    } else {
                        subTitle = "Nearest to \(altLocStreet)"
                    }
                } else {
                    subTitle = "Nearest to Current Location"
                }
                updateDistance()
                places.sort { Int($0.distance!) < Int($1.distance!) }
                let newSection = (index: 1, length: places.count, title: "")
                sections.append(newSection)
            } else if sortByDedicationDate {
                subTitle = "by Dedication Date"
                places.sort { $0.templeOrder < $1.templeOrder }
                let newSection = (index: 1, length: places.count, title: "")
                sections.append(newSection)
            } else if sortByCountry {
                subTitle = "by Country"
                // Sort by Country and then by Name
                places.sort {
                    let countryComparisonResult = $0.templeCountry.compare($1.templeCountry)
                    if countryComparisonResult == .orderedSame {
                        return $0.templeName < $1.templeName
                    }
                    return countryComparisonResult == .orderedAscending
                }
//                sections.append((index: 0, length: 0, title: UITableViewIndexSearch))
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
                        index = i
                    }
                }
            } else {
                // Sort by Name
                subTitle = "Alphabetical Order"
                places.sort {$0.templeName < $1.templeName}
                // Create sections and index for default Alphabetical
//                sections.append((index: 0, length: 0, title: UITableViewIndexSearch))
                var commonPrefix = ""
                for i in (0 ..< (places.count + 1) ) {
                    if places.count != i {
                        commonPrefix = places[i].templeName.commonPrefix(with: places[index].templeName, options: .caseInsensitive)
                    }
                    //print(temples.count)
                    if commonPrefix.isEmpty || places.count == i {
                        let string = places[index].templeName.uppercased()
                        let firstCharacter = string[string.startIndex]
                        let title = "\(firstCharacter)"
                        let newSection = (index: index, length: i - index, title: title)
                        sections.append(newSection)
                        index = i
                    }
                }
            }
        }
        // Update title of View
        self.navigationItem.titleView = setTitle(title: "\(title) (\(places.count.description))", subtitle: subTitle, type: placeFilterRow)
    }
    
    func setTitle(title:String, subtitle:String, type:Int) -> UIView {
        
        // Replace titleView with custom version that includes sub title
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        let titleFont = UIFont(name: "Baskerville", size: 19) ?? UIFont.systemFont(ofSize: 19)
        let subTitleFont = UIFont(name: "Baskerville", size: 15) ?? UIFont.systemFont(ofSize: 15)
        
        titleLabel.backgroundColor = UIColor.clear
        switch type {
        case 1:
            titleLabel.textColor = UIColor.darkRed()
        case 2:
            titleLabel.textColor = UIColor.darkLimeGreen()
        case 4:
            titleLabel.textColor = UIColor.darkOrange()
        case 3:
            titleLabel.textColor = UIColor.strongYellow()
        default:
            titleLabel.textColor = UIColor.lead()
        }
        titleLabel.font = titleFont
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.gray
        subtitleLabel.font = subTitleFont
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        
        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }
        
        return titleView
    }
    
    // MARK: - Location Services
    // Update the Distance in the Place data arrays based on new location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location Update")
        coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        if nearestEnabled {
            updateDistance()
            setup()
            self.tableView.reloadData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("Location Authorized")
            coordinateOfUser = CLLocation(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
            if nearestEnabled {
                updateDistance()
                setup()
                self.tableView.reloadData()
            }
        } else {
            print("Location not authorized")
            coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
        }
    }
    
    // Update the distances in the currently viewed array
    func updateDistance() {
        //print("Update Distance")
        //print(coordinateOfUser)
        for place in places {
            if locationSpecific {
                place.distance = place.cllocation.distance(from: coordAltLocation!)
            } else {
                place.distance = place.cllocation.distance(from: coordinateOfUser!)
            }
//            print(place.templeName + " - " + (place.distance?.description)!)
//            print(place.cllocation)
        }
    }
    
    //MARK: - Standard methods
    override func viewWillAppear(_ animated: Bool) {
        setup()
        getVisits()
        self.tableView.reloadData()
        
        if nearestEnabled {
            locationButton.title = "Location"
        } else {
            locationButton.title = ""
        }
        locationButton.isEnabled = nearestEnabled
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self

        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedWhenInUse {
            print("Location not authorized")
            coordinateOfUser = CLLocation(latitude: 40.7707425, longitude: -111.8932596)
        }
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.tintColor = UIColor.ocean()
        let searchBarFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedStringKey.font.rawValue: searchBarFont, NSAttributedStringKey.foregroundColor.rawValue:UIColor.ocean()], for: UIControlState.normal)
        
        let textFieldInsideUISearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchBar.scopeButtonTitles = ["All", "Visited", "Not Visited"]
        searchController.searchBar.delegate = self
        SortOptions(row: placeSortRow)
        FilterOptions(row: placeFilterRow)
        // Add done button to keyboard
        keyboardDone()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0 //Choose your custom row height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].length
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var index = Int()

        if nearestEnabled || sortByDedicationDate {
            index = indexPath.row
        } else {
            index = sections[indexPath.section].index + indexPath.row
        }
        
        let temple = places[index]
        
        cell.textLabel?.text = temple.templeName
        if nearestEnabled {
            // convert distance from meters to miles
            var distance = Int((temple.distance)! * 0.000621371).description
            // When under a mile, show distance in feet instead
            if distance == "0" {
                distance = Int((temple.distance)! * 3.28084).description + " ft - "
            } else {
                distance.append(" mi. - ")
            }
            cell.detailTextLabel?.text = "· " + distance + temple.templeSnippet
        } else {
            cell.detailTextLabel?.text = "· " + temple.templeSnippet
        }
        cell.textLabel?.font = UIFont(name: "Baskerville", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Baskerville", size: 14)
        
        switch temple.templeType {
        case "T":
            cell.textLabel?.textColor = UIColor.darkRed()
        case "H":
            cell.textLabel?.textColor = UIColor.darkLimeGreen()
        case "C":
            cell.textLabel?.textColor = UIColor.darkOrange()
        case "V":
            cell.textLabel?.textColor = UIColor.strongYellow()
        default:
            cell.textLabel?.textColor = UIColor.lead()
        }
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //Create label and autoresize it
        let headerLabel = UILabel()
        headerLabel.font = UIFont(name: "Baskerville", size: 22)
        headerLabel.backgroundColor = UIColor.white
        headerLabel.textColor = UIColor.ocean()
        headerLabel.text = self.tableView(self.tableView, titleForHeaderInSection: section)
        headerLabel.sizeToFit()
        
        //Adding Label to existing headerView
        let headerView = UIView()
        headerView.addSubview(headerLabel)
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if nearestEnabled || sortByDedicationDate {
            return nil
        } else {
            var titles = sections.map {$0.title[(title?.startIndex)!].description}
            titles.insert(UITableViewIndexSearch, at: 0)
            return titles
        }
//        return sections.map {$0.title[(title?.startIndex)!].description}
        
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if nearestEnabled || sortByDedicationDate {
            return index
        } else {
            if index == 0 {
                tableView.scrollRectToVisible((tableView.tableHeaderView?.frame)!, animated: false)
                return NSNotFound
            }
            return index - 1
        }
    }
    

    
    // MARK: - Navigation

    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        //array of BarButtonItems
        var arr = [UIBarButtonItem]()
        arr.append(flexSpace)
        arr.append(doneBtn)
        toolbar.setItems(arr, animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.searchController.searchBar.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction(){
        self.searchController.searchBar.endEditing(true)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                var index = Int()
                if nearestEnabled || sortByDedicationDate {
                    index = indexPath.row
                } else {
                    index = sections[indexPath.section].index + indexPath.row
                }
                let temple = places[index]
                let controller = (segue.destination as! PlaceDetailVC)
                detailItem = temple
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
        if segue.identifier == "showOptions" {
            let controller: OptionsVC = segue.destination as! OptionsVC
            controller.delegateOptions = self
            controller.sortSelected = placeSortRow
            controller.filterSelected = placeFilterRow
            searchController.isActive = false
        }
    }

}
