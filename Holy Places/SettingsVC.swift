//
//  SettingsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 11/2/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let minutes = ["1", "15", "30", "45", "60", "90", "120", "150", "180", "240", "360", "480", "600", "720", "1080", "1440"]
    
    @IBOutlet weak var minutesPicker: UIPickerView!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var filterSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        minutesPicker.dataSource = self
        minutesPicker.delegate = self
        if notificationEnabled {
            enableSwitch.isOn = true
            minutesPicker.isUserInteractionEnabled = true
        } else {
            enableSwitch.isOn = false
        }
        if notificationFilter {
            filterSwitch.isOn = true
        } else {
            filterSwitch.isOn = false
        }
        
        if notificationDelayInMinutes == 0 {
            notificationDelayInMinutes = 30
        }
        minutesPicker.selectRow(minutes.index(of: String(notificationDelayInMinutes))!, inComponent: 0, animated: true)
        if notificationDelayInMinutes > 60 {
            minutesLabel.text = "Reminder after this number of minutes: \(notificationDelayInMinutes) (\(notificationDelayInMinutes/60) hrs)"
        } else {
            minutesLabel.text = "Reminder after this number of minutes: \(notificationDelayInMinutes)"
        }
    }
    
    @IBAction func enable(_ sender: UISwitch) {
        if sender.isOn {
            notificationEnabled = true
            appDelegate.locationServiceSetup()
            minutesPicker.isUserInteractionEnabled = true
        } else {
            notificationEnabled = false
            minutesPicker.isUserInteractionEnabled = false
        }
    }
    @IBAction func filterEnabled(_ sender: UISwitch) {
        if sender.isOn {
            notificationFilter = true
        } else {
            notificationFilter = false
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return minutes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return minutes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        notificationDelayInMinutes = Int16(minutes[row])!
        if Int16(minutes[row])! > 60 {
            minutesLabel.text = "Reminder after this number of minutes: \(minutes[row]) (\(Double(minutes[row])!/60) hrs)"
        } else {
            minutesLabel.text = "Reminder after this number of minutes: \(minutes[row])"
        }
    }
    
    // MARK: - Navigation

    @IBAction func done(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
    }

}
