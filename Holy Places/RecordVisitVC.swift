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
        // When the date crosses a name-change boundary, reflect the correct historical or current name
        if let temple = resolvedTemple {
            templeName.text = temple.effectiveName(for: data)
        }
    }

    //MARK:- Variables & Outlets
    var dateOfVisit: Date?
    /// The Temple whose name is currently being recorded or edited. Set on both new-visit and edit paths.
    private var resolvedTemple: Temple?
    var placeType = String()
    var activeField: UITextField?
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let yearFormat = DateFormatter()
    var isFavorite = false
    let favoriteButton = UIButton(type: .system)
    
    private var selectedProfileIds = Set<String>()
    private var chipViews: [UIView] = []
    private var profileChipsRow: UIStackView?
    
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
        if let button = self.visitDate, let dateOfVisit = dateOfVisit {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM dd yyyy"
            let visitDateAtt = NSAttributedString(string: formatter.string(from: dateOfVisit))
            button.setAttributedTitle(visitDateAtt, for: .normal)
        }
    }
    
    @objc func saveVisit (_ sender: Any) {
        let context = getContext()
        
        yearFormat.dateFormat = "yyyy"
        
        let holyPlace = templeName.text ?? ""
        let baptismsVal = Int16(baptisms.text ?? "0") ?? 0
        let confirmationsVal = Int16(confirmations.text ?? "0") ?? 0
        let initiatoriesVal = Int16(initiatories.text ?? "0") ?? 0
        let endowmentsVal = Int16(endowments.text ?? "0") ?? 0
        let sealingsVal = Int16(sealings.text ?? "0") ?? 0
        let userComments = comments.text ?? ""
        let shiftHrsVal = Double(hoursWorked.text ?? "0") ?? 0.0
        let yearVal: String
        if let dov = dateOfVisit {
            yearVal = yearFormat.string(from: dov)
        } else {
            yearVal = yearFormat.string(from: Date())
        }
        
        var imageData: Data?
        if pictureView.isHidden == false, let image = pictureView.image {
            guard let data = image.jpegData(compressionQuality: 1) else {
                print("jpg error")
                return
            }
            imageData = data
        }
        
        let profileIds: Set<String>
        if profilesEnabled && !selectedProfileIds.isEmpty {
            profileIds = selectedProfileIds
        } else {
            profileIds = [ProfileManager.shared.effectiveProfileId() ?? ""]
        }
        
        let commentsVal = commentsForSave(userNotes: userComments, profileIds: profileIds)
        
        for profileId in profileIds {
            guard let visit = NSEntityDescription.insertNewObject(forEntityName: "Visit", into: context) as? Visit else {
                print("Failed to create Visit entity")
                continue
            }
            visit.holyPlace = holyPlace
            visit.baptisms = baptismsVal
            visit.confirmations = confirmationsVal
            visit.initiatories = initiatoriesVal
            visit.endowments = endowmentsVal
            visit.sealings = sealingsVal
            visit.comments = commentsVal
            visit.dateVisited = dateOfVisit as Date?
            visit.year = yearVal
            visit.type = placeType
            visit.shiftHrs = shiftHrsVal
            visit.isFavorite = isFavorite
            visit.profileId = profileId
            visit.picture = imageData
        }
        
        do {
            try context.save()
            print("Saving Visit(s) completed successfully for \(profileIds.count) profile(s)")
        } catch let error as NSError  {
            print("Could not save visit: \(error), \(error.userInfo)")
            let alert = UIAlertController(title: "Save Error", message: "Failed to save visit. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        ad.needsVisitRefresh = true
        ad.getVisits()
        
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
            detailVisit?.sealings = Int16(sealings.text ?? "0") ?? 0
            detailVisit?.endowments = Int16(endowments.text ?? "0") ?? 0
            detailVisit?.initiatories = Int16(initiatories.text ?? "0") ?? 0
            detailVisit?.confirmations = Int16(confirmations.text ?? "0") ?? 0
            detailVisit?.baptisms = Int16(baptisms.text ?? "0") ?? 0
            detailVisit?.shiftHrs = Double(hoursWorked.text ?? "0") ?? 0.0
        }
        detailVisit?.dateVisited = dateOfVisit as Date?
        if let dateVisited = detailVisit?.dateVisited {
            detailVisit?.year = yearFormat.string(from: dateVisited)
        } else {
            detailVisit?.year = yearFormat.string(from: Date())
        }
        detailVisit?.comments = comments.text ?? ""
        detailVisit?.isFavorite = isFavorite
        if pictureView.isHidden == false, let image = pictureView.image {
            // create NSData from UIImage
            guard let imageData = image.jpegData(compressionQuality: 1) else {
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
            print("Saving edited Visit completed successfully")
        } catch let error as NSError  {
            print("Could not save edited visit: \(error), \(error.userInfo)")
            // Show user-friendly error message
            let alert = UIAlertController(title: "Save Error", message: "Failed to save visit changes. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Update visit count for goal progress in Widget
        ad.needsVisitRefresh = true
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
        setupProfileChips()

        // Disable the swipe to make sure you get your chance to save
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Set text field delegates for auto-select behavior
        sealings.delegate = self
        endowments.delegate = self
        initiatories.delegate = self
        confirmations.delegate = self
        baptisms.delegate = self
        hoursWorked.delegate = self
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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
        
        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(RecordVisitVC.dismissKeyboard))
        
        // Customize Done button font
        let baskervilleFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let baptismsBlue: UIColor = UIColor(named: "BaptismsBlue") ?? UIColor.blue
        
        doneBtn.setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .normal)
        
        doneBtn.setTitleTextAttributes([
            .font: baskervilleFont,
            .foregroundColor: baptismsBlue
        ], for: .highlighted)
        
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
    
    // MARK: - Profile Chips
    
    /// When profiles are enabled, appends `Visit Recorded for: <names>` after user notes (blank line separator),
    /// unless the visit is recorded for the active profile only.
    private func commentsForSave(userNotes: String, profileIds: Set<String>) -> String {
        guard profilesEnabled else { return userNotes }
        
        if profileIds.count == 1, let onlyId = profileIds.first, onlyId == activeProfileId {
            return userNotes
        }
        
        let idSet = profileIds
        let names = ProfileManager.shared.allProfiles()
            .compactMap { profile -> String? in
                guard let pid = profile.value(forKey: "profileId") as? String, idSet.contains(pid) else { return nil }
                return profile.value(forKey: "name") as? String
            }
        let namesList = names.joined(separator: ", ")
        let suffix = "Visit Recorded for: \(namesList)"
        let trimmed = userNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return suffix
        }
        return trimmed + "\n\n" + suffix
    }
    
    private func setupProfileChips() {
        guard profilesEnabled, detailVisit == nil else { return }
        
        if let activeId = activeProfileId {
            selectedProfileIds.insert(activeId)
        }
        
        let allProfiles = ProfileManager.shared.allProfiles()
        guard allProfiles.count > 1 else { return }
        
        guard let notesStack = comments.superview as? UIStackView,
              let contentStack = notesStack.superview as? UIStackView else { return }
        
        guard let notesIndex = contentStack.arrangedSubviews.firstIndex(of: notesStack) else { return }
        
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        wrapper.spacing = 6
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Record for:"
        label.font = UIFont(name: "Baskerville", size: 15) ?? .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        wrapper.addArrangedSubview(label)
        
        let flowContainer = FlowLayoutView()
        flowContainer.spacing = 6
        flowContainer.rowSpacing = 6
        flowContainer.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addArrangedSubview(flowContainer)
        
        let chipHeight: CGFloat = 32
        
        for profile in allProfiles {
            let profileId = profile.value(forKey: "profileId") as? String ?? ""
            let name = profile.value(forKey: "name") as? String ?? ""
            let iconName = profile.value(forKey: "iconName") as? String ?? "person.fill"
            
            let chip = UIView()
            chip.accessibilityIdentifier = profileId
            chip.layer.cornerRadius = chipHeight / 2
            chip.clipsToBounds = true
            chip.translatesAutoresizingMaskIntoConstraints = false
            chip.isUserInteractionEnabled = true
            
            let iconView = UIImageView()
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            iconView.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
            iconView.tag = 100
            chip.addSubview(iconView)
            
            let nameLabel = UILabel()
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.text = name
            nameLabel.font = UIFont(name: "Baskerville", size: 13) ?? .systemFont(ofSize: 13)
            nameLabel.tag = 101
            chip.addSubview(nameLabel)
            
            NSLayoutConstraint.activate([
                chip.heightAnchor.constraint(equalToConstant: chipHeight),
                iconView.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 8),
                iconView.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 16),
                iconView.heightAnchor.constraint(equalToConstant: 16),
                nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
                nameLabel.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
                nameLabel.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -10)
            ])
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(profileChipTapped(_:)))
            chip.addGestureRecognizer(tap)
            
            let isSelected = selectedProfileIds.contains(profileId)
            applyChipStyle(chip, selected: isSelected)
            
            flowContainer.addArrangedSubview(chip)
            chipViews.append(chip)
        }
        
        contentStack.insertArrangedSubview(wrapper, at: notesIndex + 1)
        profileChipsRow = wrapper
    }
    
    @objc private func profileChipTapped(_ sender: UITapGestureRecognizer) {
        guard let chip = sender.view,
              let profileId = chip.accessibilityIdentifier else { return }
        
        if selectedProfileIds.contains(profileId) {
            guard selectedProfileIds.count > 1 else { return }
            selectedProfileIds.remove(profileId)
            applyChipStyle(chip, selected: false)
        } else {
            selectedProfileIds.insert(profileId)
            applyChipStyle(chip, selected: true)
        }
    }
    
    private func applyChipStyle(_ chip: UIView, selected: Bool) {
        let accentColor = UIColor(named: "BaptismsBlue") ?? .systemBlue
        let iconView = chip.viewWithTag(100) as? UIImageView
        let nameLabel = chip.viewWithTag(101) as? UILabel
        
        if selected {
            chip.backgroundColor = accentColor
            iconView?.tintColor = .white
            nameLabel?.textColor = .white
        } else {
            chip.backgroundColor = UIColor.systemGray5
            iconView?.tintColor = .secondaryLabel
            nameLabel?.textColor = .secondaryLabel
        }
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    // UITextFieldDelegate method to auto-select text when field becomes active
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        
        // Delay selection slightly to ensure it works reliably
        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let activeField = activeField else {
            return
        }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // Get the frame of the active field in the scroll view's coordinate system
        let activeFieldFrame = activeField.convert(activeField.bounds, to: scrollView)
        
        // Calculate the visible area above the keyboard
        let visibleHeight = scrollView.frame.height - keyboardSize.height
        
        // Calculate the bottom of the field (including some padding for the toolbar)
        let fieldBottom = activeFieldFrame.origin.y + activeFieldFrame.height + 50
        
        // Check if the field bottom would be hidden by keyboard
        let currentVisibleBottom = scrollView.contentOffset.y + visibleHeight
        
        if fieldBottom > currentVisibleBottom {
            // Only scroll enough to show the field above keyboard, don't force it to the top
            let targetOffset = fieldBottom - visibleHeight + 20
            let scrollPoint = CGPoint(x: 0, y: max(0, targetOffset))
            scrollView.setContentOffset(scrollPoint, animated: true)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @IBAction func hoursWorkedText(_ sender: UITextField) {
        if sender.text?.isEmpty == true {
            sender.text = "0"
        }
        self.hoursWorkedStepO.value = Double(sender.text ?? "0") ?? 0.0
    }
    @IBAction func sealingsText(_ sender: UITextField) {
        if sender.text?.isEmpty == true {
            sender.text = "0"
        }
        self.sealingsStepO.value = Double(sender.text ?? "0") ?? 0.0
    }
    @IBAction func endowmentsText(_ sender: UITextField) {
        if sender.text?.isEmpty == true {
            sender.text = "0"
        }
        self.endowmentsStepO.value = Double(sender.text ?? "0") ?? 0.0
    }
    @IBAction func initiatoriesText(_ sender: UITextField) {
        if sender.text?.isEmpty == true {
            sender.text = "0"
        }
        self.initiatoriesStepO.value = Double(sender.text ?? "0") ?? 0.0
    }
    @IBAction func confirmationsText(_ sender: UITextField) {
        if sender.text?.isEmpty == true {
            sender.text = "0"
        }
        self.confirmationsStepO.value = Double(sender.text ?? "0") ?? 0.0
    }
    @IBAction func baptismsText(_ sender: UITextField) {
        if sender.text?.isEmpty == true {
            sender.text = "0"
        }
        self.baptismsStepO.value = Double(sender.text ?? "0") ?? 0.0
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
            resolvedTemple = detail
            if let label = self.templeName {
                label.text = detail.templeName
                if detail.templeName == placeFromNotification {
                    // Since this place is the same as recently visited place, set the date to saved date
                    dateOfVisit = dateFromNotification
                    // Set default comments text for new visits from notification
                    comments.text = defaultCommentsText
                    // Reset recently visited variables
                    dateFromNotification = nil
                    placeFromNotification = nil
                } else if copyVisit != nil {
                    // Copy visit details and increament date by a week
                    let visitToCopy = copyVisit!
                    if let dateVisited = visitToCopy.dateVisited,
                       let modifiedDate = Calendar.current.date(byAdding: .day, value: Int(copyAddDays), to: dateVisited) {
                        dateOfVisit = modifiedDate
                    } else {
                        dateOfVisit = Date()
                    }
                    hoursWorked.text = visitToCopy.shiftHrs.description
                    sealings.text = visitToCopy.sealings.description
                    endowments.text = visitToCopy.endowments.description
                    initiatories.text = visitToCopy.initiatories.description
                    confirmations.text = visitToCopy.confirmations.description
                    baptisms.text = visitToCopy.baptisms.description
                    comments.text = visitToCopy.comments ?? ""
                    comments.sizeToFit()
                    // Reset the global copyVisit variable after use
                    copyVisit = nil
                } else {
                    dateOfVisit = Date()
                    // Set default comments text for new visits
                    comments.text = defaultCommentsText
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
            // Resolve the Temple so DateChanged() can apply historical name logic when editing
            let currentHP = detail.holyPlace ?? ""
            resolvedTemple = allPlaces.first { $0.templeName == currentHP }
                ?? allPlaces.first { $0.nameChanges.contains { $0.oldName == currentHP } }
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
                    hoursWorkedStepO.value = Double(hoursWorked.text ?? "0") ?? 0.0
                    sealingsStepO.value = Double(sealings.text ?? "0") ?? 0.0
                    endowmentsStepO.value = Double(endowments.text ?? "0") ?? 0.0
                    initiatoriesStepO.value = Double(initiatories.text ?? "0") ?? 0.0
                    confirmationsStepO.value = Double(confirmations.text ?? "0") ?? 0.0
                    baptismsStepO.value = Double(baptisms.text ?? "0") ?? 0.0
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

// MARK: - Flow Layout View (wraps subviews into rows)

class FlowLayoutView: UIView {
    var spacing: CGFloat = 6
    var rowSpacing: CGFloat = 6
    
    private var arrangedSubviews: [UIView] = []
    
    func addArrangedSubview(_ view: UIView) {
        arrangedSubviews.append(view)
        addSubview(view)
    }
    
    private func fittingSize(for view: UIView) -> CGSize {
        let target = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return view.systemLayoutSizeFitting(target,
                                            withHorizontalFittingPriority: .fittingSizeLevel,
                                            verticalFittingPriority: .fittingSizeLevel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in arrangedSubviews {
            let size = fittingSize(for: view)
            
            if x + size.width > bounds.width && x > 0 {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            
            view.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: CGSize {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 32
        
        for view in arrangedSubviews {
            let size = fittingSize(for: view)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        return CGSize(width: UIView.noIntrinsicMetric, height: y + rowHeight)
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
