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

class VisitTableVC: UITableViewController, SendVisitOptionsDelegate, NSFetchedResultsControllerDelegate {
    
    var titleHeader = String()
    var quickAddPlace: Temple?
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let formatter = DateFormatter()
    var sortByDate = true
    var backupDate: Date?
    var backupReminder: Date?
    
    @IBOutlet weak var sortBy: UIBarButtonItem!
    @IBAction func sortByBtn(_ sender: Any) {
        if sortByDate {
            sortByDate = false
            //sortBy.title = "by Date"
        } else {
            sortByDate = true
            //sortBy.title = "by Place"
        }
        // reset data pull
        _fetchedResultsController = nil
        if searchController.isActive {
            // reset filtered results based on updated pull
            let sel = searchController.searchBar.selectedScopeButtonIndex
            searchBar(searchController.searchBar, selectedScopeButtonIndexDidChange: sel)
        }
        self.tableView.reloadData()
    }
    
    // Set variable based on Filter Option selected on Options view
    func FilterOptions(row: Int) {
        visitFilterRow = row
    }
    
    // Set variables based on Sort Option selected on Options view
    func SortOptions(row: Int) {
        visitSortRow = row
    }
    
    // Search Controller Code
    let searchController = UISearchController(searchResultsController: nil)
    var filteredVisits = [Visit]()
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        // Reset places to full array
        _fetchedResultsController = nil
        let allVisits = fetchedResultsController.fetchedObjects
        // Search on Place name or comments
        filteredVisits = allVisits!.filter { visit in
            let categoryMatch = (scope == "All") || (scope == "B" && visit.baptisms > 0) || (scope == "C" && visit.confirmations > 0) || (scope == "I" && visit.initiatories > 0) || (scope == "E" && visit.endowments > 0) || (scope == "S" && visit.sealings > 0 || scope == "⭐️" && visit.isFavorite)
            return categoryMatch && ((visit.holyPlace?.lowercased().contains(searchText.lowercased()))! || (visit.comments?.lowercased().contains(searchText.lowercased()))! || (formatter.string(from: visit.dateVisited! as Date).lowercased().contains(searchText.lowercased())) || searchText.isEmpty)
        }
        // Update title
        if searchController.isActive {
            self.navigationItem.title = titleHeader + " (" + (filteredVisits.count.description) + ")"
        } else {
            self.navigationItem.title = titleHeader + " (" + (self.fetchedResultsController.fetchedObjects?.count.description)! + ")"
        }
        
        switch visitFilterRow {
        case 1:
            self.navigationItem.titleView?.tintColor = templeColor
        case 2:
            self.navigationItem.titleView?.tintColor = historicalColor
        case 4:
            self.navigationItem.titleView?.tintColor = constructionColor
        case 5:
            self.navigationItem.titleView?.tintColor = announcedColor
        case 3:
            self.navigationItem.titleView?.tintColor = visitorCenterColor
        default:
            self.navigationItem.titleView?.tintColor = defaultColor
        }
        
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
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        // bug with following option in 13.1
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.tintColor = UIColor(named: "BaptismsBlue")
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchBar.scopeButtonTitles = ["All", "B", "C", "I", "E", "S", "⭐️"]
        searchController.searchBar.delegate = self
        
        let defaults = UserDefaults.standard
        backupDate = defaults.object(forKey: "backupDate") as? Date
        backupReminder = defaults.object(forKey: "backupReminder") as? Date
        if backupDate?.daysBetweenDate(toDate: Date()) ?? 91 > 90
            && backupReminder?.daysBetweenDate(toDate: Date()) ?? 91 > 90
            && visits.count > 6 {
            let backupMsg = "To ensure you don't lose your entered visits due to unforeseen circumstances, back-up your visits to an XML file from time to time.\n\nClick the Options button above to access this feature; check out the FAQ for more details."
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
        keyboardToolbar.items = [flexSpace, doneButton]

        searchController.searchBar.inputAccessoryView = keyboardToolbar

    }
    
    @objc func dismissKeyboard() {
        searchController.searchBar.resignFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        // Reload the data
        _fetchedResultsController = nil
        self.tableView.reloadData()

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
        if !hasRequestedReview && visits.count >= 10 {
            if let scene = view.window?.windowScene {
                SKStoreReviewController.requestReview(in: scene)
                defaults.set(true, forKey: "hasRequestedReview")
            }
        }

    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsScopeBar = false
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
            return nil
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
        header.textLabel?.textColor = UIColor(named: "BaptismsBlue")
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
            noDataLabel.text          = "Add Visits from the Place Details pages or selecting the Add button above.\n\nIMPORTANT!\n\nTo ensure you don't lose your entered visits due to unforeseen circumstances, back-up your visits to an XML file from time to time.\n\nClick the Options button above to access this feature; check out the FAQ for more details."
            noDataLabel.textColor = UIColor(named: "BaptismsBlue")
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
            return 1
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
            return filteredVisits.count
        } else {
            let sectionInfo = self.fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visitCell", for: indexPath)
        var visit = self.fetchedResultsController.object(at: indexPath)
        if searchController.isActive {
            visit = filteredVisits[indexPath.row]
        }
        self.configureCell(cell, withVisit: visit)
        
        cell.accessoryType = .disclosureIndicator
        
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
            ad.getVisits()
        }
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
        
        cell.detailTextLabel?.text = " " + formatter.string(from: visit.dateVisited! as Date) + ordinances
        cell.textLabel?.font = UIFont(name: "Baskerville", size: 18)
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
        
        // Edit the sort key as appropriate.
        var sortDescriptor = NSSortDescriptor(key: "holyPlace", ascending: true)
        if sortByDate {
            sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
        } else {
            let sortDescriptor2 = NSSortDescriptor(key: "dateVisited", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor, sortDescriptor2]
        }
        
//        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Filter the request
        switch visitFilterRow {
        case 0:
            titleHeader = "Visits"
        case 1:
            titleHeader = "Active Temples"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
        case 2:
            titleHeader = "Historical"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
        case 3:
            titleHeader = "Visitors' Centers"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "V")
        case 4:
            titleHeader = "Construction Visits"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "C")
        case 5:
            titleHeader = "Other Visits"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "O")
        default:
            titleHeader = "Visits"
        }
        
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        var aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "holyPlace", cacheName: nil)
        if sortByDate {
            aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "year", cacheName: nil)
        }
        if searchController.isActive {
            aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        }        
        
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
        
        // Update title
        if searchController.isActive {
            self.navigationItem.title = titleHeader + " (" + (filteredVisits.count.description) + ")"
        } else {
            self.navigationItem.title = titleHeader + " (" + (self.fetchedResultsController.fetchedObjects?.count.description)! + ")"
        }
        
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
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            print("update") // This is causing a crash when the results are filtered with a search - disabling it doesn't seem to cause an issue
//            self.configureCell(tableView.cellForRow(at: indexPath!)!, withVisit: anObject as! Visit)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            print("Not handled")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
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
                    let visit = filteredVisits[indexPath.row]
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
            controller.sortSelected = visitSortRow
            controller.filterSelected = visitFilterRow
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

}
