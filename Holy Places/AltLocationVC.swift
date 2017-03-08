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

    @IBOutlet weak var street: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var postalCode: UITextField!
    @IBOutlet weak var addressResult: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func locationChoice(_ sender: UISegmentedControl) {
    }
    @IBAction func validate(_ sender: UIButton) {
        var address = String()
        address = "\(street.text!) \(city.text!) \(state.text!) \(postalCode.text!)"
        forwardGeocoding(address: address)
    }
    
    func forwardGeocoding(address: String) {
        CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if error != nil {
                self.addressResult.text = error?.localizedDescription
                return
            }
            if (placemarks?.count)! > 0 {
                let placemark = placemarks?[0]
                let location = placemark?.location
                let coordinate = location?.coordinate
                self.addressResult.text = "lat: \(coordinate!.latitude)\nlong: \(coordinate!.longitude)"
                print("\nlat: \(coordinate!.latitude), long: \(coordinate!.longitude)")

            }
        })
    }
    
    // MARK: - Navigation
    @IBAction func goBack(_ sender: UIButton) {
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
