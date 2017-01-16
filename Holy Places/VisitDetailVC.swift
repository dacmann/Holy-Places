//
//  VisitDetailVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/13/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class VisitDetailVC: UIViewController {

    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var sealings: UITextField!
    @IBOutlet weak var endowments: UITextField!
    @IBOutlet weak var initiatories: UITextField!
    @IBOutlet weak var confirmations: UITextField!
    @IBOutlet weak var baptisms: UITextField!
    @IBOutlet weak var comments: UITextView!
    @IBOutlet weak var sealingsStepO: UIStepper!
    @IBOutlet weak var endowmentsStepO: UIStepper!
    @IBOutlet weak var initiatoriesStepO: UIStepper!
    @IBOutlet weak var confirmationsStepO: UIStepper!
    @IBOutlet weak var baptismsStepO: UIStepper!
    @IBOutlet weak var visitDate: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()

        // Do any additional setup after loading the view.
    }
    @IBAction func sealingsText(_ sender: UITextField) {
        if (sender.text?.isEmpty)!{
            sender.text = "0"
        }
        self.sealingsStepO.value = Double(sender.text!)!
    }
    @IBAction func endowmentsText(_ sender: UITextField) {
        if (sender.text?.isEmpty)!{
            sender.text = "0"
        }
        self.endowmentsStepO.value = Double(sender.text!)!
    }
    @IBAction func initiatoriesText(_ sender: UITextField) {
        if (sender.text?.isEmpty)!{
            sender.text = "0"
        }
        self.initiatoriesStepO.value = Double(sender.text!)!
    }
    @IBAction func confirmationsText(_ sender: UITextField) {
        if (sender.text?.isEmpty)!{
            sender.text = "0"
        }
        self.confirmationsStepO.value = Double(sender.text!)!
    }
    @IBAction func baptismsText(_ sender: UITextField) {
        if (sender.text?.isEmpty)!{
            sender.text = "0"
        }
        self.baptismsStepO.value = Double(sender.text!)!
    }
    
    @IBAction func sealingsStep(_ sender: UIStepper) {
        self.sealings.text = Int(sender.value).description
    }
    @IBAction func endowmentStep(_ sender: UIStepper) {
        self.endowments.text = Int(sender.value).description
    }
    @IBAction func initiatoriesStep(_ sender: UIStepper) {
        self.initiatories.text = Int(sender.value).description
    }
    @IBAction func confirmationStep(_ sender: UIStepper) {
        self.confirmations.text = Int(sender.value).description
    }
    @IBAction func baptismsStep(_ sender: UIStepper) {
        self.baptisms.text = Int(sender.value).description
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                visitDate.text = formatter.string(from: date)
            }
        }
    }

    var detailItem: Temple? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        self.view.endEditing(true)
//    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
