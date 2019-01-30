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
    
    var display: [Achievement] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Achievements"

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
        if completed.count == 0 {
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = "No Achievements Yet 😕"
            noDataLabel.textColor     = UIColor.ocean()
            noDataLabel.textAlignment = .center
            noDataLabel.font = UIFont(name: "Baskerville", size: 18)
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
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
