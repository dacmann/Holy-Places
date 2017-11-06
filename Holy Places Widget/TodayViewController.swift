//
//  TodayViewController.swift
//  Holy Places Widget
//
//  Created by Derek Cordon on 10/31/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var goal: UILabel!
    @IBOutlet weak var lastVisit: UILabel!
    @IBOutlet weak var lastVisitDate: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        var latestTempleVisited = ""
//        var dateLastVisited = ""
//        var currentSize: CGSize = self.preferredContentSize
//        currentSize.height = 40.0
//        self.preferredContentSize = currentSize
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let currentYear = formatter.string(from: Date())
        
        if let goalFromApp = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "goalProgress") {
            goal.text = "\(currentYear) Goal Progress: \(goalFromApp)"
        }
        
        if let latestTempleVisited = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "latestTempleVisited") {
            lastVisit.text = latestTempleVisited as? String
        }
        if let dateLastVisited = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "dateLastVisited") {
            lastVisitDate.text = "Last Temple Visit: \(dateLastVisited)"
        }
    }

    @IBAction func openApp(_ sender: UIButton) {
        if let url = URL(string: "net.dacworld.holyplaces://")
        {
            self.extensionContext?.open(url, completionHandler: {success in print("called url complete handler: \(success)")})
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let currentYear = formatter.string(from: Date())
        if let goalFromApp = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "goalProgress") {
            if goalFromApp as? String != lastVisit.text {
                goal.text = "\(currentYear) Goal Progress: \(goalFromApp)"
                completionHandler(NCUpdateResult.newData)
            } else {
                completionHandler(NCUpdateResult.noData)
            }
        }
        if let latestTempleVisited = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "latestTempleVisited") {
            if latestTempleVisited as? String != lastVisit.text {
                lastVisit.text = latestTempleVisited as? String
                completionHandler(NCUpdateResult.newData)
            } else {
                completionHandler(NCUpdateResult.noData)
            }
        }
        if let dateLastVisited = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "dateLastVisited") {
            if dateLastVisited as? String != lastVisitDate.text {
                lastVisitDate.text = "Last Temple Visit: \(dateLastVisited)"
                completionHandler(NCUpdateResult.newData)
            } else {
                completionHandler(NCUpdateResult.noData)
            }
        }
        completionHandler(NCUpdateResult.newData)
    }
    
}
