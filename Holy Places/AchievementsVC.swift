//
//  AchievementsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 10/11/18.
//  Copyright © 2018 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import SafariServices



class AchievementsVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var display: [Achievement] = []
    private var showingCompleted = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Achievements"

        // Default to display the completed achievements
        display = completed
        tableView.tableHeaderView = makeCelebrationBoardHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload from globals so profile changes are reflected immediately
        display = showingCompleted ? completed : notCompleted
        tableView.reloadData()
    }

    // MARK: - Table view data source
    func getContext () -> NSManagedObjectContext {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return ad.persistentContainer.viewContext
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        let cell  = tableView.dequeueReusableCell(withIdentifier: "acell", for: indexPath) as! AchievementCell
        let row = indexPath.row
        let achievement = display[row]
        cell.cellTitle.text = achievement.name
        switch achievement.iconName.suffix(1) {
        case "B":
            cell.cellTitle.textColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
            cell.cellProgress.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
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
            cell.cellTitle.textColor = historicalColor
            cell.cellProgress.tintColor = historicalColor
        case "T":
            cell.cellTitle.textColor = templeColor
            cell.cellProgress.tintColor = templeColor
        default:
            cell.cellTitle.textColor = templeColor
            cell.cellProgress.tintColor = templeColor
        }
        if let placeAchieved = achievement.placeAchieved {
            cell.cellDetails.text = achievement.details
            cell.cellPlaceAchieved.text = "at \(placeAchieved)"
            cell.cellPlaceAchieved.isHidden = false
            cell.cellProgress.isHidden = true
            switch achievement.iconName.suffix(1) {
            case "H":
                cell.cellPlaceAchieved.textColor = historicalColor
            default:
                cell.cellPlaceAchieved.textColor = templeColor
            }
        } else {
            cell.cellDetails.text = "\(achievement.details) ~ \(achievement.remaining ?? 0) more"
            cell.cellPlaceAchieved.text = ""
            cell.cellPlaceAchieved.isHidden = true
            cell.cellProgress.isHidden = false
            cell.cellProgress.progress = achievement.progress!
        }
        if let dateAchieved = achievement.achieved {
            cell.cellDateAchieved.text = "on \(formatter.string(from: dateAchieved))"
            cell.cellDateAchieved.isHidden = false
        } else {
            cell.cellDateAchieved.text = ""
            cell.cellDateAchieved.isHidden = true
        }
        if let iconImage = UIImage(named: achievement.iconName) {
            // image exists
            cell.cellImage?.image = iconImage
        } else {
            cell.cellImage?.image = UIImage(named: "ach12MT")
        }
        // dim image
        cell.imageView?.alpha = 0.5
        
        // Add white glow shadow effect to achievement icon
        if let imageView = cell.cellImage {
            imageView.layer.shadowColor = UIColor.white.withAlphaComponent(0.6).cgColor
            imageView.layer.shadowRadius = 4
            imageView.layer.shadowOpacity = 1.0
            imageView.layer.shadowOffset = .zero
            imageView.layer.masksToBounds = false
        }

        cell.configureShareButton(show: achievement.achieved != nil)
        cell.shareButton.tag = row
        cell.shareButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.shareButton.addTarget(self, action: #selector(shareTapped(_:)), for: .touchUpInside)

        return cell
    }

    @objc private func shareTapped(_ sender: UIButton) {
        let row = sender.tag
        guard row >= 0, row < display.count else { return }
        let achievement = display[row]
        handleAchievementShareAction(for: achievement, sourceView: sender)
    }

    private func makeCelebrationBoardHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.title = "View \(CelebrationBoardConfig.displayName)"
        config.image = UIImage(systemName: "globe")
        config.imagePadding = 6
        config.baseForegroundColor = UIColor(named: "BaptismsBlue") ?? .systemBlue
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont(name: "Baskerville", size: 17)
            return outgoing
        }
        button.configuration = config
        button.addTarget(self, action: #selector(openCelebrationBoard), for: .touchUpInside)
        header.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
        return header
    }

    @objc private func openCelebrationBoard() {
        let safari = SFSafariViewController(url: CelebrationBoardConfig.pageURL)
        present(safari, animated: true)
    }

    @IBAction func changeDisplay(_ sender: UISegmentedControl) {
        showingCompleted = sender.selectedSegmentIndex != 1
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
