//
//  VisitDetailVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/13/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

class VisitDetailVC: UIViewController, SendDateDelegate {
    
    func DateChanged(data: Date) {
        dateOfVisit = data
        setDate()
    }
    
    var dateOfVisit: Date?
    var placeType = String()
    
    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var sealings: UITextField!
    @IBOutlet weak var endowments: UITextField!
    @IBOutlet weak var initiatories: UITextField!
    @IBOutlet weak var confirmations: UITextField!
    @IBOutlet weak var baptisms: UITextField!
    @IBOutlet weak var sealingsStepO: UIStepper!
    @IBOutlet weak var endowmentsStepO: UIStepper!
    @IBOutlet weak var initiatoriesStepO: UIStepper!
    @IBOutlet weak var confirmationsStepO: UIStepper!
    @IBOutlet weak var baptismsStepO: UIStepper!
    @IBOutlet weak var comments: UITextView!
    @IBOutlet weak var visitDate: UIButton!
    @IBOutlet weak var templeView: UIStackView!
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    @IBAction func setDate() {
        //dateOfVisit = sender.date
        if let button = self.visitDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM dd YYYY"
            let visitDateAtt = NSAttributedString(string: formatter.string(from: dateOfVisit!))
            button.setAttributedTitle(visitDateAtt, for: .normal)
        }
    }
    
    func saveVisit (_ sender: Any) {
        let context = getContext()
        
        //retrieve the entity
        let entity =  NSEntityDescription.entity(forEntityName: "Visit", in: context)
        
        //set the entity values
        let visit = NSManagedObject(entity: entity!, insertInto: context)
        visit.setValue(templeName.text, forKey: "holyPlace")
        visit.setValue(Double(baptisms.text!), forKey: "baptisms")
        visit.setValue(Double(confirmations.text!), forKey: "confirmations")
        visit.setValue(Double(initiatories.text!), forKey: "initiatories")
        visit.setValue(Double(endowments.text!), forKey: "endowments")
        visit.setValue(Double(sealings.text!), forKey: "sealings")
        visit.setValue(comments.text, forKey: "comments")
        visit.setValue(dateOfVisit, forKey: "dateVisited")
        visit.setValue(placeType, forKey: "type")
        
        //save the object
        do {
            try context.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {}
        print("Saving Visit completed")
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        populateView()
        setDate()

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
                dateOfVisit = Date()
                placeType = detail.templeType
                if detail.templeType != "T" {
                    templeView.isHidden = true
                }
            }
        }
    }
    
    func populateView() {
        // Update the user interface for the detail item.
        if let detail = self.detailVisit {
            if let label = self.templeName {
                label.text = detail.holyPlace
                dateOfVisit = detail.dateVisited as? Date
                sealings.text = detail.sealings.description
                endowments.text = detail.endowments.description
                initiatories.text = detail.initiatories.description
                confirmations.text = detail.confirmations.description
                baptisms.text = detail.baptisms.description
                comments.text = detail.comments
                visitDate.isEnabled = false
                comments.isEditable = false
                if detail.type == "T" {
                    sealingsStepO.isHidden = true
                    endowmentsStepO.isHidden = true
                    initiatoriesStepO.isHidden = true
                    confirmationsStepO.isHidden = true
                    baptismsStepO.isHidden = true
                    sealings.isEnabled = false
                    endowments.isEnabled = false
                    initiatories.isEnabled = false
                    confirmations.isEnabled = false
                    baptisms.isEnabled = false
                } else {
                    templeView.isHidden = true
                }
            }
        }
    }
    
    var detailVisit: Visit? {
        didSet {
            // populate the view
            self.populateView()
        }
    }

    var detailItem: Temple? {
        didSet {
            // Update the view.
            self.configureView()
            let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveVisit(_:)))
            self.navigationItem.rightBarButtonItem = saveButton
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
        // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeDate" {
            let controller: DateChangeVC = segue.destination as! DateChangeVC
            controller.delegate = self
            controller.dateOfVisit = dateOfVisit
        }
    }
    

}
