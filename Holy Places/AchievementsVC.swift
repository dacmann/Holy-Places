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

    
    var completed: [Achievement] = []
    var notCompleted: [Achievement] = []
    var display: [Achievement] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Achievements"
        // divide array into achieved and not achieved
        completed = achievements.filter { if $0.achieved != nil {
            return true
        } else {
            return false
            }
        }
        notCompleted = achievements.filter { if $0.achieved == nil {
            return true
        } else {
            return false
            }
        }
        // sort the achievements by date achieved
        completed.sort(by: { $0.achieved?.compare(($1.achieved)!) == .orderedDescending })
        // Default to display the completed achievements
        display = completed
    }

    // MARK: - Table view data source
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, YYYY"
        let cell  = tableView.dequeueReusableCell(withIdentifier: "acell", for: indexPath) as! AchievementCell
        let row = indexPath.row
        cell.cellTitle.text = display[row].name
        cell.cellDetails.text = display[row].details
        if let placeAchieved = display[row].placeAchieved {
            cell.cellPlaceAchieved.text = "at \(placeAchieved)"
            cell.cellPlaceAchieved.isHidden = false
        } else {
            cell.cellPlaceAchieved.text = ""
            cell.cellPlaceAchieved.isHidden = true
        }
        if let dateAchieved = display[row].achieved {
            cell.cellDateAchieved.text = "on \(formatter.string(from: dateAchieved))"
            cell.cellDateAchieved.isHidden = false
        } else {
            cell.cellDateAchieved.text = ""
            cell.cellDateAchieved.isHidden = true
        }
        if let iconImage = UIImage(named: display[row].iconName) {
            // image exists
            cell.cellImage?.image = iconImage
        } else {
            cell.cellImage?.image = nil
        }
        // dim image
        cell.imageView?.alpha = 0.5

        return cell
    }
    @IBAction func changeDisplay(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            display = notCompleted
        } else {
            display = completed
        }
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return display.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if display[indexPath.row].placeAchieved == nil {
            return 55.0
        } else {
            return 100.0 //Choose your custom row height
        }
    }

    @IBAction func doneButton(_ sender: UIBarButtonItem) {
     // Dismiss view
     self.dismiss(animated: true, completion: nil)
 }

}
