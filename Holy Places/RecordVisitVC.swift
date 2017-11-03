//
//  RecordVisitVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 3/31/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

class RecordVisitVC: UIViewController, SendDateDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    func DateChanged(data: Date) {
        dateOfVisit = data
        setDate()
    }

    //MARK:- Variables & Outlets
    var dateOfVisit: Date?
    var placeType = String()
    var activeField: UITextField?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var scrollView: UIScrollView!
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
    @IBOutlet weak var addPictureBtn: UIButton!
    @IBOutlet weak var pictureView: UIImageView!

    //MARK:- CoreData functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    func setDate() {
        //dateOfVisit = sender.date
        if let button = self.visitDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM dd YYYY"
            let visitDateAtt = NSAttributedString(string: formatter.string(from: dateOfVisit!))
            button.setAttributedTitle(visitDateAtt, for: .normal)
        }
    }
    
    @objc func saveVisit (_ sender: Any) {
        let context = getContext()
        
        //insert a new object in the Visit entity
        let visit = NSEntityDescription.insertNewObject(forEntityName: "Visit", into: context) as! Visit

        //set the entity values
        visit.holyPlace = templeName.text
        visit.baptisms = Int16(baptisms.text!)!
        visit.confirmations = Int16(confirmations.text!)!
        visit.initiatories = Int16(initiatories.text!)!
        visit.endowments = Int16(endowments.text!)!
        visit.sealings = Int16(sealings.text!)!
        visit.comments = comments.text
        visit.dateVisited = dateOfVisit as Date?
        visit.type = placeType
        if pictureView.isHidden == false {
            // create NSData from UIImage
            guard let imageData = UIImageJPEGRepresentation(pictureView.image!, 1) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            visit.picture = imageData as Data
        }
        
        //save the object
        do {
            try context.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {}
        print("Saving Visit completed")
        
        // Update visit count for goal progress in Widget
        appDelegate.getVisits()
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func saveEdit (_ sender: Any) {
        let context = getContext()
        
        // save the updated values to the Visit object 
        if detailVisit?.type == "T" {
            templeView.isHidden = true
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
        detailVisit?.dateVisited = dateOfVisit as Date?
        detailVisit?.comments = comments.text!
        if pictureView.isHidden == false {
            // create NSData from UIImage
            guard let imageData = UIImageJPEGRepresentation(pictureView.image!, 1) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            detailVisit?.picture = imageData as Data
        } else {
            detailVisit?.picture = nil
        }
        
        //save the object
        do {
            try context.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {}
        print("Saving edited Visit completed")
        _ = navigationController?.popViewController(animated: true)

    }
    
    //MARK:- Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        populateView()
        setDate()
        
        // Disable the swipe to make sure you get your chance to save
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        self.scrollView.reloadInputViews()
//        self.scrollView.setContentOffset(CGPoint(x:0, y:self.scrollView.contentSize.height - self.scrollView.bounds.size.height), animated: true)

    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(RecordVisitVC.doneButtonAction))
        //array of BarButtonItems
        var arr = [UIBarButtonItem]()
        arr.append(flexSpace)
        arr.append(doneBtn)
        toolbar.setItems(arr, animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.comments.inputAccessoryView = toolbar
        self.sealings.inputAccessoryView = toolbar
        self.endowments.inputAccessoryView = toolbar
        self.initiatories.inputAccessoryView = toolbar
        self.confirmations.inputAccessoryView = toolbar
        self.baptisms.inputAccessoryView = toolbar
    }
    
    //MARK:- Actions
    
    
    @objc func doneButtonAction(){
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
    @IBAction func addPicture(_ sender: UIButton) {
        if addPictureBtn.currentTitle == "Remove Picture" {
            pictureView.image = nil
            pictureView.isHidden = true
            addPictureBtn.setTitle("Add Picture", for: UIControlState.normal)
        } else {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
//                imagePicker.allowsEditing = true
                if UIDevice.current.userInterfaceIdiom == .pad {
                    imagePicker.modalPresentationStyle = UIModalPresentationStyle.popover
                    self.present(imagePicker, animated: true, completion: nil)
                    let popoverPresentationController = imagePicker.popoverPresentationController
                    popoverPresentationController?.sourceView = sender
                } else {
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }
        }
//        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
//            let imagePicker = UIImagePickerController()
//            imagePicker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
//            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
//            imagePicker.allowsEditing = false
//            self.present(imagePicker, animated: true, completion: nil)
//        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        pictureView.isHidden = false
        addPictureBtn.setTitle("Remove Picture", for: UIControlState.normal)
//        pictureView.image = info[UIImagePickerControllerEditedImage] as? UIImage
//        pictureView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        print(image?.size as Any)
        let size = CGSize(width: (image?.size.width)! / 3, height: (image?.size.height)! / 3)
        pictureView.image = image?.scale(toSize: size)
        print(pictureView.image?.size as Any)
        pictureView.sizeThatFits(size)
//        scrollView.sizeToFit()

        self.dismiss(animated: true, completion: nil)
    }


    //MARK:- Initial Set-up functions
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                if detail == holyPlaceVisited {
                    // Since this place is the same as recently visited place, set the date to saved date
                    dateOfVisit = dateHolyPlaceVisited
                    // Reset recently visited variables
                    dateHolyPlaceVisited = nil
                    holyPlaceVisited = nil
                    holyPlaceWasVisited = false
                } else {
                    dateOfVisit = Date()
                }
                placeType = detail.templeType
                if detail.templeType != "T" {
                    templeView.isHidden = true
                }
                keyboardDone()
                switch detail.templeType {
                case "T":
                    templeName.textColor = UIColor.darkRed()
                case "H":
                    templeName.textColor = UIColor.darkLimeGreen()
                case "C":
                    templeName.textColor = UIColor.darkOrange()
                case "V":
                    templeName.textColor = UIColor.strongYellow()
                default:
                    templeName.textColor = UIColor.lead()
                }
            }
        }
    }
    
    // function for edit view of recorded visit
    func populateView() {
        // Update the user interface for the detail item.
        if let detail = self.detailVisit {
            if let label = self.templeName {
                label.text = detail.holyPlace
                dateOfVisit = detail.dateVisited as Date?
                sealings.text = detail.sealings.description
                endowments.text = detail.endowments.description
                initiatories.text = detail.initiatories.description
                confirmations.text = detail.confirmations.description
                baptisms.text = detail.baptisms.description
                comments.text = detail.comments
                comments.sizeToFit()
                if let imageData = detail.picture {
                    let image = UIImage(data: imageData as Data)
                    pictureView.image = image
                    pictureView.isHidden = false
                    addPictureBtn.setTitle("Remove Picture", for: UIControlState.normal)
                }
                if detail.type != "T" {
                    templeView.isHidden = true
                } else {
                    sealingsStepO.value = Double(sealings.text!)!
                    endowmentsStepO.value = Double(endowments.text!)!
                    initiatoriesStepO.value = Double(initiatories.text!)!
                    confirmationsStepO.value = Double(confirmations.text!)!
                    baptismsStepO.value = Double(baptisms.text!)!
                }
                keyboardDone()
                if let theType = detail.type {
                    switch theType {
                    case "T":
                        templeName.textColor = UIColor.darkRed()
                    case "H":
                        templeName.textColor = UIColor.darkLimeGreen()
                    case "C":
                        templeName.textColor = UIColor.darkOrange()
                    case "V":
                        templeName.textColor = UIColor.strongYellow()
                    default:
                        templeName.textColor = UIColor.lead()
                    }
                }
            }
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

    var detailVisit: Visit? {
        didSet {
            // populate the view
            self.populateView()
            let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveEdit(_:)))
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
