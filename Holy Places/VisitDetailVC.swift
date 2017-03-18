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
    
    func editVisit (_ sender: Any) {
        
        sealingsStepO.isHidden = false
        sealingsStepO.value = Double(sealings.text!)!
        endowmentsStepO.isHidden = false
        endowmentsStepO.value = Double(endowments.text!)!
        initiatoriesStepO.isHidden = false
        initiatoriesStepO.value = Double(initiatories.text!)!
        confirmationsStepO.isHidden = false
        confirmationsStepO.value = Double(confirmations.text!)!
        baptismsStepO.isHidden = false
        baptismsStepO.value = Double(baptisms.text!)!
        comments.isEditable = true
        visitDate.isEnabled = true
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveEdit(_:)))
        self.navigationItem.rightBarButtonItem = saveButton
        keyboardDone()
    }
    
    func saveEdit (_ sender: Any) {
        let context = getContext()
        
        // save the updated values to the Visit object and disable the editable fields
        if detailVisit?.type == "T" {
            sealingsStepO.isHidden = true
            endowmentsStepO.isHidden = true
            initiatoriesStepO.isHidden = true
            confirmationsStepO.isHidden = true
            baptismsStepO.isHidden = true
            detailVisit?.sealings = Int16(sealings.text!)!
            detailVisit?.endowments = Int16(endowments.text!)!
            detailVisit?.initiatories = Int16(initiatories.text!)!
            detailVisit?.confirmations = Int16(confirmations.text!)!
            detailVisit?.baptisms = Int16(baptisms.text!)!
        }
        detailVisit?.dateVisited = dateOfVisit as NSDate?
        detailVisit?.comments = comments.text!
        comments.isEditable = false
        visitDate.isEnabled = false
        
        //save the object
        do {
            try context.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {}
        print("Saving edited Visit completed")
        
        // change it back to edit button
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editVisit(_:)))
        self.navigationItem.rightBarButtonItem = editButton
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
//        self.comments.layer.borderWidth = 0.5

    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(VisitDetailVC.doneButtonAction))
        //array of BarButtonItems
        var arr = [UIBarButtonItem]()
        arr.append(flexSpace)
        arr.append(doneBtn)
        toolbar.setItems(arr, animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.comments.inputAccessoryView = toolbar
    }
    
    func doneButtonAction(){
        self.view.endEditing(true)
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
                keyboardDone()
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
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editVisit(_:)))
            self.navigationItem.rightBarButtonItem = editButton
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
