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
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let yearFormat = DateFormatter()
    var isFavorite = false
    let favoriteButton = UIButton(type: .system)
    
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
    @IBOutlet weak var ordinanceWorkerSV: UIStackView!
    @IBOutlet weak var hoursWorked: UITextField!
    @IBOutlet weak var hoursWorkedStepO: UIStepper!
    
    //MARK:- CoreData functions
    func getContext () -> NSManagedObjectContext {
        return ad.persistentContainer.viewContext
    }

    func setDate() {
        //dateOfVisit = sender.date
        if let button = self.visitDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM dd yyyy"
            let visitDateAtt = NSAttributedString(string: formatter.string(from: dateOfVisit!))
            button.setAttributedTitle(visitDateAtt, for: .normal)
        }
    }
    
    @objc func saveVisit (_ sender: Any) {
        let context = getContext()
        
        yearFormat.dateFormat = "yyyy"
        
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
        visit.year = yearFormat.string(from: visit.dateVisited!)
        visit.type = placeType
        visit.shiftHrs = Double(hoursWorked.text!)!
        visit.isFavorite = isFavorite
        if pictureView.isHidden == false {
            // create NSData from UIImage
            guard let imageData = pictureView.image!.jpegData(compressionQuality: 1) else {
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
        ad.getVisits()
        
        //_ = navigationController?.popViewController(animated: true)
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func saveEdit (_ sender: Any) {
        let context = getContext()
        
        yearFormat.dateFormat = "yyyy"
        
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
            detailVisit?.shiftHrs = Double(hoursWorked.text!)!
        }
        detailVisit?.dateVisited = dateOfVisit as Date?
        detailVisit?.year = yearFormat.string(from: (detailVisit?.dateVisited)!)
        detailVisit?.comments = comments.text!
        detailVisit?.isFavorite = isFavorite
        if pictureView.isHidden == false {
            // create NSData from UIImage
            guard let imageData = pictureView.image!.jpegData(compressionQuality: 1) else {
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
        
        // Update visit count for goal progress in Widget
        ad.getVisits()
        
        _ = navigationController?.popViewController(animated: true)

    }
    
    //MARK:- Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        populateView()
        setDate()
        setupFavoriteButton()

        // Disable the swipe to make sure you get your chance to save
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show tab bar when leaving
        tabBarController?.tabBar.isHidden = false
    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(RecordVisitVC.dismissKeyboard))
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
        self.hoursWorked.inputAccessoryView = toolbar
    }
    
    //MARK:- Actions
    
    private func setupFavoriteButton() {
        favoriteButton.setImage(UIImage(systemName: isFavorite ? "star.fill" : "star"), for: .normal)
        favoriteButton.tintColor = isFavorite ? UIColor.darkTangerine() : .gray
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(favoriteButton)
        
        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 85),
            favoriteButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            favoriteButton.widthAnchor.constraint(equalToConstant: 40),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func toggleFavorite() {
        isFavorite.toggle()
        let imageName = isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? UIColor.darkTangerine() : .gray
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    @IBAction func hoursWorkedText(_ sender: UITextField) {
        if (sender.text?.isEmpty)!{
            sender.text = "0"
        }
        self.hoursWorkedStepO.value = Double(sender.text!)!
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
    
    @IBAction func hoursWorkedStep(_ sender: UIStepper) {
        self.hoursWorked.text = sender.value.description
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
            addPictureBtn.setTitle("Add Picture", for: UIControl.State.normal)
        } else {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
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

    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        pictureView.isHidden = false
        addPictureBtn.setTitle("Remove Picture", for: UIControl.State.normal)
        var image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
        print(image?.size as Any)
//        let size = CGSize(width: (image?.size.width)! / 1.5, height: (image?.size.height)! / 1.5)
        
        if image!.size.height > 2000 {
            // reduce size of picture if it is very large
            do {
                if let smallImage = try self.imageWithImage(image: image!, scaledToSize: CGSize(width: image!.size.width/2, height: image!.size.height/2)) {
                    print("reduced image to \(smallImage.size.height)")
                    image = smallImage
                } else {
                    print("failed to reduce image")
                }
            } catch {
                print("failed to reduce image - throw")
            }
        }
    
//        pictureView.image = image?.scale(toSize: size)
        pictureView.image = image
        print(pictureView.image?.size as Any)
//        pictureView.sizeThatFits(size)

        self.dismiss(animated: true, completion: nil)
    }
    
    func imageWithImage(image:UIImage? ,scaledToSize newSize:CGSize) throws -> UIImage?
    {
        UIGraphicsBeginImageContext( newSize )
        image?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return newImage
        } else {
            UIGraphicsEndImageContext()
            return nil
        }

    }


    //MARK:- Initial Set-up functions
    func configureView() {
        
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                if detail.templeName == placeFromNotification {
                    // Since this place is the same as recently visited place, set the date to saved date
                    dateOfVisit = dateFromNotification
                    // Reset recently visited variables
                    dateFromNotification = nil
                    placeFromNotification = nil
                } else if copyVisit != nil {
                    // Copy visit details and increament date by a week
                    let modifiedDate = Calendar.current.date(byAdding: .day, value: Int(copyAddDays), to: copyVisit!.dateVisited!)!
                    dateOfVisit = modifiedDate
                    hoursWorked.text = copyVisit!.shiftHrs.description
                    sealings.text = copyVisit!.sealings.description
                    endowments.text = copyVisit!.endowments.description
                    initiatories.text = copyVisit!.initiatories.description
                    confirmations.text = copyVisit!.confirmations.description
                    baptisms.text = copyVisit!.baptisms.description
                    comments.text = copyVisit!.comments
                    comments.sizeToFit()
                    copyVisit = nil
                } else {
                    dateOfVisit = Date()
                }
                placeType = detail.templeType
                if detail.templeType != "T" {
                    templeView.isHidden = true
                }
                self.title = "Record Visit"
                
                keyboardDone()
                switch detail.templeType {
                case "T":
                    templeName.textColor = templeColor
                case "H":
                    templeName.textColor = historicalColor
                case "C":
                    templeName.textColor = constructionColor
                case "V":
                    templeName.textColor = visitorCenterColor
                default:
                    templeName.textColor = defaultColor
                }
                
                // enable the Hours worked stack view when needed
                ordinanceWorkerSV.isHidden = !ordinanceWorker
                
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
                isFavorite = detail.isFavorite
                hoursWorked.text = detail.shiftHrs.description
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
                    addPictureBtn.setTitle("Remove Picture", for: UIControl.State.normal)
                }
                if detail.type != "T" {
                    templeView.isHidden = true
                } else {
                    hoursWorkedStepO.value = Double(hoursWorked.text!)!
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
                        templeName.textColor = templeColor
                    case "H":
                        templeName.textColor = historicalColor
                    case "C":
                        templeName.textColor = constructionColor
                    case "V":
                        templeName.textColor = visitorCenterColor
                    default:
                        templeName.textColor = defaultColor
                    }
                }
                // enable the Hours worked stack view when needed
                ordinanceWorkerSV.isHidden = !ordinanceWorker
                
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
            DispatchQueue.main.async {
                self.populateView() // Refresh UI when detailVisit changes
            }
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
        if segue.identifier == "quickRecordVisit" {
            // Change the back button on the Record Visit VC to Cancel
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
