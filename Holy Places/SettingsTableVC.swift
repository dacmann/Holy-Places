//
//  SettingsTVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 12/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class SettingsTableVC: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    @IBOutlet weak var minutesDelay: UITextField!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var filterSwitch: UISwitch!
    @IBOutlet weak var visitGoal: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        if notificationEnabled {
            enableSwitch.isOn = true
        } else {
            enableSwitch.isOn = false
        }
        if notificationFilter {
            filterSwitch.isOn = true
        } else {
            filterSwitch.isOn = false
        }
        // default values
        if notificationDelayInMinutes == 0 {
            notificationDelayInMinutes = 30
        }
        if annualVisitGoal == 0 {
            annualVisitGoal = 12
        }
        
        visitGoal.text = String(annualVisitGoal)
        minutesDelay.text = String(notificationDelayInMinutes)
        keyboardDone()

    }
    
    @IBAction func enable(_ sender: UISwitch) {
        if sender.isOn {
            notificationEnabled = true
            appDelegate.locationServiceSetup()
            minutesDelay.isEnabled = true
        } else {
            notificationEnabled = false
            minutesDelay.isEnabled = false
        }
    }
    @IBAction func filterEnabled(_ sender: UISwitch) {
        if sender.isOn {
            notificationFilter = true
        } else {
            notificationFilter = false
        }
    }
    
    @IBAction func done(_ sender: UIButton) {
        // Save settings
        notificationDelayInMinutes = Int16(minutesDelay.text!)!
        annualVisitGoal = Int(visitGoal.text!)!
        
        // Dismiss view
        self.dismiss(animated: true, completion: nil)
    }

    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        //array of BarButtonItems
        var arr = [UIBarButtonItem]()
        arr.append(flexSpace)
        arr.append(doneBtn)
        toolbar.setItems(arr, animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.minutesDelay.inputAccessoryView = toolbar
        self.visitGoal.inputAccessoryView = toolbar
    }
}
