//
//  SettingsTVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 12/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

class SettingsTableVC: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    //MARK: - Variables and Outlets
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var imageOptionSelected = 0
    
    @IBOutlet weak var minutesDelay: UITextField!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var filterSwitch: UISwitch!
    @IBOutlet weak var visitGoal: UITextField!
    @IBOutlet weak var baptismGoal: UITextField!
    @IBOutlet weak var initiatoryGoal: UITextField!
    @IBOutlet weak var endowmentGoal: UITextField!
    @IBOutlet weak var sealingGoal: UITextField!
    @IBOutlet weak var colorThemeOptions: UISegmentedControl!
    @IBOutlet weak var textColor: UISegmentedControl!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var imageOptions: UISegmentedControl!
    @IBOutlet weak var importBtn: ShadowButton!
    @IBOutlet weak var hoursWorkedSwitch: UISwitch!
    @IBOutlet weak var excludeNonOrdinanceVisitsSwitch: UISwitch!
    @IBOutlet weak var addDays: UITextField!
    @IBOutlet weak var defaultCommentsTextField: UITextField!
    
    //MARK: - Standard Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Settings"
        
        enableSwitch.isOn = notificationEnabled
        filterSwitch.isOn = notificationFilter
        filterSwitch.isEnabled = notificationEnabled
        minutesDelay.isEnabled = notificationEnabled
        hoursWorkedSwitch.isOn = ordinanceWorker
        excludeNonOrdinanceVisitsSwitch.isOn = excludeNonOrdinanceVisits
        
        // default values
        if notificationDelayInMinutes == 0 {
            notificationDelayInMinutes = 30
        }
        //if annualVisitGoal == 0 {
        //    annualVisitGoal = 12
        //}
        
        if homeDefaultPicture {
            imageOptionSelected = 0
        } else if homeVisitPicture {
            imageOptionSelected = 1
        } else {
            imageOptionSelected = 2
        }
        imageOptions.selectedSegmentIndex = imageOptionSelected
        textColor.selectedSegmentIndex = Int(homeTextColor)
        if theme == "4414" {
            colorThemeOptions.selectedSegmentIndex = 0
        } else {
            colorThemeOptions.selectedSegmentIndex = 1
        }
        
        if homeAlternatePicture != nil {
            selectedImage.image = UIImage(data: homeAlternatePicture!)
            importBtn.setTitle("Change Image", for: .normal)
            importBtn.setTitleColor(UIColor.home(), for: .normal)
        }
        
        visitGoal.text = String(annualVisitGoal)
        baptismGoal.text = String(annualBaptismGoal)
        initiatoryGoal.text = String(annualInitiatoryGoal)
        endowmentGoal.text = String(annualEndowmentGoal)
        sealingGoal.text = String(annualSealingGoal)
        minutesDelay.text = String(notificationDelayInMinutes)
        addDays.text = String(copyAddDays)
        defaultCommentsTextField.text = defaultCommentsText
        defaultCommentsTextField.placeholder = "Enter default comments text"
        keyboardDone()
        setupProfilesFooter()
        
        // Set text field delegates for auto-select behavior
        minutesDelay.delegate = self
        visitGoal.delegate = self
        baptismGoal.delegate = self
        initiatoryGoal.delegate = self
        endowmentGoal.delegate = self
        sealingGoal.delegate = self
        addDays.delegate = self
        defaultCommentsTextField.delegate = self
        
    }
    
    //MARK: - Actions
    
    @IBAction func themeColorChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            theme = "4414"
        case 1:
            theme = "3830"
        default:
            theme = "3830"
        }
        UserDefaults.standard.set(theme, forKey: "themeSelected")
        themeChanged = true
    }
    
    @IBAction func textColorChange(_ sender: UISegmentedControl) {
        homeTextColor = Int16(sender.selectedSegmentIndex)
        importBtn.setTitleColor(UIColor.home(), for: .normal)
    }
    
    @IBAction func changeImageOption(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            homeDefaultPicture = true
            homeVisitPicture = false
            homeTextColor = 0
            textColor.selectedSegmentIndex = Int(homeTextColor)
            imageOptionSelected = 0
        case 1:
            if homeVisitPictureData == nil {
                let alert = UIAlertController(title: "Not Available", message: "You haven't added any Visit images yet.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
                imageOptions.selectedSegmentIndex = imageOptionSelected
            } else {
                homeVisitPicture = true
                homeDefaultPicture = false
                imageOptionSelected = 1
            }
        default:
            if homeAlternatePicture == nil {
                let alert = UIAlertController(title: "Not Available", message: "You haven't imported an image below.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
                imageOptions.selectedSegmentIndex = imageOptionSelected
            } else {
                homeVisitPicture = false
                homeDefaultPicture = false
                imageOptionSelected = 2
            }
        }
    }
    
    @IBAction func enable(_ sender: UISwitch) {
        notificationEnabled = sender.isOn
        if notificationEnabled {
            ad.locationServiceSetup()
        }
        filterSwitch.isEnabled = notificationEnabled
        minutesDelay.isEnabled = notificationEnabled
    }
    
    @IBAction func excludeSwitched(_ sender: UISwitch) {
        excludeNonOrdinanceVisits = sender.isOn
    }
    
    @IBAction func filterEnabled(_ sender: UISwitch) {
        notificationFilter = sender.isOn
    }
    
    @IBAction func hoursWorkedEnabled(_ sender: UISwitch) {
        ordinanceWorker = sender.isOn
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    // UITextFieldDelegate method to auto-select text when field becomes active
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Delay selection slightly to ensure it works reliably
        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
    
    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        // Save settings
        notificationDelayInMinutes = Int16(minutesDelay.text!) ?? 30
        annualVisitGoal = Int(visitGoal.text!) ?? 0
        annualBaptismGoal = Int(baptismGoal.text!) ?? 0
        annualInitiatoryGoal = Int(initiatoryGoal.text!) ?? 0
        annualEndowmentGoal = Int(endowmentGoal.text!) ?? 0
        annualSealingGoal = Int(sealingGoal.text!) ?? 0
        copyAddDays = Int16(addDays.text!) ?? 7
        defaultCommentsText = defaultCommentsTextField.text ?? ""
        ad.needsVisitRefresh = true
        
        if profilesEnabled {
            ProfileManager.shared.saveGoalsToActiveProfile()
        }
        
        // Dismiss view
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Profiles (footer view approach to avoid static table conflicts)
    
    private var profilesToggle: UISwitch!
    private var manageRow: UIView!
    private var separatorView: UIView!
    private var chevronView: UIImageView!
    private var subtitleLabel: UILabel!
    
    private func setupProfilesFooter() {
        let footer = UIView()
        footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 200)
        
        let inset: CGFloat = 20
        let cellInset: CGFloat = 16
        var y: CGFloat = 28
        
        // Section header
        let headerLabel = UILabel(frame: CGRect(x: inset, y: y, width: tableView.bounds.width - inset * 2, height: 18))
        headerLabel.text = "PROFILES"
        headerLabel.font = UIFont.systemFont(ofSize: 13)
        headerLabel.textColor = .secondaryLabel
        footer.addSubview(headerLabel)
        y += 26
        
        // Rounded container
        let containerWidth = tableView.bounds.width - cellInset * 2
        let container = UIView(frame: CGRect(x: cellInset, y: y, width: containerWidth, height: 100))
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        footer.addSubview(container)
        
        // Enable Profiles row
        let rowHeight: CGFloat = 44
        let enableLabel = UILabel(frame: CGRect(x: 16, y: 0, width: containerWidth - 82, height: rowHeight))
        enableLabel.text = "Enable Profiles"
        enableLabel.font = UIFont(name: "Baskerville", size: 17) ?? .systemFont(ofSize: 17)
        container.addSubview(enableLabel)
        
        profilesToggle = UISwitch()
        profilesToggle.isOn = profilesEnabled
        profilesToggle.addTarget(self, action: #selector(profilesToggled(_:)), for: .valueChanged)
        profilesToggle.frame.origin = CGPoint(x: containerWidth - profilesToggle.frame.width - 16, y: (rowHeight - profilesToggle.frame.height) / 2)
        container.addSubview(profilesToggle)
        
        // Separator
        separatorView = UIView(frame: CGRect(x: 16, y: rowHeight, width: containerWidth - 16, height: 0.5))
        separatorView.backgroundColor = .separator
        container.addSubview(separatorView)
        
        // Manage Profiles row
        manageRow = UIView(frame: CGRect(x: 0, y: rowHeight + 0.5, width: containerWidth, height: rowHeight))
        
        let manageLabel = UILabel(frame: CGRect(x: 16, y: 0, width: containerWidth - 50, height: rowHeight))
        manageLabel.text = "Manage Profiles"
        manageLabel.font = UIFont(name: "Baskerville", size: 17) ?? .systemFont(ofSize: 17)
        manageLabel.textColor = UIColor(named: "BaptismsBlue") ?? .systemBlue
        manageRow.addSubview(manageLabel)
        
        chevronView = UIImageView(image: UIImage(systemName: "chevron.right")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        chevronView.tintColor = .tertiaryLabel
        chevronView.frame = CGRect(x: containerWidth - 30, y: (rowHeight - 16) / 2, width: 14, height: 16)
        manageRow.addSubview(chevronView)
        
        let manageTap = UITapGestureRecognizer(target: self, action: #selector(manageProfilesTapped))
        manageRow.addGestureRecognizer(manageTap)
        container.addSubview(manageRow)
        
        // Subtitle
        let subtitleY = y + container.frame.height + 8
        subtitleLabel = UILabel(frame: CGRect(x: inset, y: subtitleY, width: tableView.bounds.width - inset * 2, height: 18))
        subtitleLabel.text = "Track visits separately for family members."
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        footer.addSubview(subtitleLabel)
        
        updateProfilesFooterLayout(footer: footer, container: container)
        tableView.tableFooterView = footer
    }
    
    private func updateProfilesFooterLayout(footer: UIView? = nil, container: UIView? = nil) {
        let footerView = footer ?? tableView.tableFooterView
        guard let footerView = footerView else { return }
        
        let showManage = profilesEnabled
        manageRow.isHidden = !showManage
        separatorView.isHidden = !showManage
        
        let rowHeight: CGFloat = 44
        let containerHeight: CGFloat = showManage ? rowHeight * 2 + 0.5 : rowHeight
        
        let containerView = container ?? footerView.subviews.first(where: { $0.layer.cornerRadius == 10 })
        containerView?.frame.size.height = containerHeight
        
        let containerBottom = 28 + 26 + containerHeight
        subtitleLabel.frame.origin.y = containerBottom + 8
        
        let totalHeight = containerBottom + 8 + 18 + 20
        footerView.frame.size.height = totalHeight
        
        if footer == nil {
            tableView.tableFooterView = footerView
        }
    }
    
    @objc private func manageProfilesTapped() {
        let profileVC = ProfileManagementVC()
        let nav = UINavigationController(rootViewController: profileVC)
        present(nav, animated: true)
    }
    
    @objc func profilesToggled(_ sender: UISwitch) {
        profilesEnabled = sender.isOn
        
        if profilesEnabled {
            ad.migrateToProfiles()
            ad.loadGoalsFromActiveProfile()
            
            visitGoal.text = String(annualVisitGoal)
            baptismGoal.text = String(annualBaptismGoal)
            initiatoryGoal.text = String(annualInitiatoryGoal)
            endowmentGoal.text = String(annualEndowmentGoal)
            sealingGoal.text = String(annualSealingGoal)
        }
        
        ad.needsVisitRefresh = true
        updateProfilesFooterLayout()
    }
    
    func keyboardDone() {
        //init toolbar
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
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
        self.minutesDelay.inputAccessoryView = toolbar
        self.visitGoal.inputAccessoryView = toolbar
        self.baptismGoal.inputAccessoryView = toolbar
        self.initiatoryGoal.inputAccessoryView = toolbar
        self.endowmentGoal.inputAccessoryView = toolbar
        self.sealingGoal.inputAccessoryView = toolbar
        self.addDays.inputAccessoryView = toolbar
        self.defaultCommentsTextField.inputAccessoryView = toolbar
    }
    
    @IBAction func addPicture(_ sender: UIButton) {
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
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)


        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
        print(image?.size as Any)

        guard let imageData = image!.jpegData(compressionQuality: 1) else {
            // handle failed conversion
            print("jpg error")
            return
        }
        homeAlternatePicture = imageData as Data
        selectedImage.image = UIImage(data: homeAlternatePicture!)
        importBtn.setTitleColor(UIColor.home(), for: .normal)
        importBtn.setTitle("Change Image", for: .normal)
        homeVisitPicture = false
        homeDefaultPicture = false
        imageOptionSelected = 2
        imageOptions.selectedSegmentIndex = imageOptionSelected
        self.dismiss(animated: true, completion: nil)
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
