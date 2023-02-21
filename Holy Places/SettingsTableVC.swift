//
//  SettingsTVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 12/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class SettingsTableVC: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //MARK: - Variables and Outlets
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var imageOptionSelected = 0
    
    @IBOutlet weak var minutesDelay: UITextField!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var filterSwitch: UISwitch!
    @IBOutlet weak var visitGoal: UITextField!
    @IBOutlet weak var textColor: UISegmentedControl!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var imageOptions: UISegmentedControl!
    @IBOutlet weak var importBtn: ShadowButton!
    @IBOutlet weak var hoursWorkedSwitch: UISwitch!
    @IBOutlet weak var excludeNonOrdinanceVisitsSwitch: UISwitch!
    @IBOutlet weak var addDays: UITextField!
    
    //MARK: - Standard Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Settings"
        
        enableSwitch.isOn = notificationEnabled
        filterSwitch.isOn = notificationFilter
        filterSwitch.isEnabled = notificationEnabled
        minutesDelay.isEnabled = notificationEnabled
        hoursWorkedSwitch.isOn = ordinanceWorker
        excludeNonOrdinanceVisitsSwitch.isOn = excludeNonOrdinanceVisits
        
        // default values
        if notificationDelayInMinutes == 0 {
            notificationDelayInMinutes = 30
        }
        if annualVisitGoal == 0 {
            annualVisitGoal = 12
        }
        
        if homeDefaultPicture {
            imageOptionSelected = 0
        } else if homeVisitPicture {
            imageOptionSelected = 1
        } else {
            imageOptionSelected = 2
        }
        imageOptions.selectedSegmentIndex = imageOptionSelected
        textColor.selectedSegmentIndex = Int(homeTextColor)
        
        if homeAlternatePicture != nil {
            selectedImage.image = UIImage(data: homeAlternatePicture!)
            importBtn.setTitle("Change Image", for: .normal)
            importBtn.setTitleColor(UIColor.home(), for: .normal)
        }
        
        visitGoal.text = String(annualVisitGoal)
        minutesDelay.text = String(notificationDelayInMinutes)
        addDays.text = String(copyAddDays)
        keyboardDone()
        
    }
    
    //MARK: - Actions
    @IBAction func textColorChange(_ sender: UISegmentedControl) {
        homeTextColor = Int16(sender.selectedSegmentIndex)
        importBtn.setTitleColor(UIColor.home(), for: .normal)
    }
    
    @IBAction func changeImageOption(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            homeDefaultPicture = true
            homeVisitPicture = false
            homeTextColor = 0
            textColor.selectedSegmentIndex = Int(homeTextColor)
            imageOptionSelected = 0
        case 1:
            if homeVisitPictureData == nil {
                let alert = UIAlertController(title: "Not Available", message: "You haven't added any Visit images yet.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
                imageOptions.selectedSegmentIndex = imageOptionSelected
            } else {
                homeVisitPicture = true
                homeDefaultPicture = false
                imageOptionSelected = 1
            }
        default:
            if homeAlternatePicture == nil {
                let alert = UIAlertController(title: "Not Available", message: "You haven't imported an image below.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
                imageOptions.selectedSegmentIndex = imageOptionSelected
            } else {
                homeVisitPicture = false
                homeDefaultPicture = false
                imageOptionSelected = 2
            }
        }
    }
    
    @IBAction func enable(_ sender: UISwitch) {
        notificationEnabled = sender.isOn
        if notificationEnabled {
            ad.locationServiceSetup()
        }
        filterSwitch.isEnabled = notificationEnabled
        minutesDelay.isEnabled = notificationEnabled
    }
    
    @IBAction func excludeSwitched(_ sender: UISwitch) {
        excludeNonOrdinanceVisits = sender.isOn
    }
    
    @IBAction func filterEnabled(_ sender: UISwitch) {
        notificationFilter = sender.isOn
    }
    
    @IBAction func hoursWorkedEnabled(_ sender: UISwitch) {
        ordinanceWorker = sender.isOn
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        // Save settings
        notificationDelayInMinutes = Int16(minutesDelay.text!) ?? 30
        annualVisitGoal = Int(visitGoal.text!) ?? 12
        copyAddDays = Int16(addDays.text!) ?? 7
        
        // Dismiss view
        self.dismiss(animated: true, completion: nil)
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
        self.addDays.inputAccessoryView = toolbar
    }
    
    @IBAction func addPicture(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
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
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)


        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
        print(image?.size as Any)

        guard let imageData = image!.jpegData(compressionQuality: 1) else {
            // handle failed conversion
            print("jpg error")
            return
        }
        homeAlternatePicture = imageData as Data
        selectedImage.image = UIImage(data: homeAlternatePicture!)
        importBtn.setTitleColor(UIColor.home(), for: .normal)
        importBtn.setTitle("Change Image", for: .normal)
        homeVisitPicture = false
        homeDefaultPicture = false
        imageOptionSelected = 2
        imageOptions.selectedSegmentIndex = imageOptionSelected
        self.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
