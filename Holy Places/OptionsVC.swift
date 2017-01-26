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
    
    var delegateOptions: SendOptionsDelegate? = nil
    
    var filterSelected: Int?
    var sortSelected: Int?
    //var nearestEnabled: Bool?
    var filterChoices = ["LDS Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction" ]
    var sortOptions = ["Alphabetical", "Nearest", "Country"]

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
