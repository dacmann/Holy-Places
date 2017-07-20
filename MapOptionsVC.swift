//
//  MapOptionsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 7/19/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class MapOptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var filterChoices = ["Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction" ]
    
    @IBOutlet weak var filterPicker: UIPickerView!
    @IBOutlet weak var visitedFilter: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let attr = NSDictionary(object: UIFont(name: "Baskerville", size: 14.0)!, forKey: NSFontAttributeName as NSCopying)
        visitedFilter.setTitleTextAttributes(attr as? [AnyHashable : Any], for: .normal)
        visitedFilter.selectedSegmentIndex = mapVisitedFilter
        filterPicker.dataSource = self
        filterPicker.delegate = self
        filterPicker.selectRow(mapFilterRow, inComponent: 0, animated: true)

    }
    
    @IBAction func visitedFilterChanged(_ sender: UISegmentedControl) {
        mapVisitedFilter = sender.selectedSegmentIndex
    }

    //MARK: - PickerView Functions
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel!
        if label == nil {
            label = UILabel()
        }
        let data = filterChoices[row]

        let title = NSAttributedString(string: data, attributes: [NSFontAttributeName: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch data {
        case "Active Temples":
            label?.textColor = UIColor.darkRed()
        case "Historical Sites":
            label?.textColor = UIColor.darkLimeGreen()
        case "Visitors' Centers":
            label?.textColor = UIColor.strongYellow()
        case "Temples Under Construction":
            label?.textColor = UIColor.darkOrange()
        default:
            label?.textColor = UIColor.lead()
        }
        return label!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {

        return filterChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        return filterChoices[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        mapFilterRow = row
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // MARK: - Navigation

     @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
     }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
