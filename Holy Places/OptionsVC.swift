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
    func NearestEnabled(nearest: Bool)
}

class OptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegateOptions: SendOptionsDelegate? = nil
    
    var filterSelected: Int?
    var nearestEnabled: Bool?
    var filterChoices = ["LDS Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction" ]

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerFilter: UIPickerView!
    @IBOutlet weak var switchNearest: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pickerFilter.dataSource = self
        pickerFilter.delegate = self
        pickerFilter.selectRow(filterSelected!, inComponent: 0, animated: true)
        switchNearest.isOn = nearestEnabled!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filterChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filterChoices[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        filterSelected = row
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nearestSwitch(_ sender: UISwitch) {
        nearestEnabled = sender.isOn
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        if delegateOptions != nil {
            delegateOptions?.FilterOptions(row: filterSelected!)
            delegateOptions?.NearestEnabled(nearest: nearestEnabled!)
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
