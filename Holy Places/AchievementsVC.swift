//
//  AchievementsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 10/11/18.
//  Copyright © 2018 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData



class AchievementsVC: UITableViewController, NSFetchedResultsControllerDelegate {

   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Achievements"
    }

    // MARK: - Table view data source
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func determineAchievements() {
//        var achievementDate = Date()
//        var achievementPlace = String()
//
//        do {
//
//            // Loop through places visited
//            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
//            fetchRequest.predicate = nil
//            var searchResults = try getContext().fetch(fetchRequest)
//            var distinct = NSSet(array: searchResults.map { $0.holyPlace! })
//
//
//
//        }  catch {
//            print("Error with request: \(error)")
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, YYYY"
        let cell  = tableView.dequeueReusableCell(withIdentifier: "acell", for: indexPath) as! AchievementCell
        let row = indexPath.row
        cell.cellTitle.text = achievements[row].name
        cell.cellDetails.text = achievements[row].details
        cell.cellPlaceAchieved.text = "at \(achievements[row].placeAchieved)"
        cell.cellDateAchieved.text = "on \(formatter.string(from: achievements[row].achieved))"
        guard ((cell.cellImage?.image = UIImage(imageLiteralResourceName: achievements[row].iconName)) != nil) else {
            return cell
        }

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return achievements.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 100.0 //Choose your custom row height
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    // MARK: - Navigation

 @IBAction func doneButton(_ sender: UIBarButtonItem) {
     // Dismiss view
     self.dismiss(animated: true, completion: nil)
 }

}
