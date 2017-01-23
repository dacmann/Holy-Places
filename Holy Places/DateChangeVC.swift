//
//  DateChangeVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/19/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

protocol SendDateDelegate {
    func DateChanged(data: Date)
}

class DateChangeVC: UIViewController {
    
    var delegate: SendDateDelegate? = nil
    
    var dateOfVisit: Date?

    @IBOutlet weak var dayOfWeek: UILabel!
    @IBOutlet weak var dateChange: UIDatePicker!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dateChange.date = dateOfVisit!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        dayOfWeek.text = formatter.string(from: dateOfVisit!)
    }

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        dayOfWeek.text = formatter.string(from: sender.date)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func dismiss(_ sender: UIButton) {
        if delegate != nil {
            let data = dateChange.date
            delegate?.DateChanged(data: data)
        }
        self.dismiss(animated: true, completion: nil)
    }
    

    // MARK: - Navigation

    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let controller = (segue.destination as! VisitDetailVC)
//        controller.dateOfVisit = dateChange.date
//    }
}
