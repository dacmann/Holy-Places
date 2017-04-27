//
//  GoalVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 4/26/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class GoalVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var goalPicker: UIPickerView!
    
    let goalNumbers = ["1", "2", "3", "4", "6", "12", "18", "24", "36", "48", "52", "104", "156", "208", "260"]
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return goalNumbers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return goalNumbers[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        annualVisitGoal = Int(goalNumbers[row])!
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        goalPicker.dataSource = self
        goalPicker.delegate = self
        if annualVisitGoal == 0 {
            annualVisitGoal = 12
        }
        goalPicker.selectRow(goalNumbers.index(of: String(annualVisitGoal))!, inComponent: 0, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation
    @IBAction func done(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)

    }


}
