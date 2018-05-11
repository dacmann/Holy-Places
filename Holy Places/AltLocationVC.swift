//
//  AltLocationVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 3/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreLocation
import AddressBookUI

class AltLocationVC: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var street: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var postalCode: UITextField!
    @IBOutlet weak var addressResult: UITextView!
    @IBOutlet weak var locationControl: UISegmentedControl!
    
    //MARK: - Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if locationSpecific {
            locationControl.selectedSegmentIndex = 1
        } else {
            locationControl.selectedSegmentIndex = 0
        }
        self.street.text = altLocStreet
        self.city.text = altLocCity
        self.state.text = altLocState
        self.postalCode.text = altLocPostalCode
        if coordAltLocation != nil {
            let coordinate = coordAltLocation.coordinate
            self.addressResult.text = "latitude: \(coordinate.latitude)\nlongitude: \(coordinate.longitude)"
        } else {
            locationControl.isEnabled = false
        }
        keyboardDone()
    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(AltLocationVC.doneButtonAction))
        //array of BarButtonItems
        var arr = [UIBarButtonItem]()
        arr.append(flexSpace)
        arr.append(doneBtn)
        toolbar.setItems(arr, animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.street.inputAccessoryView = toolbar
        self.city.inputAccessoryView = toolbar
        self.state.inputAccessoryView = toolbar
        self.postalCode.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        let nextTage=textField.tag+1
        // Try to find next responder
        let nextResponder=textField.superview?.viewWithTag(nextTage) as UIResponder?
        
        if nextResponder != nil {
            // Found next responder, so set it.
            nextResponder?.becomeFirstResponder()
        }
        else
        {
            // Not found, so remove keyboard
            textField.resignFirstResponder()
        }
        return false // We do not want UITextField to insert line-breaks.
    }
    
    //MARK: - Actions
    @IBAction func locationChoice(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            locationSpecific = true
        } else {
            locationSpecific = false
        }
    }
    @IBAction func validate(_ sender: UIButton) {
        self.view.endEditing(true)
        var address = String()
        address = "\(street.text!) \(city.text!) \(state.text!) \(postalCode.text!)"
        if address.trimmingCharacters(in: .whitespaces).isEmpty {
            self.addressResult.text = "Enter city, state or postal code"
        } else {
            CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
                if error != nil {
                    self.addressResult.text = error?.localizedDescription
                    return
                }
                if (placemarks?.count)! > 0 {
                    let placemark = placemarks?[0]
                    let location = placemark?.location
                    let coordinate = location?.coordinate
                    self.addressResult.text = "Coordinates found!  Press Done to see what is nearest.\n\nlatitude: \(coordinate!.latitude)\nlongitude: \(coordinate!.longitude)"
                    print("\nlat: \(coordinate!.latitude), long: \(coordinate!.longitude)")
                    coordAltLocation = location
                    altLocStreet = self.street.text!
                    altLocCity = self.city.text!
                    altLocState = self.state.text!
                    altLocPostalCode = self.postalCode.text!
                    self.locationControl.isEnabled = true
                    self.locationControl.selectedSegmentIndex = 1
                    locationSpecific = true
                }
            })
        }
    }
    
    // MARK: - Navigation
    @IBAction func goBack(_ sender: UIButton) {
        optionsChanged = true
        self.dismiss(animated: true, completion: nil)
    }

    /*
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
