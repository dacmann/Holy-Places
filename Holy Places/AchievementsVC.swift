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
        switch display[row].iconName.suffix(1) {
        case "B":
            cell.cellTitle.textColor = UIColor(named: "BaptismsBlue")
            cell.cellProgress.tintColor = UIColor(named: "BaptismsBlue")
        case "I":
            cell.cellTitle.textColor = UIColor(named: "InitiatoriesOlive")!
            cell.cellProgress.tintColor = UIColor(named: "InitiatoriesOlive")!
        case "E":
            cell.cellTitle.textColor = UIColor.darkTangerine()
            cell.cellProgress.tintColor = UIColor.darkTangerine()
        case "S":
            cell.cellTitle.textColor = UIColor(named: "SealingsPurple")!
            cell.cellProgress.tintColor = UIColor(named: "SealingsPurple")!
        case "W":
            cell.cellTitle.textColor = UIColor.iron()
            cell.cellProgress.tintColor = UIColor.iron()
        case "H":
            cell.cellTitle.textColor = UIColor.darkLimeGreen()
            cell.cellProgress.tintColor = UIColor.darkLimeGreen()
        case "T":
            cell.cellTitle.textColor = UIColor(named: "TempleDarkRed")
            cell.cellProgress.tintColor = UIColor(named: "TempleDarkRed")
        default:
            cell.cellTitle.textColor = UIColor(named: "DefaultText")!
            cell.cellProgress.tintColor = UIColor(named: "DefaultText")!
        }
        if let placeAchieved = display[row].placeAchieved {
            cell.cellDetails.text = display[row].details
            cell.cellPlaceAchieved.text = "at \(placeAchieved)"
            cell.cellPlaceAchieved.isHidden = false
            cell.cellProgress.isHidden = true
            switch display[row].iconName.suffix(1) {
            case "H":
                cell.cellPlaceAchieved.textColor = UIColor.darkLimeGreen()
            default:
                cell.cellPlaceAchieved.textColor = UIColor(named: "TempleDarkRed")
            }
        } else {
            cell.cellDetails.text = "\(display[row].details) ~ \(display[row].remaining ?? 0) more"
            cell.cellPlaceAchieved.text = ""
            cell.cellPlaceAchieved.isHidden = true
            cell.cellProgress.isHidden = false
            cell.cellProgress.progress = display[row].progress!
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
            noDataLabel.textColor     = UIColor(named: "BaptismsBlue")
            noDataLabel.textAlignment = .center
            noDataLabel.font = UIFont(name: "Baskerville", size: 18)
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return display.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if display[indexPath.row].placeAchieved == nil {
            return 65.0
        } else {
            return 100.0 //Choose your custom row height
        }
    }

    @IBAction func doneButton(_ sender: UIBarButtonItem) {
     // Dismiss view
     self.dismiss(animated: true, completion: nil)
 }

}
