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
        
    @IBOutlet weak var goalTitle: UILabel!
    @IBOutlet weak var goalProgress: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        var currentSize: CGSize = self.preferredContentSize
//        currentSize.height = 40.0
//        self.preferredContentSize = currentSize
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let currentYear = formatter.string(from: Date())
        
        goalTitle.text = "\(currentYear) Goal Progress"
        if let goalFromApp = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "goalProgress") {
            goalProgress.text = goalFromApp as? String
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
        
        if let goalFromApp = UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.value(forKey: "goalProgress") {
            if goalFromApp as? String != goalProgress.text {
                goalProgress.text = goalFromApp as? String
                completionHandler(NCUpdateResult.newData)
            } else {
                completionHandler(NCUpdateResult.noData)
            }
        }
        completionHandler(NCUpdateResult.newData)
    }
    
}
