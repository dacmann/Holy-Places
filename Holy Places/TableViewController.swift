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

class TableViewController: UITableViewController, SendOptionsDelegate {
    //MARK: - Variables and Outlets
    var nearestEnabled = Bool()
    var sortByCountry = Bool()
    var sortByDedicationDate = Bool()
    var sortBySize = Bool()
    var sections : [(index: Int, length :Int, title: String)] = Array()
    var randomPlace = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var locationButton: UIBarButtonItem!
    
    // MARK: - SendOptions
    // Set variable based Filter Option selected on Options view
    func FilterOptions(row: Int) {
        placeFilterRow = row
        optionsChanged = true
    }
    
    // Set variables based on Sort Option selected on Options view
    func SortOptions(row: Int) {
        placeSortRow = row
        nearestEnabled = false
        sortByCountry = false
        sortByDedicationDate = false
        sortBySize = false
        if placeSortRow == 1 {
            nearestEnabled = true
            //appDelegate.locationServiceSetup() - now done in OptionsVC
        } else if placeSortRow == 2 {
            sortByCountry = true
        } else if placeSortRow == 3 {
            sortByDedicationDate = true
        } else if placeSortRow == 4 {
            sortBySize = true
        }
        optionsChanged = true
    }
    
    //MARK: - CoreData
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
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
        case 4:
            places = construction
        case 5:
            places = announced
        default:
            places = allTemples
        }
        // Search on Place name, City or State and now snippet
        filteredPlaces = places.filter { place in
            let categoryMatch = (scope == "All") || (scope == "Visited" && visits.contains(place.templeName)) || (scope == "Not Visited" && !(visits.contains(place.templeName)))
            return categoryMatch && (place.templeName.lowercased().contains(searchText.lowercased()) || place.templeCityState.lowercased().contains(searchText.lowercased()) || place.templeCountry.lowercased().contains(searchText.lowercased()) || place.templeSnippet.lowercased().contains(searchText.lowercased())  || (place.fhCode?.lowercased().contains(searchText.lowercased()))! || searchText.isEmpty)
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
        case 4:
            title = "Construction"
            places = construction
        case 5:
            title = "Announced"
            places = announced
        default:
            title = "All Temples"
            places = allTemples
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
                appDelegate.updateDistance(placesToUpdate: places, true)
                places.sort { Int($0.distance!) < Int($1.distance!) }
                let newSection = (index: 1, length: places.count, title: "")
                sections.append(newSection)
            } else if sortByDedicationDate {
                subTitle = "by Dedication Date"
                places.sort { $0.templeOrder < $1.templeOrder }
                var commonEra = ""
                var era = "Pioneer Era ~ 1877-1893"
                for i in (0 ..< (places.count + 1) ) {
                    if places.count != i {
                        switch places[i].templeOrder {
                        case 1 ... 4:
                            commonEra = "Pioneer Era ~ 1877-1893"
                        case 5 ... 12:
                            commonEra = "Expansion Era ~ 1919-1958"
                        case 13 ... 20:
                            commonEra = "Strengthening Era ~ 1964-1981"
                        case 21 ... 53:
                            commonEra = "Growth Era ~ 1983-1998"
                        case 54 ... 114:
                            commonEra = "Explosive Era ~ 1999-2002"
                        default:
                            commonEra = "Hastening Era ~ 2003-Present"
                        }
                    }
                    if era != commonEra || places.count == i {
                        let title = "\(era) (\(i - index))"
                        let newSection = (index: index, length: i - index, title: title)
                        sections.append(newSection)
                        era = commonEra
                        index = i
                    }
                }
            } else if sortBySize {
                subTitle = "by Size"
                places.sort {
                    if Double($0.templeSqFt!) == Double($1.templeSqFt!) {
                        return $0.templeName < $1.templeName
                    }
                    return Double($0.templeSqFt!) > Double($1.templeSqFt!)
                }
                var commonSize = ""
                var size = "Over 100K sqft"
                for i in (0 ..< (places.count + 1) ) {
                    if places.count != i {
                        if let sqft = places[i].templeSqFt {
                            switch sqft {
                            case 100000... :
                                commonSize = "Over 100K sqft"
                            case 60000 ... 99999:
                                commonSize = "60K - 100K sqft"
                            case 30000 ... 59999:
                                commonSize = "30K - 60K sqft"
                            case 12000 ... 29999:
                                commonSize = "12K - 30K sqft"
                            default:
                                commonSize = "Under 12K sqft"
                            }
                        }
                    }
                    if size != commonSize || places.count == i {
                        let title = "\(size) (\(i - index))"
                        let newSection = (index: index, length: i - index, title: title)
                        sections.append(newSection)
                        size = commonSize
                        index = i
                    }
                }
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
                // Create sections and index
                for i in (0 ..< (places.count + 1) ) {
                    var commonCountry = ""
                    if places.count != i {
                        if places[i].templeCountry.lowercased() == places[index].templeCountry.lowercased() {
                            commonCountry = places[i].templeCountry.lowercased()
                        }
                    }
                    if commonCountry.isEmpty || places.count == i {
                        let title = places[index].templeCountry + " (" + (i - index).description + ")"
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
            titleLabel.textColor = UIColor(named: "TempleDarkRed")
        case 2:
            titleLabel.textColor = UIColor.darkLimeGreen()
        case 4:
            titleLabel.textColor = UIColor.darkOrange()
        case 3:
            titleLabel.textColor = UIColor.strongYellow()
        case 5:
            titleLabel.textColor = UIColor.brown
        default:
            titleLabel.textColor = UIColor(named: "DefaultText")!
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
    
    
    //MARK: - Standard methods
    fileprivate func updateView() {
        setup()
//        appDelegate.getVisits()
        self.tableView.reloadData()
        
        if nearestEnabled {
            locationButton.title = "Location"
            // Create Notification Observer ".reload" to trigger the table to refresh when the location changes
            NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        } else {
            locationButton.title = ""
            // Remove Notification Observer ".reload"
            NotificationCenter.default.removeObserver(self, name: .reload, object: nil)
        }
        locationButton.isEnabled = nearestEnabled
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if optionsChanged {
            updateView()
            // Scroll to first row
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            optionsChanged = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        // bug with following option in 13.1
        if #available(iOS 13.2, *) {
            searchController.hidesNavigationBarDuringPresentation = false
        }
        searchController.searchBar.tintColor = UIColor(named: "BaptismsBlue")
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchBar.scopeButtonTitles = ["All", "Visited", "Not Visited"]
        searchController.searchBar.delegate = self
        SortOptions(row: placeSortRow)
        FilterOptions(row: placeFilterRow)
        // Add done button to keyboard
        keyboardDone()
        
        tableView.sectionIndexColor = UIColor(named: "BaptismsBlue")
        
        // Change the font and color for the navigation Bar text
        let barbuttonFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)
        if #available(iOS 13.0, *) {
            let style = UINavigationBarAppearance()
            let searchField = searchController.searchBar.searchTextField
            searchField.font = UIFont(name: "Baskerville", size: 17)
            style.configureWithOpaqueBackground()
            style.buttonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor(named: "BaptismsBlue")!]
            style.doneButtonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor(named: "BaptismsBlue")!]
            style.titleTextAttributes = [
                .foregroundColor : UIColor(named: "BaptismsBlue")!, // Navigation bar title color
                .font : navbarFont // Navigation bar title font
            ]
            navigationController?.navigationBar.standardAppearance = style
            
        } else {
            // Fallback on earlier versions
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor(named: "BaptismsBlue")!], for: UIControl.State.normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor(named: "BaptismsBlue")!], for: UIControl.State.highlighted)
            
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor:UIColor(named: "DefaultText")!]
            UINavigationBar.appearance().tintColor = UIColor(named: "BaptismsBlue")
        }
    }
    
    @objc func reloadTableData(_ notification: Notification) {
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

        if nearestEnabled {
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
            cell.detailTextLabel?.text = " " + distance + temple.templeSnippet
        } else if sortBySize {
            // include sq ft in label text
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            let formattedNumber = numberFormatter.string(from: NSNumber(value:temple.templeSqFt!))
            cell.detailTextLabel?.text = " \(formattedNumber ?? "") sq ft - \(temple.templeSnippet)"
        } else {
            cell.detailTextLabel?.text = " " + temple.templeSnippet
        }
        cell.textLabel?.font = UIFont(name: "Baskerville", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Baskerville", size: 14)
        
        switch temple.templeType {
        case "T":
            cell.textLabel?.textColor = UIColor(named: "TempleDarkRed")
        case "H":
            cell.textLabel?.textColor = UIColor.darkLimeGreen()
        case "A":
            cell.textLabel?.textColor = UIColor.brown
        case "C":
            cell.textLabel?.textColor = UIColor.darkOrange()
        case "V":
            cell.textLabel?.textColor = UIColor.strongYellow()
        default:
            cell.textLabel?.textColor = UIColor(named: "DefaultText")!
        }
        
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Baskerville", size: 22)
        header.textLabel?.textColor = UIColor(named: "BaptismsBlue")
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if nearestEnabled || sortByDedicationDate || sortBySize {
            return nil
        } else {
            let titles = sections.map {$0.title[(title?.startIndex)!].description}
//            titles.insert(UITableViewIndexSearch, at: 0)
            return titles
        }
//        return sections.map {$0.title[(title?.startIndex)!].description}
        
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
//        if nearestEnabled || sortByDedicationDate {
            return index
//        } else {
//            if index == 0 {
//                tableView.scrollRectToVisible((tableView.tableHeaderView?.frame)!, animated: false)
//                return NSNotFound
//            }
//            return index - 1
//        }
    }
    

    
    // MARK: - Navigation
    
    func openForPlace(shortcutIdentifier: ShortcutIdentifier) -> Bool {
//        SortOptions(row: placeSortRow)
        updateView()
        if shortcutIdentifier == .OpenRandomPlace {
            randomPlace = true
            performSegue(withIdentifier: "showDetail", sender: nil)
        }
        if shortcutIdentifier == .ViewPlace {
            performSegue(withIdentifier: "showDetail", sender: nil)
        }
        return true
    }

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
        var index = Int()
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if nearestEnabled {
                    index = indexPath.row
                } else {
                    index = sections[indexPath.section].index + indexPath.row
                }
                selectedPlaceRow = index
                detailItem = places[index]
            } else if randomPlace {
                selectedPlaceRow = Int(arc4random_uniform(UInt32(allPlaces.count)))
                detailItem = allPlaces[selectedPlaceRow]
            }
            let controller = (segue.destination as! PlaceDetailVC)
            controller.navigationItem.leftItemsSupplementBackButton = true
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
