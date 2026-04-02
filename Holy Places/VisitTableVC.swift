//
//  VisitTableVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/13/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import StoreKit

extension VisitTableVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchText: searchController.searchBar.text!, scope: scope)
    }
}

extension VisitTableVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

class VisitTableVC: UITableViewController, SendVisitOptionsDelegate, NSFetchedResultsControllerDelegate, UISearchControllerDelegate {
    
    var titleHeader = String()
    var quickAddPlace: Temple?
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let formatter = DateFormatter()
    var sortOption = 0 // 0: Latest Date, 1: Oldest Date, 2: Place A-Z, 3: Place Z-A
    var backupDate: Date?
    var backupReminder: Date?
    
    @IBOutlet weak var sortBy: UIBarButtonItem!
    @IBOutlet weak var filterBy: UIBarButtonItem!
    
    // MARK: - Select / Copy-to-Profile Mode
    private var isSelectMode = false
    private var selectedVisitIds = Set<NSManagedObjectID>()
    private var selectBarButton: UIBarButtonItem!
    private var selectAllBarButton: UIBarButtonItem!
    private var copyToProfileBarButton: UIBarButtonItem!
    private var savedRightBarButtonItems: [UIBarButtonItem]?
    private var savedLeftBarButtonItems: [UIBarButtonItem]?
    
    // Sort options for the menu
    let sortOptions = ["Latest Date", "Oldest Date", "Place (A-Z)", "Place (Z-A)"]
    
    // Filter options for the menu
    let filterOptions = ["All Visits", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction", "Other"]
    
    
    func setupSortMenu() {
        let sortMenu = UIMenu(title: "Sort by", children: [
            UIAction(title: "Latest Date", handler: { [weak self] _ in
                self?.updateSortOption(0)
            }),
            UIAction(title: "Oldest Date", handler: { [weak self] _ in
                self?.updateSortOption(1)
            }),
            UIAction(title: "Place (A-Z)", handler: { [weak self] _ in
                self?.updateSortOption(2)
            }),
            UIAction(title: "Place (Z-A)", handler: { [weak self] _ in
                self?.updateSortOption(3)
            })
        ])
        
        sortBy.menu = sortMenu
        sortBy.title = "Sort"
    }
    
    func setupFilterMenu() {
        let filterMenu = UIMenu(title: "Filter by", children: [
            UIAction(title: "All Visits", handler: { [weak self] _ in
                self?.updateFilterOption(0)
            }),
            UIAction(title: "Active Temples", handler: { [weak self] _ in
                self?.updateFilterOption(1)
            }),
            UIAction(title: "Historical Sites", handler: { [weak self] _ in
                self?.updateFilterOption(2)
            }),
            UIAction(title: "Visitors' Centers", handler: { [weak self] _ in
                self?.updateFilterOption(3)
            }),
            UIAction(title: "Temples Under Construction", handler: { [weak self] _ in
                self?.updateFilterOption(4)
            }),
            UIAction(title: "Other", handler: { [weak self] _ in
                self?.updateFilterOption(5)
            })
        ])
        
        filterBy.menu = filterMenu
        filterBy.title = "Filter"
    }
    
    func customizeSearchBarAppearance() {
        let baskervilleFont = UIFont(name: "Baskerville", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let baptismsBlue: UIColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        
        // Customize search text field font
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = baskervilleFont
        }
        
        // Customize scope button fonts
        searchController.searchBar.setScopeBarButtonTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .normal)
        
        searchController.searchBar.setScopeBarButtonTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .selected)
        
        // Customize cancel button font
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .normal)
    }
    
    func updateSortOption(_ option: Int) {
        sortOption = option
        updateTitle()
        
        // Reset data pull
        _fetchedResultsController = nil
        if searchController.isActive {
            // Reset filtered results based on updated pull
            let sel = searchController.searchBar.selectedScopeButtonIndex
            searchBar(searchController.searchBar, selectedScopeButtonIndexDidChange: sel)
        }
        self.tableView.reloadData()
    }
    
    func updateFilterOption(_ option: Int) {
        visitFilterRow = option
        updateTitle()
        
        // Reset data pull
        _fetchedResultsController = nil
        if searchController.isActive {
            // Reset filtered results based on updated pull
            let sel = searchController.searchBar.selectedScopeButtonIndex
            searchBar(searchController.searchBar, selectedScopeButtonIndexDidChange: sel)
        }
        self.tableView.reloadData()
    }
    
    func updateTitle() {
        // Set up title and subtitle
        var title = String()
        var subTitle = ""
        
        // Set title based on current filter
        switch visitFilterRow {
        case 0:
            title = "Visits"
        case 1:
            title = "Active Temples"
        case 2:
            title = "Historical Sites"
        case 3:
            title = "Visitors' Centers"
        case 4:
            title = "Construction"
        case 5:
            title = "Other Visits"
        default:
            title = "Visits"
        }
        
        // Set subtitle based on sort method
        subTitle = sortOptions[sortOption]
        
        // Check if there are search terms to determine which count to use
        let searchText = searchController.searchBar.text ?? ""
        let searchTerms = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        let count = !searchTerms.isEmpty ? filteredVisits.count : getVisitCount()
        
        // Determine color based on filter
        let titleColor: UIColor
        switch visitFilterRow {
        case 1:
            titleColor = templeColor
        case 2:
            titleColor = historicalColor
        case 4:
            titleColor = constructionColor
        case 5:
            titleColor = announcedColor
        case 3:
            titleColor = visitorCenterColor
        default:
            titleColor = defaultColor
        }
        
        // Update navigation title with color
        self.navigationItem.titleView = setTitle(title: "\(title) (\(count))", subtitle: subTitle, color: titleColor)
    }
    
    func getVisitCount() -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.reduce(0) { $0 + $1.numberOfObjects }
        }
        return 0
    }
    
    func setTitle(title: String, subtitle: String, color: UIColor = UIColor.label) -> UIView {
        // Replace titleView with custom version that includes sub title
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        let titleFont = UIFont(name: "Baskerville", size: 19) ?? UIFont.systemFont(ofSize: 19)
        let subTitleFont = UIFont(name: "Baskerville", size: 15) ?? UIFont.systemFont(ofSize: 15)
        
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = color
        titleLabel.font = titleFont
        titleLabel.text = title
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
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
    
    
    
    // Search Controller Code
    let searchController = UISearchController(searchResultsController: nil)
    var filteredVisits = [Visit]()
    var groupedFilteredVisits: [(section: String, visits: [Visit])] = []
    
    func groupFilteredVisits() {
        groupedFilteredVisits.removeAll()
        
        guard !filteredVisits.isEmpty else { return }
        
        switch sortOption {
        case 0, 1: // Date sorts - group by year
            let grouped = Dictionary(grouping: filteredVisits) { visit in
                let year = Calendar.current.component(.year, from: visit.dateVisited ?? Date())
                return "\(year)"
            }
            groupedFilteredVisits = grouped.map { (section: $0.key, visits: $0.value) }
                .sorted { 
                    if sortOption == 0 { // Latest Date
                        return Int($0.section)! > Int($1.section)!
                    } else { // Oldest Date
                        return Int($0.section)! < Int($1.section)!
                    }
                }
            
        case 2, 3: // Name sorts - group by FULL place name
            let grouped = Dictionary(grouping: filteredVisits) { visit in
                return visit.holyPlace! // Use the full place name as the section key
            }
            groupedFilteredVisits = grouped.map { (section: $0.key, visits: $0.value) }
                .sorted { 
                    if sortOption == 2 { // Place A-Z
                        return $0.section < $1.section
                    } else { // Place Z-A
                        return $0.section > $1.section
                    }
                }
            
        default:
            // Fallback to single section
            groupedFilteredVisits = [("Results", filteredVisits)]
        }
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        // Reset places to full array
        _fetchedResultsController = nil
        let allVisits = fetchedResultsController.fetchedObjects
        
        // Split search text into individual terms for AND search
        let searchTerms = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        // Search on Place name, comments, and date with AND logic
        filteredVisits = allVisits!.filter { visit in
            let categoryMatch = (scope == "All") || (scope == "B" && visit.baptisms > 0) || (scope == "C" && visit.confirmations > 0) || (scope == "I" && visit.initiatories > 0) || (scope == "E" && visit.endowments > 0) || (scope == "S" && visit.sealings > 0 || scope == "⭐️" && visit.isFavorite)
            
            guard categoryMatch else { return false }
            guard !searchTerms.isEmpty else { return true }
            
            // Create searchable text from all relevant fields
            let dateString = visit.dateVisited.map { formatter.string(from: $0) } ?? ""
            let searchableText = "\(visit.holyPlace ?? "") \(visit.comments ?? "") \(dateString)".lowercased()
            
            // AND search: all terms must be found in the searchable text
            return searchTerms.allSatisfy { term in
                searchableText.contains(term.lowercased())
            }
        }
        
        // Group the filtered results
        groupFilteredVisits()
        
        // Update title with correct count and color
        updateTitle()
        
        tableView.reloadData()
    }
    
    func getContext () -> NSManagedObjectContext {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return ad.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        formatter.dateFormat = "EEEE, MMMM dd, yyyy"
        
        // Setup sort menu
        setupSortMenu()
        
        // Setup filter menu
        setupFilterMenu()
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        // bug with following option in 13.1
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchBar.scopeButtonTitles = ["All", "B", "C", "I", "E", "S", "⭐️"]
        searchController.searchBar.delegate = self
        searchController.delegate = self
        
        // Customize search bar and scope button fonts
        customizeSearchBarAppearance()
        
        let defaults = UserDefaults.standard
        backupDate = defaults.object(forKey: "backupDate") as? Date
        backupReminder = defaults.object(forKey: "backupReminder") as? Date
        if backupDate?.daysBetweenDate(toDate: Date()) ?? 91 > 90
            && backupReminder?.daysBetweenDate(toDate: Date()) ?? 91 > 90
            && visits.count > 6 {
            let backupMsg = "To ensure you don't lose your entered visits due to unforeseen circumstances, back-up your visits to an XML file from time to time.\n\nClick the Export button in the top right corner to access this feature; See the FAQ for more details."
            let alert = UIAlertController(title: "IMPORTANT!", message: backupMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle OK (cancel) Logic here")
                defaults.set(Date(), forKey: "backupReminder")
            }))
            self.present(alert, animated: true)
        }
        
        // Add Done button to search bar keyboard
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        // Customize Done button font
        let baskervilleFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let baptismsBlue: UIColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        
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

        // Observer for widget deep link to open specific visit
        NotificationCenter.default.addObserver(self, selector: #selector(openVisitFromWidget(_:)), name: NSNotification.Name("OpenVisitFromWidget"), object: nil)
        
        // Create Select button for copy-to-profile feature (icon placed left of Sort/Filter)
        let selectImage = UIImage(named: "select")?.withRenderingMode(.alwaysTemplate)
        selectBarButton = UIBarButtonItem(image: selectImage, style: .plain, target: self, action: #selector(enterSelectMode))
        selectBarButton.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        selectBarButton.accessibilityLabel = "Select visits"
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("OpenVisitFromWidget"), object: nil)
    }

    @objc func openVisitFromWidget(_ notification: Notification) {
        guard let objectIDString = notification.object as? String else { return }

        // Prevent double navigation - only navigate if we're at the root
        guard let navController = navigationController,
              navController.viewControllers.count == 1 else {
            return
        }

        guard let url = URL(string: objectIDString),
              let objectID = ad.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {
            return
        }

        let context = getContext()
        do {
            let visit = try context.existingObject(with: objectID) as? Visit
            guard let visit = visit else { return }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let detailVC = storyboard.instantiateViewController(withIdentifier: "VisitDetailVC") as? VisitDetailVC else { return }

            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Visits", style: .done, target: nil, action: nil)
            detailVC.detailVisit = visit
            detailVC.navigationItem.leftItemsSupplementBackButton = true

            // Set up visitsInTable for swipe navigation (single visit)
            visitsInTable = [visit]
            selectedVisitRow = 0

            navController.pushViewController(detailVC, animated: true)
        } catch {
            // Visit was deleted - fallback to opening the place if we can get the name from the objectID
            // For now, just stay on Visits tab (user is already there)
        }
    }
    
    @objc func dismissKeyboard() {
        searchController.searchBar.resignFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        // Reload the data
        _fetchedResultsController = nil
        self.tableView.reloadData()
        
        // Update title with current sort option
        updateTitle()
        
        // Refresh Select button visibility based on profile state
        updateSelectButton()
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
        
        let defaults = UserDefaults.standard
        let hasRequestedReview = defaults.bool(forKey: "hasRequestedReview")
        let visitCount = getVisitCount()
        if !hasRequestedReview && visitCount >= 10 {
            if let scene = view.window?.windowScene {
                SKStoreReviewController.requestReview(in: scene)
                defaults.set(true, forKey: "hasRequestedReview")
            }
        }
        
        // Ensure search bar appearance is customized
        customizeSearchBarAppearance()

    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        customizeSearchBarAppearance()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Keep scope bar visible as long as search is active
        if searchController.isActive {
            searchBar.showsScopeBar = true
            searchBar.sizeToFit()
        } else {
            searchBar.showsScopeBar = false
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = false
    }
    
    // MARK: - Search Controller Delegate Methods
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
        customizeSearchBarAppearance()
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
        customizeSearchBarAppearance()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = false
    }

    func insertNewObject(_ sender: Any) {
        let context = self.fetchedResultsController.managedObjectContext
        let newVisit = Visit(context: context)
        
        // If appropriate, configure the new managed object.
        newVisit.dateVisited = Date()
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive {
            guard section < groupedFilteredVisits.count else { return nil }
            let group = groupedFilteredVisits[section]
            return "\(group.section) (\(group.visits.count))"
        } else {
            guard let sectionInfo = fetchedResultsController.sections?[section] else {
                return nil
            }
            return "\(sectionInfo.name) (\(sectionInfo.numberOfObjects))"
        }
        
    }
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Baskerville", size: 22)
        header.textLabel?.textColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.fetchedResultsController.fetchedObjects?.count != 0
        {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
        }
        else
        {
            let containerView = UIView(frame: tableView.bounds)

            let noDataLabel = UILabel()
            noDataLabel.translatesAutoresizingMaskIntoConstraints = false
            noDataLabel.text          = "Add Visits from the Place Details pages or selecting the Add button above.\n\nIMPORTANT!\n\nTo ensure you don't lose your entered visits due to unforeseen circumstances, back-up your visits to an XML file from time to time.\n\nClick the Export button in the top right corner to access this feature; See the FAQ for more details."
            noDataLabel.textColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
            noDataLabel.textAlignment = .center
            noDataLabel.font = UIFont(name: "Baskerville", size: 18)
            noDataLabel.numberOfLines = 0

            containerView.addSubview(noDataLabel)

            // Add padding with constraints
            NSLayoutConstraint.activate([
                noDataLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                noDataLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                noDataLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])

            tableView.backgroundView = containerView
            tableView.separatorStyle  = .none
        }
        if searchController.isActive {
            return groupedFilteredVisits.count
        } else {
            return self.fetchedResultsController.sections?.count ?? 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0 //Choose your custom row height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            guard section < groupedFilteredVisits.count else { return 0 }
            return groupedFilteredVisits[section].visits.count
        } else {
            let sectionInfo = self.fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visitCell", for: indexPath)
        var visit: Visit
        
        if searchController.isActive {
            guard indexPath.section < groupedFilteredVisits.count else { return cell }
            visit = groupedFilteredVisits[indexPath.section].visits[indexPath.row]
        } else {
            visit = self.fetchedResultsController.object(at: indexPath)
        }
        
        self.configureCell(cell, withVisit: visit)
        
        if isSelectMode {
            cell.accessoryType = selectedVisitIds.contains(visit.objectID) ? .checkmark : .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if searchController.isActive {
            return false
        }
        return true
    }
    
    //MARK: Swipe Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isSelectMode else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
        //let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // delete item at indexPath after confirming action
            let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to delete this visit?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }
            alert.addAction(cancelAction)
            let destroyAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                let context = self.fetchedResultsController.managedObjectContext
                context.delete(self.fetchedResultsController.object(at: indexPath))
                self.tableView.reloadData()
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
                // Update visit count for goal progress in Widget
                ad.needsVisitRefresh = true
                ad.getVisits()
            }
            alert.addAction(destroyAction)
            
            self.present(alert, animated: true) {
            }
        }
        
        let new = UIContextualAction(style: .destructive, title: "New") {  (contextualAction, view, boolValue) in
            // new item at indexPath
            let visit = self.fetchedResultsController.object(at: indexPath)
            // find Place based on name of Visit
            if let found = allPlaces.first(where:{$0.templeName == visit.holyPlace!}) {
                self.quickAddPlace  = found
                self.performSegue(withIdentifier: "quickRecordVisit", sender: nil)
            }
            
        }
        
        let copy = UIContextualAction(style: .destructive, title: "Copy") {  (contextualAction, view, boolValue) in
            // Copy item at indexPath
            copyVisit = self.fetchedResultsController.object(at: indexPath)
            // find Place based on name of Visit
            if let found = allPlaces.first(where:{$0.templeName == copyVisit!.holyPlace!}) {
                self.quickAddPlace  = found
                self.performSegue(withIdentifier: "quickRecordVisit", sender: nil)
            }
            
        }

        new.backgroundColor = UIColor.blue
        copy.backgroundColor = UIColor.moss()
        
        return UISwipeActionsConfiguration(actions: [new, copy, delete])
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(self.fetchedResultsController.object(at: indexPath))
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            // Update visit count for goal progress in Widget
            ad.needsVisitRefresh = true
            ad.getVisits()
        }
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isSelectMode else { return }
        let visit: Visit
        if searchController.isActive {
            guard indexPath.section < groupedFilteredVisits.count else { return }
            visit = groupedFilteredVisits[indexPath.section].visits[indexPath.row]
        } else {
            visit = fetchedResultsController.object(at: indexPath)
        }
        if selectedVisitIds.contains(visit.objectID) {
            selectedVisitIds.remove(visit.objectID)
        } else {
            selectedVisitIds.insert(visit.objectID)
        }
        copyToProfileBarButton.isEnabled = !selectedVisitIds.isEmpty
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if isSelectMode && identifier == "visitDetail" { return false }
        return true
    }
    
    func configureCell(_ cell: UITableViewCell, withVisit visit: Visit) {
        cell.textLabel!.text = visit.holyPlace
        
        var ordinances = " ~"
        
        // Determine Ordinances performed for summary
        if visit.baptisms > 0 {
            ordinances.append(" B")
        }
        if visit.confirmations > 0 {
            ordinances.append(" C")
        }
        if visit.initiatories > 0 {
            ordinances.append(" I")
        }
        if visit.endowments > 0 {
            ordinances.append(" E")
        }
        if visit.sealings > 0 {
            ordinances.append(" S")
        }
        if visit.shiftHrs > 0 {
            ordinances.append(" \(visit.shiftHrs) hrs")
        }
        // If no ordinaces appended, blank out the variable, otherwise add closing bracket
        if ordinances == " ~" {
            ordinances = ""
        }
        
        if visit.picture != nil {
            ordinances.append("  📷")
        }
        
        if visit.isFavorite {
            ordinances.append( "   ⭐")
        }
        
        if let dateVisited = visit.dateVisited {
            cell.detailTextLabel?.text = " " + formatter.string(from: dateVisited) + ordinances
        } else {
            cell.detailTextLabel?.text = " (no date)" + ordinances
        }
        cell.textLabel?.font = UIFont(name: "Baskerville", size: 18)
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.7
        cell.detailTextLabel?.font = UIFont(name: "Baskerville", size: 14)
        cell.detailTextLabel?.textColor = defaultColor
        if let theType = visit.type {
            switch theType {
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
        }
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Visit> {
        
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        let managedObjectContext = getContext()
        
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate based on sortOption
        var sortDescriptors: [NSSortDescriptor] = []
        
        switch sortOption {
        case 0: // Latest Date
            sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        case 1: // Oldest Date
            sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: true)]
        case 2: // Place A-Z
            sortDescriptors = [NSSortDescriptor(key: "holyPlace", ascending: true)]
        case 3: // Place Z-A
            sortDescriptors = [NSSortDescriptor(key: "holyPlace", ascending: false)]
        default:
            sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        }
        
        fetchRequest.sortDescriptors = sortDescriptors
        
//        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Build profile predicate
        var predicates: [NSPredicate] = []
        if profilesEnabled, let pid = activeProfileId {
            predicates.append(NSPredicate(format: "profileId == %@", pid))
        }
        
        // Filter the request
        switch visitFilterRow {
        case 0:
            titleHeader = "Visits"
        case 1:
            titleHeader = "Active Temples"
            predicates.append(NSPredicate(format: "type == %@", "T"))
        case 2:
            titleHeader = "Historical"
            predicates.append(NSPredicate(format: "type == %@", "H"))
        case 3:
            titleHeader = "Visitors' Centers"
            predicates.append(NSPredicate(format: "type == %@", "V"))
        case 4:
            titleHeader = "Construction"
            predicates.append(NSPredicate(format: "type == %@", "C"))
        case 5:
            titleHeader = "Other Visits"
            predicates.append(NSPredicate(format: "type == %@", "O"))
        default:
            titleHeader = "Visits"
        }
        
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        var sectionNameKeyPath: String?
        
        switch sortOption {
        case 0, 1: // Latest Date, Oldest Date
            sectionNameKeyPath = "year"
        case 2, 3: // Place A-Z, Place Z-A
            sectionNameKeyPath = "holyPlace"
        default:
            sectionNameKeyPath = "year"
        }
        
        if searchController.isActive {
            sectionNameKeyPath = nil
        }
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)        
        
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        // Update title with correct count
        updateTitle()
        
        var titleDict = NSDictionary()
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)

        switch visitFilterRow {
        case 1:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: templeColor]
        case 2:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: historicalColor]
        case 4:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: constructionColor]
        case 3:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: visitorCenterColor]
        default:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: defaultColor]
        }

        self.navigationController!.navigationBar.titleTextAttributes = titleDict as? [NSAttributedString.Key : AnyObject]

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Visit>? = nil
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
    
    //MARK: - Navigation
    func quickAddVisit(shortcutIdentifier: ShortcutIdentifier) -> Bool {
        if shortcutIdentifier == .RecordVisit {
            quickAddPlace = quickLaunchItem
        } else {
            if notificationData?.value(forKey: "place") != nil {
                if let found = allPlaces.first(where:{$0.templeName == (notificationData?.value(forKey: "place"))! as! String}) {
                    quickAddPlace  = found
                    placeFromNotification = quickAddPlace?.templeName
                    dateFromNotification = (notificationData?.value(forKey: "dateVisited"))! as? Date
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
        performSegue(withIdentifier: "quickRecordVisit", sender: nil)
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "visitDetail" {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Visits", style: .done, target: nil, action: nil)
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destination as! VisitDetailVC)
                if searchController.isActive {
                    guard indexPath.section < groupedFilteredVisits.count else { return }
                    let visit = groupedFilteredVisits[indexPath.section].visits[indexPath.row]
                    visitsInTable = filteredVisits
                    controller.detailVisit = visit
                    selectedVisitRow = indexPath.row
                } else {
                    let visit = self.fetchedResultsController.object(at: indexPath)
                    visitsInTable = fetchedResultsController.fetchedObjects!
                    controller.detailVisit = visit
                    selectedVisitRow = visitsInTable.firstIndex(where:{$0.holyPlace == visit.holyPlace && $0.dateVisited == visit.dateVisited})!
                }
                
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
        if segue.identifier == "showVisitOptions" {
            let controller: VisitOptionsVC = segue.destination as! VisitOptionsVC
            controller.delegateOptions = self
            searchController.isActive = false
        }
        if segue.identifier == "quickRecordVisit" {
            // Change the back button on the Record Visit VC to Cancel
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
            let temple = quickAddPlace
            let controller = (segue.destination as! RecordVisitVC)
            controller.detailItem = temple
        }
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
        guard let input = input else { return nil }
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
    }
    
    // MARK: - Copy to Profile
    
    private var canCopyToProfile: Bool {
        return profilesEnabled && ProfileManager.shared.allProfiles().count >= 2
    }
    
    private func updateSelectButton() {
        guard !isSelectMode else { return }
        var items = navigationItem.rightBarButtonItems ?? []
        let alreadyPresent = items.contains(where: { $0 === selectBarButton })
        if canCopyToProfile {
            if !alreadyPresent {
                items.append(selectBarButton)
                navigationItem.rightBarButtonItems = items
            }
        } else {
            if alreadyPresent {
                items.removeAll(where: { $0 === selectBarButton })
                navigationItem.rightBarButtonItems = items
            }
        }
    }
    
    @objc private func enterSelectMode() {
        isSelectMode = true
        selectedVisitIds.removeAll()
        
        savedLeftBarButtonItems = navigationItem.leftBarButtonItems
        savedRightBarButtonItems = navigationItem.rightBarButtonItems
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(exitSelectMode))
        
        let selectAllImage = UIImage(named: "select")?.withRenderingMode(.alwaysTemplate)
        selectAllBarButton = UIBarButtonItem(image: selectAllImage, style: .plain, target: self, action: #selector(selectAllVisits))
        selectAllBarButton.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        selectAllBarButton.accessibilityLabel = "Select all"
        
        copyToProfileBarButton = UIBarButtonItem(title: "Copy to Profile\u{2026}", style: .plain, target: self, action: #selector(copySelectedToProfile))
        copyToProfileBarButton.isEnabled = false
        
        navigationItem.leftBarButtonItems = [cancelButton]
        navigationItem.rightBarButtonItems = [selectAllBarButton, copyToProfileBarButton]
        
        tableView.allowsMultipleSelection = true
        tableView.reloadData()
    }
    
    @objc func exitSelectMode() {
        isSelectMode = false
        selectedVisitIds.removeAll()
        
        navigationItem.leftBarButtonItems = savedLeftBarButtonItems
        navigationItem.rightBarButtonItems = savedRightBarButtonItems
        savedLeftBarButtonItems = nil
        savedRightBarButtonItems = nil
        
        tableView.allowsMultipleSelection = false
        tableView.reloadData()
    }
    
    private func visibleVisits() -> [Visit] {
        if searchController.isActive {
            return filteredVisits
        }
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    @objc private func selectAllVisits() {
        let visible = visibleVisits()
        let allAlreadySelected = !visible.isEmpty && visible.allSatisfy { selectedVisitIds.contains($0.objectID) }
        if allAlreadySelected {
            visible.forEach { selectedVisitIds.remove($0.objectID) }
        } else {
            visible.forEach { selectedVisitIds.insert($0.objectID) }
        }
        copyToProfileBarButton.isEnabled = !selectedVisitIds.isEmpty
        tableView.reloadData()
    }
    
    @objc private func copySelectedToProfile() {
        guard !selectedVisitIds.isEmpty else { return }
        let context = fetchedResultsController.managedObjectContext
        let visits = selectedVisitIds.compactMap { try? context.existingObject(with: $0) as? Visit }
        guard !visits.isEmpty else { return }
        showProfilePicker(for: visits)
    }
    
    private func showProfilePicker(for visits: [Visit]) {
        let visitWord = visits.count == 1 ? "this visit" : "\(visits.count) visits"
        let alert = UIAlertController(
            title: "Copy to Profile",
            message: "Select a profile to copy \(visitWord) to:",
            preferredStyle: .actionSheet
        )
        
        let allProfiles = ProfileManager.shared.allProfiles()
        let otherProfiles = allProfiles.filter { ($0.value(forKey: "profileId") as? String) != activeProfileId }
        
        for profile in otherProfiles {
            guard let profileId = profile.value(forKey: "profileId") as? String,
                  let name = profile.value(forKey: "name") as? String else { continue }
            let iconName = profile.value(forKey: "iconName") as? String ?? "person.fill"
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.copyVisits(visits, toProfileId: profileId)
                let inSelectMode = self.isSelectMode
                if inSelectMode { self.exitSelectMode() }
                self.showCopySuccessMessage(count: visits.count, profileName: name)
            }
            if let image = UIImage(systemName: iconName) {
                action.setValue(image.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func copyVisits(_ visits: [Visit], toProfileId: String) {
        let context = fetchedResultsController.managedObjectContext
        for source in visits {
            let copy = Visit(context: context)
            copy.holyPlace = source.holyPlace
            copy.dateVisited = source.dateVisited
            copy.year = source.year
            copy.type = source.type
            copy.profileId = toProfileId
            copy.baptisms = source.baptisms
            copy.confirmations = source.confirmations
            copy.initiatories = source.initiatories
            copy.endowments = source.endowments
            copy.sealings = source.sealings
            copy.shiftHrs = source.shiftHrs
            copy.comments = source.comments
            copy.picture = source.picture
            copy.isFavorite = source.isFavorite
        }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            print("Error saving copied visits: \(nserror)")
        }
        ad.needsVisitRefresh = true
        ad.getVisits()
    }
    
    private func showCopySuccessMessage(count: Int, profileName: String) {
        let visitWord = count == 1 ? "visit" : "visits"
        let alert = UIAlertController(
            title: "Visits Copied",
            message: "\(count) \(visitWord) copied to \(profileName).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
