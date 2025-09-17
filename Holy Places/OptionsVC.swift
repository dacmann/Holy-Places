//
//  OptionsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/20/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

protocol SendOptionsDelegate {
    func FilterOptions(row: Int)
    func SortOptions(row: Int)
}

class OptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    //MARK: - Variables
    var delegateOptions: SendOptionsDelegate? = nil
    var filterSelected: Int?
    var sortSelected: Int?
    var filterChoices = ["All Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction", "Announced Temples", "All Temples"]
    var sortOptions = ["Alphabetical", "Nearest", "Country"]
    var sortOptionsTemple = ["Alphabetical", "Nearest", "Country", "Dedication Date", "Size", "Announced Date"]
    var sortOptionsAllTemples = ["Alphabetical", "Nearest", "Country", "Announced Date"]
    var sortOptionsAll = ["Alphabetical", "Nearest", "Country"]
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: - Outlets & Actions
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerFilter: UIPickerView!
    @IBOutlet weak var pickerSort: UIPickerView!
    
    //MARK: - Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view
        
        // Determine which Sort array to use
        if filterSelected == 1 {
            sortOptions = sortOptionsTemple
        } else if [4, 5, 6].contains(filterSelected) {
            sortOptions = sortOptionsAllTemples
        } else {
            sortOptions = sortOptionsAll
        }
        
        // Set up Picker views
        pickerFilter.dataSource = self
        pickerFilter.delegate = self
        pickerFilter.selectRow(filterSelected!, inComponent: 0, animated: true)
        pickerSort.dataSource = self
        pickerSort.delegate = self
        pickerSort.selectRow(sortSelected!, inComponent: 0, animated: true)
    }
    
    //MARK: - PickerView Functions
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel?
        if label == nil {
            label = UILabel()
        }
        var data = filterChoices[row]
        if pickerView.tag == 1 {
            data = sortOptions[row]
        }
        let title = NSAttributedString(string: data, attributes: [NSAttributedString.Key.font: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch data {
        case "Active Temples":
            label?.textColor = templeColor
        case "Historical Sites":
            label?.textColor = historicalColor
        case "Temples Under Construction":
            label?.textColor = constructionColor
        case "Announced Temples":
            label?.textColor = announcedColor
        case "Visitors' Centers":
            label?.textColor = visitorCenterColor
        default:
            label?.textColor = defaultColor
        }
        return label!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return sortOptions.count
        } else {
            return filterChoices.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return sortOptions[row]
        } else {
            return filterChoices[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            sortSelected = row
            if row == 1 {
                ad.locationServiceSetup()
            }
        } else {
            filterSelected = row
            if row == 1 {
                sortOptions = sortOptionsTemple
            } else if [4, 5, 6].contains(row) {
                sortOptions = sortOptionsAllTemples
            } else {
                sortOptions = sortOptionsAll
            }

            pickerSort.reloadAllComponents()
            if sortSelected! >= sortOptions.count {
                sortSelected = 0
                pickerSort.selectRow(sortSelected!, inComponent: 0, animated: true)
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // MARK: - Navigation
    @IBAction func goBack(_ sender: UIButton) {
        if delegateOptions != nil {
            delegateOptions?.FilterOptions(row: filterSelected!)
            delegateOptions?.SortOptions(row: sortSelected!)
        }
        self.dismiss(animated: true, completion: nil)
    }


}
