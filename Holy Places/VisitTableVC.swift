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
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

class VisitTableVC: UITableViewController, SendVisitOptionsDelegate, NSFetchedResultsControllerDelegate {
    
    var titleHeader = String()
    var quickAddPlace: Temple?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let formatter = DateFormatter()
    
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
        let allVisits = fetchedResultsController.fetchedObjects
        // Search on Place name or comments
        filteredVisits = allVisits!.filter { visit in
            return ((visit.holyPlace?.lowercased().contains(searchText.lowercased()))! || (visit.comments?.lowercased().contains(searchText.lowercased()))! || (formatter.string(from: visit.dateVisited! as Date).lowercased().contains(searchText.lowercased())))
        }
        // Update title
        if searchController.isActive && searchController.searchBar.text != "" {
            self.navigationItem.title = titleHeader + " (" + (filteredVisits.count.description) + ")"
        } else {
            self.navigationItem.title = titleHeader + " (" + (self.fetchedResultsController.fetchedObjects?.count.description)! + ")"
        }
        
        switch visitFilterRow {
        case 1:
            self.navigationItem.titleView?.tintColor = UIColor.darkRed()
        case 2:
            self.navigationItem.titleView?.tintColor = UIColor.darkLimeGreen()
        case 4:
            self.navigationItem.titleView?.tintColor = UIColor.darkOrange()
        case 3:
            self.navigationItem.titleView?.tintColor = UIColor.strongYellow()
        default:
            self.navigationItem.titleView?.tintColor = UIColor.lead()
        }
        
        tableView.reloadData()
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        formatter.dateFormat = "EEEE, MMMM dd, YYYY"
        
        // Search Controller Stuff
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        let textFieldInsideUISearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        definesPresentationContext = true
        if #available(iOS 11.0, *) {
            // New in iOS 11, the searchbar is part of the navigationItem
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Fallback on earlier versions
            tableView.tableHeaderView = searchController.searchBar
        }
        extendedLayoutIncludesOpaqueBars = true
    }

    override func viewWillAppear(_ animated: Bool) {
        // Reload the data
        _fetchedResultsController = nil
        self.tableView.reloadData()
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
            noDataLabel.textColor     = UIColor.ocean()
            noDataLabel.textAlignment = .center
            noDataLabel.font = UIFont(name: "Baskerville", size: 18)
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0 //Choose your custom row height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredVisits.count
        } else {
            let sectionInfo = self.fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visitCell", for: indexPath)
        var visit = self.fetchedResultsController.object(at: indexPath)
        if searchController.isActive && searchController.searchBar.text != "" {
            visit = filteredVisits[indexPath.row]
        }
        self.configureCell(cell, withVisit: visit)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
        cell.detailTextLabel?.textColor = UIColor.lead()
        if let theType = visit.type {
            switch theType {
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
        let sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
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
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
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
        if searchController.isActive && searchController.searchBar.text != "" {
            self.navigationItem.title = titleHeader + " (" + (filteredVisits.count.description) + ")"
        } else {
            self.navigationItem.title = titleHeader + " (" + (self.fetchedResultsController.fetchedObjects?.count.description)! + ")"
        }
        
        var titleDict = NSDictionary()
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)

        switch visitFilterRow {
        case 1:
            titleDict = [NSAttributedStringKey.font: navbarFont, NSAttributedStringKey.foregroundColor: UIColor.darkRed()]
        case 2:
            titleDict = [NSAttributedStringKey.font: navbarFont, NSAttributedStringKey.foregroundColor: UIColor.darkLimeGreen()]
        case 4:
            titleDict = [NSAttributedStringKey.font: navbarFont, NSAttributedStringKey.foregroundColor: UIColor.darkOrange()]
        case 3:
            titleDict = [NSAttributedStringKey.font: navbarFont, NSAttributedStringKey.foregroundColor: UIColor.strongYellow()]
        default:
            titleDict = [NSAttributedStringKey.font: navbarFont, NSAttributedStringKey.foregroundColor: UIColor.lead()]
        }

        self.navigationController!.navigationBar.titleTextAttributes = titleDict as? [NSAttributedStringKey : AnyObject]

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
                if searchController.isActive && searchController.searchBar.text != "" {
                    let visit = filteredVisits[indexPath.row]
                    visitsInTable = filteredVisits
                    controller.detailVisit = visit
                } else {
                    let visit = self.fetchedResultsController.object(at: indexPath)
                    visitsInTable = fetchedResultsController.fetchedObjects!
                    controller.detailVisit = visit
                }
                selectedVisitRow = indexPath.row
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


}
