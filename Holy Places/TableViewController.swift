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
        let searchText = searchController.searchBar.text ?? ""
        
        // Don't sync custom control - it's the master control
        
        filterContentForSearchText(searchText: searchText, scope: scope)
    }
}

extension TableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let scope = searchBar.scopeButtonTitles![selectedScope]
        
        // Don't sync custom control - it's the master control
        
        if searchController.isActive {
            // When search is active, use the full search filtering
            let searchText = searchBar.text ?? ""
            filterContentForSearchText(searchText: searchText, scope: scope)
        } else {
            // When search is not active, use scope-only filtering
            applyScopeFilter(scope: scope)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        customizeSearchBarAppearance()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        customizeSearchBarAppearance()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Customization will be handled by search controller delegate
    }
}

class TableViewController: UITableViewController, SendOptionsDelegate, UISearchControllerDelegate {
    //MARK: - Variables and Outlets
    var nearestEnabled = Bool()
    var sortByCountry = Bool()
    var sortByDedicationDate = Bool()
    var sortBySize = Bool()
    var sortByAnnouncedDate = Bool()
    var sections : [(index: Int, length :Int, title: String)] = Array()
    var randomPlace = false
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var locationButton: UIBarButtonItem!
    
    // Custom scope control
    var customScopeControl: UISegmentedControl!
    var scopeView: UIView?
    var separatorLine: UIView?
    var isScopeFiltering = false
    
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
        sortByAnnouncedDate = false
        
        if placeSortRow == 1 {
            nearestEnabled = true
        } else if placeSortRow == 2 {
            sortByCountry = true
        } else if placeSortRow == 3 {
            // Dedication Date for Active Temples
            if placeFilterRow == 1 {
                sortByDedicationDate = true
            }
            // Announced Date for non-active temples
            if [4, 5, 6].contains(placeFilterRow) {
                sortByAnnouncedDate = true
            }
        } else if placeSortRow == 4 {
            sortBySize = true
        } else if placeSortRow == 5 {
            // Announced Date for Active Temples
            if placeFilterRow == 1 {
                sortByAnnouncedDate = true
            }
        }

        optionsChanged = true
    }
    
    //MARK: - CoreData
    func getContext () -> NSManagedObjectContext {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return ad.persistentContainer.viewContext
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
        
        // Split search text into individual terms for AND search
        let searchTerms = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        // Search on Place name, City or State and now snippet with AND logic
        filteredPlaces = places.filter { place in
            let categoryMatch = (scope == "All") || (scope == "Visited" && visits.contains(place.templeName)) || (scope == "Not Visited" && !(visits.contains(place.templeName)))
            
            guard categoryMatch else { return false }
            guard !searchTerms.isEmpty else { return true }
            
            // Create searchable text from all relevant fields
            let searchableText = "\(place.templeName) \(place.templeCityState) \(place.templeCountry) \(place.templeSnippet) \(place.fhCode ?? "")".lowercased()
            
            // AND search: all terms must be found in the searchable text
            return searchTerms.allSatisfy { term in
                searchableText.contains(term.lowercased())
            }
        }
        // Update table to reflect filtered results
        setup()
        tableView.reloadData()
    }
    
    func applyScopeFilter(scope: String) {
        isScopeFiltering = true
        
        // Reset places to full array based on current filter
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
        
        
        // Apply scope filtering
        if scope != "All" {
            places = places.filter { place in
                if scope == "Visited" {
                    return visits.contains(place.templeName)
                } else if scope == "Not Visited" {
                    return !visits.contains(place.templeName)
                }
                return true
            }
        }
        
        
        // If search is active, apply search filtering to the scope-filtered results
        if searchController.isActive {
            let searchText = searchController.searchBar.text ?? ""
            if !searchText.isEmpty {
                // Split search text into individual terms for AND search
                let searchTerms = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                places = places.filter { place in
                    // Create searchable text from all relevant fields
                    let searchableText = "\(place.templeName) \(place.templeCityState) \(place.templeCountry) \(place.templeSnippet) \(place.fhCode ?? "")".lowercased()
                    
                    // AND search: all terms must be found in the searchable text
                    return searchTerms.allSatisfy { term in
                        searchableText.contains(term.lowercased())
                    }
                }
            }
        }
        
        // Update table to reflect filtered results - call setup without resetting places
        setupForScopeFilter()
        tableView.reloadData()
        
        // Reset flag after a short delay to allow viewWillAppear to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isScopeFiltering = false
        }
    }
    
    func setupForScopeFilter() {
        
        // Set up title and subtitle without calling setup() (which resets places)
        var title = String()
        var subTitle = ""
        
        // Set title based on current filter
        switch placeFilterRow {
        case 0:
            title = "Holy Places"
        case 1:
            title = "Active Temples"
        case 2:
            title = "Historical Sites"
        case 3:
            title = "Visitors' Centers"
        case 4:
            title = "Construction"
        case 5:
            title = "Announced"
        default:
            title = "All Temples"
        }
        
        // Set subtitle based on sort method
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
        } else if sortByDedicationDate {
            subTitle = "by Dedication Date"
        } else if sortByAnnouncedDate {
            subTitle = "by Announced Date"
        } else if sortBySize {
            subTitle = "by Size"
        } else if sortByCountry {
            subTitle = "by Country"
        } else {
            subTitle = "Alphabetical Order"
        }
        
        // Update navigation title
        self.navigationItem.titleView = setTitle(title: "\(title) (\(places.count.description))", subtitle: subTitle, type: placeFilterRow)
        
        // Create sections for the filtered data
        createSectionsForPlaces()
        
    }
    
    // Helper method to create sections for any places array
    func createSectionsForPlaces() {
        sections.removeAll()
        
        if places.count > 0 {
            var index = 0
            if nearestEnabled {
                ad.updateDistance(placesToUpdate: places, true)
                places.sort { Int($0.distance!) < Int($1.distance!) }
                let newSection = (index: 1, length: places.count, title: "")
                sections.append(newSection)
            } else if sortByDedicationDate {
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
                        case 115 ... 161:
                            commonEra = "Hastening Era ~ 2003-2018"
                        default:
                            commonEra = "Unparalleled Era ~ 2019-\(Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year ?? 2023)"
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
            } else if sortByAnnouncedDate {
                places.sort {
                    switch ($0.templeAnnouncedDate, $1.templeAnnouncedDate) {
                    case let (d1?, d2?):
                        return d1 > d2
                    case (_?, nil):
                        return true
                    case (nil, _?):
                        return false
                    default:
                        return false
                    }
                }
                var index = 0
                var currentDateString = ""
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMMM yyyy"
                for i in 0...places.count {
                    var dateString = ""
                    if i < places.count, let date = places[i].templeAnnouncedDate {
                        dateString = formatter.string(from: date)
                    }
                    if dateString != currentDateString || i == places.count {
                        if !currentDateString.isEmpty {
                            let title = "\(currentDateString) (\(i - index))"
                            let newSection = (index: index, length: i - index, title: title)
                            sections.append(newSection)
                        }
                        currentDateString = dateString
                        index = i
                    }
                }
            } else if sortBySize {
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
                places.sort {
                    let countryComparisonResult = $0.templeCountry.compare($1.templeCountry)
                    if countryComparisonResult == .orderedSame {
                        return $0.templeName < $1.templeName
                    }
                    return countryComparisonResult == .orderedAscending
                }
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
                places.sort {$0.templeName < $1.templeName}
                var commonPrefix = ""
                for i in (0 ..< (places.count + 1) ) {
                    if places.count != i {
                        commonPrefix = places[i].templeName.commonPrefix(with: places[index].templeName, options: .caseInsensitive)
                    }
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
    }
    
    func setupCustomScopeControl() {
        // Create custom segmented control
        customScopeControl = UISegmentedControl(items: ["All", "Visited", "Not Visited"])
        customScopeControl.selectedSegmentIndex = 0
        customScopeControl.backgroundColor = UIColor.systemBackground
        customScopeControl.selectedSegmentTintColor = UIColor(named: "BaptismsBlueBtn")
        customScopeControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont(name: "Baskerville", size: 16) ?? UIFont.systemFont(ofSize: 16)], for: .selected)
        customScopeControl.setTitleTextAttributes([.foregroundColor: UIColor.label, .font: UIFont(name: "Baskerville", size: 16) ?? UIFont.systemFont(ofSize: 16)], for: .normal)
        customScopeControl.apportionsSegmentWidthsByContent = false
        
        // Add action
        customScopeControl.addTarget(self, action: #selector(scopeControlChanged), for: .valueChanged)
        
        // Create a fixed view below the search bar
        scopeView = UIView()
        scopeView!.backgroundColor = UIColor.systemBackground
        scopeView!.translatesAutoresizingMaskIntoConstraints = false
        scopeView!.isUserInteractionEnabled = true  // Enable touches for the segmented control
        customScopeControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Add scope control to scope view
        scopeView!.addSubview(customScopeControl)
        
        // Create separator line
        separatorLine = UIView()
        separatorLine!.backgroundColor = UIColor.separator
        separatorLine!.translatesAutoresizingMaskIntoConstraints = false
        scopeView!.addSubview(separatorLine!)
        
        // Only set height constraint here, positioning will be done in viewDidLayoutSubviews
        NSLayoutConstraint.activate([
            scopeView!.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Use AutoLayout for customScopeControl
        customScopeControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Adjust table view content inset to account for the fixed scope view
        tableView.contentInset.top = 44
        tableView.scrollIndicatorInsets.top = 44
    }
    
    @objc func scopeControlChanged() {
        let selectedIndex = customScopeControl.selectedSegmentIndex
        let scope = customScopeControl.titleForSegment(at: selectedIndex) ?? "All"
        
        // Sync search bar scope with custom control
        searchController.searchBar.selectedScopeButtonIndex = selectedIndex
        
        applyScopeFilter(scope: scope)
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
        
        // Custom scope control is used instead of search bar scope buttons
        
        // Set subtitle based on sort method
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
        } else if sortByDedicationDate {
            subTitle = "by Dedication Date"
        } else if sortByAnnouncedDate {
            subTitle = "by Announced Date"
        } else if sortBySize {
            subTitle = "by Size"
        } else if sortByCountry {
            subTitle = "by Country"
        } else {
            subTitle = "Alphabetical Order"
        }
        
        // Create sections using the helper method
        createSectionsForPlaces()
        
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
            titleLabel.textColor = templeColor
        case 2:
            titleLabel.textColor = historicalColor
        case 3:
            titleLabel.textColor = visitorCenterColor
        case 4:
            titleLabel.textColor = constructionColor
        case 5:
            titleLabel.textColor = announcedColor
        default:
            titleLabel.textColor = defaultColor
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
        if !isScopeFiltering {
            setup()
        } else {
        }
//        appDelegate.getVisits()
        self.tableView.reloadData()
        
        if nearestEnabled {
            locationButton.title = "Location"
            locationButton.isEnabled = true
            // Show the Location button
            navigationItem.leftBarButtonItem = locationButton
            // Create Notification Observer ".reload" to trigger the table to refresh when the location changes
            NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        } else {
            // Hide the Location button
            navigationItem.leftBarButtonItem = nil
            // Remove Notification Observer ".reload"
            NotificationCenter.default.removeObserver(self, name: .reload, object: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Position scope control below search bar once search bar is laid out
        if let scopeView = scopeView, scopeView.superview == nil {
            view.addSubview(scopeView)
            
            // Add all constraints to position directly below safe area and full width
            NSLayoutConstraint.activate([
                scopeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scopeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scopeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scopeView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
            
            // Force layout to ensure proper sizing
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
        }
        
        // Update custom scope control and separator constraints (only once)
        if let scopeView = scopeView, let customScopeControl = customScopeControl, let separatorLine = separatorLine, scopeView.superview != nil, customScopeControl.superview == scopeView {
            // Check if constraints already exist by looking for centerX constraint
            let hasConstraints = customScopeControl.constraints.contains { $0.firstAttribute == .centerX }
            
            if !hasConstraints {
                
                // Add constraints to center the control and position separator
                NSLayoutConstraint.activate([
                    // Center the scope control with proper width
                    customScopeControl.centerXAnchor.constraint(equalTo: scopeView.centerXAnchor),
                    customScopeControl.centerYAnchor.constraint(equalTo: scopeView.centerYAnchor),
                    customScopeControl.widthAnchor.constraint(equalTo: scopeView.widthAnchor, multiplier: 0.8),
                    
                    // Position separator line at bottom, full width
                    separatorLine.leadingAnchor.constraint(equalTo: scopeView.leadingAnchor),
                    separatorLine.trailingAnchor.constraint(equalTo: scopeView.trailingAnchor),
                    separatorLine.bottomAnchor.constraint(equalTo: scopeView.bottomAnchor),
                    separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
                ])
                
                // Force layout update
                scopeView.setNeedsLayout()
                scopeView.layoutIfNeeded()
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Ensure custom scope control is always visible
        if customScopeControl == nil {
            setupCustomScopeControl()
        }
        
        if optionsChanged || themeChanged {
            updateView()
            // Scroll to first row
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            optionsChanged = false
            themeChanged = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // save Place updates on main thread
        if ad.newFileParsed {
            ad.storePlaces()
            ad.savePlaceVersion()
            checkedForUpdate = Date()
            ad.newFileParsed = false
        }
        // Pop message when update has occured
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
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle OK (cancel) Logic here")
                // clear out message now that it has been presented
                changesDate = ""
            }))
            self.present(alert, animated: true)
        }
        
        // Ensure search bar appearance is customized
        customizeSearchBarAppearance()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        // bug with following option in 13.1
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.tintColor = UIColor(named: "BaptismsBlue")
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Custom scope control will be added separately
        
        extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchBar.scopeButtonTitles = ["All", "Visited", "Not Visited"]
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchBar.showsScopeBar = false  // Hide original scope bar since we have custom one
        SortOptions(row: placeSortRow)
        FilterOptions(row: placeFilterRow)
        
        // Create custom scope control
        setupCustomScopeControl()
        
        // Apply initial scope filter (start with "All")
        applyScopeFilter(scope: "All")
        
        tableView.sectionIndexColor = UIColor(named: "BaptismsBlue")
        
        // Add Done button to search bar keyboard
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        // Customize Done button font
        let baskervilleFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let baptismsBlue = UIColor(named: "BaptismsBlue")
        
        doneButton.setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .normal)
        
        doneButton.setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .highlighted)
        
        doneButton.setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .selected)
        
        keyboardToolbar.items = [flexSpace, doneButton]

        searchController.searchBar.inputAccessoryView = keyboardToolbar
        
        // Customize search bar and scope button fonts
        customizeSearchBarAppearance()

    }
    
    func customizeSearchBarAppearance() {
        let baskervilleFont = UIFont(name: "Baskerville", size: 16) ?? UIFont.systemFont(ofSize: 16)
        
        // Customize search text field font
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = baskervilleFont
        }
        
        // Customize scope button fonts
        searchController.searchBar.setScopeBarButtonTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: UIColor(named: "BaptismsBlue")
        ], for: .normal)
        
        searchController.searchBar.setScopeBarButtonTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: UIColor(named: "BaptismsBlue")
        ], for: .selected)
        
        // Customize cancel button font
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: UIColor(named: "BaptismsBlue")
        ], for: .normal)
    }
    
    // MARK: - Search Controller Delegate Methods
    func willPresentSearchController(_ searchController: UISearchController) {
        customizeSearchBarAppearance()
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        customizeSearchBarAppearance()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        // No action needed
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        // No action needed
    }
    
    @objc func dismissKeyboard() {
        searchController.searchBar.resignFirstResponder()
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
            cell.textLabel?.textColor = templeColor
        case "H":
            cell.textLabel?.textColor = historicalColor
        case "A":
            cell.textLabel?.textColor = announcedColor
        case "C":
            cell.textLabel?.textColor = constructionColor
        case "V":
            cell.textLabel?.textColor = visitorCenterColor
        default:
            cell.textLabel?.textColor = defaultColor
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
        
        if nearestEnabled || sortByDedicationDate || sortBySize || sortByAnnouncedDate {
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
