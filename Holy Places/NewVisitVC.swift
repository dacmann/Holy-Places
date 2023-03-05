//
//  NewVisitVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 11/2/19.
//  Copyright © 2019 Derek Cordon. All rights reserved.
//

import UIKit

class NewVisitVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource  {

    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeSelection: UIPickerView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    var pickerData = activeTemples
    var placeNameSelected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.placeSelection.delegate = self
        self.placeSelection.dataSource = self
        
        let randomPlace = Int(arc4random_uniform(UInt32(pickerData.count)))
        placeSelection.selectRow(randomPlace, inComponent: 0, animated: true)
        placeNameSelected = randomPlace
        
        let attr = NSDictionary(object: UIFont(name: "Baskerville", size: 14.0)!, forKey: NSAttributedString.Key.font as NSCopying)
        segmentedController.setTitleTextAttributes(attr as? [AnyHashable : Any] as? [NSAttributedString.Key : Any], for: .normal)
        
        keyboardDone()

    }

    @IBAction func placeEntered(_ sender: UITextField) {
        if placeName.text != "" {
            nextButton.isEnabled = true
        } else {
            nextButton.isEnabled = false
        }
    }
    
    @IBAction func typeSelection(_ sender: UISegmentedControl) {
        placeName.isHidden = true
        placeSelection.isHidden = false
        doneButtonAction()
        nextButton.isEnabled = true
        switch segmentedController.selectedSegmentIndex {
        case 0:
            pickerData = activeTemples
        case 1:
            pickerData = historical
        case 2:
            pickerData = visitors
        case 3:
            placeName.isHidden = false
            placeSelection.isHidden = true
            placeName.becomeFirstResponder()
            nextButton.isEnabled = false
        default:
            break
        }
        placeSelection.reloadAllComponents()
        let randomPlace = Int(arc4random_uniform(UInt32(pickerData.count)))
        placeSelection.selectRow(randomPlace, inComponent: 0, animated: true)
        placeNameSelected = randomPlace
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel?
        if label == nil {
            label = UILabel()
        }
        let data = pickerData[row].templeName
        let title = NSAttributedString(string: data, attributes: [NSAttributedString.Key.font: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch segmentedController.selectedSegmentIndex {
        case 0:
            label?.textColor = templeColor
        case 1:
            label?.textColor = historicalColor
        case 2:
            label?.textColor = visitorCenterColor
        default:
            label?.textColor = defaultColor
        }
        return label!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        return pickerData[row].templeName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        placeNameSelected = row
        nextButton.isEnabled = true
    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(NewVisitVC.doneButtonAction))
        //array of BarButtonItems
        var arr = [UIBarButtonItem]()
        arr.append(flexSpace)
        arr.append(doneBtn)
        toolbar.setItems(arr, animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.placeName.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = (segue.destination as! RecordVisitVC)
        if segue.identifier == "enterVisit" {
            // Change the back button on the Record Visit VC to Cancel
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
            if segmentedController.selectedSegmentIndex == 3 {
                let temple = Temple(Name: placeName.text!, Address: "", Snippet: "", CityState: "", Country: "", Phone: "", Latitude: 0.0, Longitude: 0.0, Order: 0, PictureURL: "", SiteURL: "", Type: "O", ReaderView: false, InfoURL: "", SqFt: 0, FHCode: "")
                controller.detailItem = temple
            } else {
                let temple = pickerData[placeNameSelected]
                controller.detailItem = temple
            }
            
        }
    }
}
