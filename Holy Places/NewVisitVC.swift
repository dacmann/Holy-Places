//
//  NewVisitVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 11/2/19.
//  Copyright © 2019 Derek Cordon. All rights reserved.
//

import UIKit

class NewVisitVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UISearchBarDelegate, UITextFieldDelegate  {

    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeSelection: UIPickerView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var closestPlaceSwitch: UISwitch!
    @IBOutlet weak var closestPlaceLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var pickerData = allTemples
    var placeNameSelected = 0
    var closest = UserDefaults.standard.bool(forKey: "addVisitClosestPlace")
    
    var filteredData: [Temple] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.placeSelection.delegate = self
        self.placeSelection.dataSource = self
        
        // Initialize picker data
        filteredData = pickerData
        
        if closest {
            ad.DetermineClosest()
            filteredData.sort {
                guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
                return Int(distance1) < Int(distance2)
            }
            placeSelection.selectRow(0, inComponent: 0, animated: true)
            placeNameSelected = 0
        } else if !filteredData.isEmpty {
            let randomPlace = Int(arc4random_uniform(UInt32(filteredData.count)))
            placeSelection.selectRow(randomPlace, inComponent: 0, animated: true)
            placeNameSelected = randomPlace
        } else {
            placeNameSelected = 0 // Fallback if pickerData is empty
        }
        
        let attr = NSDictionary(object: UIFont(name: "Baskerville", size: 14.0)!, forKey: NSAttributedString.Key.font as NSCopying)
        segmentedController.setTitleTextAttributes(attr as? [AnyHashable : Any] as? [NSAttributedString.Key : Any], for: .normal)
        
        //keyboardDone()
        
        closestPlaceSwitch.isOn = closest
        if UserDefaults.standard.bool(forKey: "locationNotAllowed") {
            closestPlaceSwitch.isHidden = true
            closestPlaceLabel.isHidden = true
        }
        
        searchBar.delegate = self
        placeName.delegate = self  // Set the delegate
        placeName.returnKeyType = .done // Change Return key to "Done"
        
        // Force UI update to reflect selection
        DispatchQueue.main.async {
            self.placeSelection.reloadAllComponents()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show tab bar when leaving
        tabBarController?.tabBar.isHidden = false
    }

    @IBAction func placeEntered(_ sender: UITextField) {
        if placeName.text != "" {
            nextButton.isEnabled = true
        } else {
            nextButton.isEnabled = false
        }
    }
    
    @IBAction func closestPlace(_ sender: UISwitch) {
        closest = sender.isOn
        if closest {
            if UserDefaults.standard.bool(forKey: "locationAllowed") {
                UserDefaults.standard.set(true, forKey: "addVisitClosestPlace")
                filteredData.sort {
                    guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
                    return Int(distance1) < Int(distance2)
                }
                placeSelection.selectRow(0, inComponent: 0, animated: true)
                placeNameSelected = 0
            } else {
                ad.locationServiceSetup()
                closestPlaceSwitch.isOn = false
            }
        } else {
            UserDefaults.standard.set(false, forKey: "addVisitClosestPlace")
            filteredData.sort {
                return $0.templeName < $1.templeName
            }
            let randomPlace = Int(arc4random_uniform(UInt32(filteredData.count)))
            placeSelection.selectRow(randomPlace, inComponent: 0, animated: true)
            placeNameSelected = randomPlace
        }
        
        // Update filteredData and reload picker
        placeSelection.reloadAllComponents()
    }
    
    @IBAction func typeSelection(_ sender: UISegmentedControl) {
        placeName.isHidden = true
        placeSelection.isHidden = false
        nextButton.isEnabled = true
        searchBar.isHidden = false
        switch segmentedController.selectedSegmentIndex {
        case 0:
            pickerData = allTemples
        case 1:
            pickerData = historical
        case 2:
            pickerData = visitors
        case 3:
            placeName.isHidden = false
            placeSelection.isHidden = true
            placeName.becomeFirstResponder()
            nextButton.isEnabled = false
            searchBar.isHidden = true
        default:
            break
        }
        // Reset search bar and filtered data
        searchBar.text = ""
        filteredData = pickerData
        
        placeSelection.reloadAllComponents()
        
        if closest {
            filteredData.sort {
                guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
                return Int(distance1) < Int(distance2)
            }
            placeSelection.selectRow(0, inComponent: 0, animated: true)
            placeNameSelected = 0
        } else {
            let randomPlace = Int(arc4random_uniform(UInt32(filteredData.count)))
            placeSelection.selectRow(randomPlace, inComponent: 0, animated: true)
            placeNameSelected = randomPlace
        }
        
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        guard row < filteredData.count else { return UILabel() }  // Prevent out-of-range crash
        var label = view as! UILabel?
        if label == nil {
            label = UILabel()
        }
        let data = filteredData[row].templeName  // Use filteredData instead of pickerData
        let title = NSAttributedString(string: data, attributes: [NSAttributedString.Key.font: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch segmentedController.selectedSegmentIndex {
        case 0:
            // apply appropriate color based on temple status
            switch filteredData[row].templeType { // Use filteredData
            case "T":
                label?.textColor = templeColor
            case "A": 
                label?.textColor = announcedColor
            default: 
                label?.textColor = constructionColor
            }
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
        return filteredData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filteredData[row].templeName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard !filteredData.isEmpty, row < filteredData.count else {
            nextButton.isEnabled = false
            return
        }
        
        placeNameSelected = filteredData.firstIndex(where: { $0.templeName == filteredData[row].templeName }) ?? 0
        nextButton.isEnabled = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredData = pickerData
        } else {
            filteredData = pickerData.filter { $0.templeName.lowercased().contains(searchText.lowercased()) }
        }
        if closest {
            filteredData.sort {
                guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
                return Int(distance1) < Int(distance2)
            }
            placeSelection.selectRow(0, inComponent: 0, animated: true)
            placeNameSelected = 0
        }
        DispatchQueue.main.async {
            self.placeSelection.reloadAllComponents()
        }
        
        // Automatically select the first item in the filtered list
        if !filteredData.isEmpty {
            placeSelection.selectRow(0, inComponent: 0, animated: true)
            placeNameSelected = filteredData.firstIndex(where: { $0.templeName == filteredData[0].templeName }) ?? 0
        }

    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        // Reset to full data
        filteredData = pickerData
        
        if closest {
            filteredData.sort {
                guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
                return Int(distance1) < Int(distance2)
            }
            placeSelection.selectRow(0, inComponent: 0, animated: true)
            placeNameSelected = 0
        } else {
            let randomPlace = Int(arc4random_uniform(UInt32(filteredData.count)))
            placeSelection.selectRow(randomPlace, inComponent: 0, animated: true)
            placeNameSelected = randomPlace
        }
        
        // Reload picker and set selection
        placeSelection.reloadAllComponents()
        placeSelection.selectRow(placeNameSelected, inComponent: 0, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Dismiss the keyboard
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = (segue.destination as! RecordVisitVC)
        if segue.identifier == "enterVisit" {
            // Change the back button on the Record Visit VC to Cancel
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
            if segmentedController.selectedSegmentIndex == 3 {
                let temple = Temple(Name: placeName.text!, Address: "", Snippet: "", CityState: "", Country: "", Phone: "", Latitude: 0.0, Longitude: 0.0, Order: 0, AnnouncedDate: nil, PictureURL: "", SiteURL: "", Type: "O", ReaderView: false, InfoURL: "", SqFt: 0, FHCode: "")
                controller.detailItem = temple
            } else {
                let temple = filteredData[placeNameSelected]
                controller.detailItem = temple
            }
            
        }
    }
}

