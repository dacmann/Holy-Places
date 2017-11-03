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
    let minutes = ["1", "15", "30", "45", "60", "90", "120", "150", "180", "240", "300"]
    
    @IBOutlet weak var minutesPicker: UIPickerView!
    @IBOutlet weak var enableSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        minutesPicker.dataSource = self
        minutesPicker.delegate = self
        if notificationEnabled {
            enableSwitch.isOn = true
            appDelegate.locationManager.requestAlwaysAuthorization()
            appDelegate.notificationManager.requestAuthorization(options: [.alert, .sound], completionHandler: { (permissionGranted, error) in
                print(error as Any)
            })
            minutesPicker.isUserInteractionEnabled = true
        } else {
            enableSwitch.isOn = false
        }
        minutesPicker.selectRow(minutes.index(of: String(notificationDelayInMinutes))!, inComponent: 0, animated: true)
    }
    
    @IBAction func enable(_ sender: UISwitch) {
        if sender.isOn {
            notificationEnabled = true
            appDelegate.locationManager.requestAlwaysAuthorization()
            appDelegate.notificationManager.requestAuthorization(options: [.alert, .sound], completionHandler: { (permissionGranted, error) in
                print(error as Any)
                })
            minutesPicker.isUserInteractionEnabled = true
        } else {
            notificationEnabled = false
            minutesPicker.isUserInteractionEnabled = false
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
    }
    
    // MARK: - Navigation

    @IBAction func done(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
    }

}
