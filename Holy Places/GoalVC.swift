//
//  GoalVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 4/26/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import SafariServices

class GoalVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var goalPicker: UIPickerView!
    @IBOutlet weak var quote: UILabel!
    
    let goalNumbers = ["1", "2", "3", "4", "6", "9", "12", "15", "18", "21", "24", "27", "30", "33", "36", "39", "42", "48", "52", "64", "72", "84", "96", "104", "156", "208", "260"]
    
    @IBAction func showTalk(_ sender: UIButton) {
        if let url = URL(string: "https://www.lds.org/general-conference/2009/04/temple-worship-the-source-of-strength-and-power-in-times-of-need") {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            present(vc, animated: true)
        }
    }
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
        quote.text = """
        I encourage you to establish your own goal of how frequently you will avail yourself of the ordinances offered in our operating temples. What is there that is more important than attending and participating in the ordinances of the temple?
           - Elder Richard G. Scott
        """
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
