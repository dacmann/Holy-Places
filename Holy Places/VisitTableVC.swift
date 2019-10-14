//
//  VisitTableVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/13/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let formatter = DateFormatter()
    var sortByDate = true
    
    @IBOutlet weak var sortBy: UIBarButtonItem!
    @IBAction func sortByBtn(_ sender: Any) {
        if sortByDate {
            sortByDate = false
            sortBy.title = "by Date"
        } else {
            sortByDate = true
            sortBy.title = "by Place"
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
            let categoryMatch = (scope == "All") || (scope == "B" && visit.baptisms > 0) || (scope == "C" && visit.confirmations > 0) || (scope == "I" && visit.initiatories > 0) || (scope == "E" && visit.endowments > 0) || (scope == "S" && visit.sealings > 0)
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
            self.navigationItem.titleView?.tintColor = UIColor(named: "TempleDarkRed")
        case 2:
            self.navigationItem.titleView?.tintColor = UIColor.darkLimeGreen()
        case 4:
            self.navigationItem.titleView?.tintColor = UIColor.darkOrange()
        case 5:
            self.navigationItem.titleView?.tintColor = UIColor.brown
        case 3:
            self.navigationItem.titleView?.tintColor = UIColor.strongYellow()
        default:
            self.navigationItem.titleView?.tintColor = UIColor(named: "DefaultText")!
        }
        
        tableView.reloadData()
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        formatter.dateFormat = "EEEE, MMMM dd, YYYY"
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.tintColor = UIColor(named: "BaptismsBlue")
        let searchBarFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        searchController.searchBar.setScopeBarButtonTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.font.rawValue: searchBarFont, NSAttributedString.Key.foregroundColor.rawValue:UIColor(named: "BaptismsBlue")!]), for: UIControl.State.normal)

        let textFieldInsideUISearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        extendedLayoutIncludesOpaqueBars = true
        
        searchController.searchBar.scopeButtonTitles = ["All", "B", "C", "I", "E", "S"]
        searchController.searchBar.delegate = self
        
        // Add done button to keyboard
        keyboardDone()
    }

    override func viewWillAppear(_ animated: Bool) {
        // Reload the data
        _fetchedResultsController = nil
        self.tableView.reloadData()
        
        // Change the font and color for the navigation Bar text
        let barbuttonFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)
        if #available(iOS 13.0, *) {
            let style = UINavigationBarAppearance()
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
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = "Add Visits from the Place Details pages"
            noDataLabel.textColor     = UIColor(named: "BaptismsBlue")
            noDataLabel.textAlignment = .center
            noDataLabel.font = UIFont(name: "Baskerville", size: 18)
            tableView.backgroundView  = noDataLabel
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
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
                self.appDelegate.getVisits()
            }
            alert.addAction(destroyAction)
            
            self.present(alert, animated: true) {
            }
        }
        
        let new = UITableViewRowAction(style: .normal, title: "New") { (action, indexPath) in
            // new item at indexPath
            let visit = self.fetchedResultsController.object(at: indexPath)
            // find Place based on name of Visit
            if let found = allPlaces.first(where:{$0.templeName == visit.holyPlace!}) {
                self.quickAddPlace  = found
                self.performSegue(withIdentifier: "quickRecordVisit", sender: nil)
            }
            
        }
        
        let copy = UITableViewRowAction(style: .normal, title: "Copy") { (action, indexPath) in
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
        
        return [new, copy, delete]
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
            appDelegate.getVisits()
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
        
        cell.detailTextLabel?.text = " " + formatter.string(from: visit.dateVisited! as Date) + ordinances
        cell.textLabel?.font = UIFont(name: "Baskerville", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Baskerville", size: 14)
        cell.detailTextLabel?.textColor = UIColor(named: "DefaultText")!
        if let theType = visit.type {
            switch theType {
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
            titleHeader = "Holy Places Visits"
        case 1:
            titleHeader = "Active Temples Visits"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
        case 2:
            titleHeader = "Historical Sites Visits"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
        case 3:
            titleHeader = "Visitors' Centers Visits"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "V")
        case 4:
            titleHeader = "Construction Visits"
            fetchRequest.predicate = NSPredicate(format: "type == %@", "C")
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
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: UIColor(named: "TempleDarkRed")!]
        case 2:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: UIColor.darkLimeGreen()]
        case 4:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: UIColor.darkOrange()]
        case 3:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: UIColor.strongYellow()]
        default:
            titleDict = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor: UIColor(named: "DefaultText")!]
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
            if notificationData != nil {
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
