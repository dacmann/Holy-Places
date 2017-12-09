//
//  SettingsTVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 12/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class SettingsTableVC: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    @IBOutlet weak var minutesDelay: UITextField!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var filterSwitch: UISwitch!
    @IBOutlet weak var visitGoal: UITextField!
    @IBOutlet weak var textColor: UISegmentedControl!
    @IBOutlet weak var defaultImage: UISwitch!
    @IBOutlet weak var randomVisit: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        enableSwitch.isOn = notificationEnabled
        filterSwitch.isOn = notificationFilter
        filterSwitch.isEnabled = notificationEnabled
        
        // default values
        if notificationDelayInMinutes == 0 {
            notificationDelayInMinutes = 30
        }
        if annualVisitGoal == 0 {
            annualVisitGoal = 12
        }
        
        defaultImage.isOn = homeDefaultPicture
        textColor.selectedSegmentIndex = Int(homeTextColor)
        
        visitGoal.text = String(annualVisitGoal)
        minutesDelay.text = String(notificationDelayInMinutes)
        randomVisit.isEnabled = !homeDefaultPicture
        randomVisit.isOn = homeVisitPicture
        keyboardDone()

    }
    
    @IBAction func textColorChange(_ sender: UISegmentedControl) {
        homeTextColor = Int16(sender.selectedSegmentIndex)
    }
    @IBAction func randomVisitChange(_ sender: UISwitch) {
        homeVisitPicture = sender.isOn
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
        notificationFilter = sender.isOn
    }
    
    @IBAction func defaultImageChange(_ sender: UISwitch) {
        homeDefaultPicture = sender.isOn
        if homeDefaultPicture {
            homeTextColor = 0
        }
        textColor.selectedSegmentIndex = Int(homeTextColor)
        randomVisit.isEnabled = !homeDefaultPicture
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
    
    @IBAction func addPicture(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            //                imagePicker.allowsEditing = true
            if UIDevice.current.userInterfaceIdiom == .pad {
                imagePicker.modalPresentationStyle = UIModalPresentationStyle.popover
                self.present(imagePicker, animated: true, completion: nil)
                let popoverPresentationController = imagePicker.popoverPresentationController
                popoverPresentationController?.sourceView = sender
            } else {
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        print(image?.size as Any)

        guard let imageData = UIImageJPEGRepresentation(image!, 1) else {
            // handle failed conversion
            print("jpg error")
            return
        }
        homeAlternatePicture = imageData as Data
        self.dismiss(animated: true, completion: nil)
    }
}
