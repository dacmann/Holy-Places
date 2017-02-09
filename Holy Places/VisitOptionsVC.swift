//
//  VisitOptionsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 2/8/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

protocol SendVisitOptionsDelegate {
    func FilterOptions(row: Int)
    func SortOptions(row: Int)
}

class VisitOptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegateOptions: SendVisitOptionsDelegate? = nil
    
    var filterSelected: Int?
    var sortSelected: Int?
    //var nearestEnabled: Bool?
    var filterChoices = ["Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers" ]
    var sortOptions = ["Latest Visit", "Group by Place"]
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerFilter: UIPickerView!
    @IBOutlet weak var pickerSort: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        pickerFilter.dataSource = self
        pickerFilter.delegate = self
        pickerFilter.selectRow(filterSelected!, inComponent: 0, animated: true)
        pickerSort.dataSource = self
        pickerSort.delegate = self
        pickerSort.selectRow(sortSelected!, inComponent: 0, animated: true)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel!
        if label == nil {
            label = UILabel()
        }
        var data = filterChoices[row]
        if pickerView.tag == 1 {
            data = sortOptions[row]
        }
        let title = NSAttributedString(string: data, attributes: [NSFontAttributeName: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch data {
        case "Active Temples":
            label?.textColor = UIColor.ocean()
        case "Historical Sites":
            label?.textColor = UIColor.moss()
        case "Visitors' Centers":
            label?.textColor = UIColor.asparagus()
        default:
            label?.textColor = UIColor.lead()
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
        } else {
            filterSelected = row
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        if delegateOptions != nil {
            delegateOptions?.FilterOptions(row: filterSelected!)
            delegateOptions?.SortOptions(row: sortSelected!)
        }
        self.dismiss(animated: true, completion: nil)
    }
    

}
