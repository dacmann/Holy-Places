//
//  HomeVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/14/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
//import StoreKit

//class HomeVC: UIViewController, SKProductsRequestDelegate {
class HomeVC: UIViewController, XMLParserDelegate, UITabBarControllerDelegate {
    
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private var profileButton: UIButton!
    
    //MARK: - Outlets & Actions
    @IBOutlet weak var info: UIButton!
    @IBOutlet weak var goalTitle: UILabel!
    @IBOutlet weak var goal: UILabel!
    @IBOutlet weak var settings: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var appName: UILabel!
    @IBOutlet weak var holyPlaces: UILabel!
    @IBOutlet weak var reference: UILabel!
    @IBOutlet weak var topLine: UIView!
    @IBOutlet weak var bottomLine: UIView!
    @IBOutlet weak var share: UIButton!
    @IBOutlet weak var visitDate: UILabel!
    @IBOutlet weak var goalSpacerConstraint: NSLayoutConstraint!
    @IBOutlet weak var achievementBtn: UIButton!
    @IBOutlet weak var achBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var achievementBtnView: UIView!
    @IBOutlet weak var achievementButtonWidth: NSLayoutConstraint!
    
    @IBAction func shareHolyPlaces(_ sender: UIButton) {
        let shareVC = ShareVC(sourceView: sender)
        present(shareVC, animated: true)
    }

    
    //MARK: - Standard Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Apply selected home background as early as possible to avoid launch-time flash.
        refreshBackgroundImage()
        
        // Do any additional setup after loading the view.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        currentYear = formatter.string(from: Date())
        
        // Grab In-App purchase information
//        fetchProducts(matchingIdentifiers: ["GreatTip99", "GreaterTip299", "GreatestTip499"])
        
        //Unicode Character for 'GEAR'
        settings.setTitle("\u{2699}\u{0000FE0E}", for: .normal)
        
        // Add swipe gestures to move to enter content
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        self.tabBarController?.delegate = self
        
        // Add notification observer to refresh background image when app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // download all place images if needed
        //ad.downloadImage()
        
        // Check if newly installed
        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        if !previouslyLaunched {
            UserDefaults.standard.set(true, forKey: "previouslyLaunched")
            UserDefaults.standard.set("3830", forKey: "themeSelected")
            UserDefaults.standard.set(false, forKey: "addVisitClosestPlace")
            checkedForUpdate = Date()
        }
        
        setupProfileButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(profileDidChange), name: ProfileManager.profileDidChangeNotification, object: nil)
    }
    
    private func setupProfileButton() {
        profileButton = UIButton(type: .system)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.showsMenuAsPrimaryAction = true
        profileButton.titleLabel?.font = UIFont(name: "Baskerville", size: 14) ?? .systemFont(ofSize: 14)
        view.addSubview(profileButton)
        
        NSLayoutConstraint.activate([
            profileButton.bottomAnchor.constraint(equalTo: info.topAnchor, constant: -4),
            profileButton.leadingAnchor.constraint(equalTo: info.leadingAnchor, constant: 8),
            profileButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func updateProfileButton() {
        profileButton.isHidden = !profilesEnabled
        guard profilesEnabled else { return }
        
        let iconName = ProfileManager.shared.activeProfileIconName()
        let name = ProfileManager.shared.activeProfileName()
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        profileButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        profileButton.setTitle(" \(name) ", for: .normal)
        profileButton.tintColor = UIColor.home()
        profileButton.setTitleColor(UIColor.home(), for: .normal)
        
        let allProfiles = ProfileManager.shared.allProfiles()
        let actions = allProfiles.map { profile -> UIAction in
            let pName = profile.value(forKey: "name") as? String ?? ""
            let pIcon = profile.value(forKey: "iconName") as? String ?? "person.fill"
            let pId = profile.value(forKey: "profileId") as? String ?? ""
            let isActive = pId == activeProfileId
            
            return UIAction(
                title: pName,
                image: UIImage(systemName: pIcon),
                state: isActive ? .on : .off
            ) { _ in
                ProfileManager.shared.setActiveProfile(profile)
            }
        }
        
        profileButton.menu = UIMenu(title: "Switch Profile", children: actions)
    }
    
    @objc private func profileDidChange() {
        updateProfileButton()
        goal.text = goalProgress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if profilesEnabled {
            goalTitle.text = "\(ProfileManager.shared.activeProfileName())'s \(currentYear) Goals"
        } else {
            goalTitle.text = "\(currentYear) Goal Progress"
        }
        let attributedString = NSMutableAttributedString(string: goalTitle.text!)
        attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(3.0), range: NSRange(location: 0, length: attributedString.length))
        goalTitle.attributedText = attributedString
        
        if completed.count > 0 {
            if let iconImage = UIImage(named: completed[0].iconName) {
                achievementBtn.setImage(iconImage, for: .normal)
            } else {
                achievementBtn.setImage(UIImage(named: "ach12MT"), for: .normal)
            }
            achievementBtnView.isHidden = false
        } else {
            achievementBtnView.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Pick a new random visit photo each time the home tab is shown, then display it.
        if homeVisitPicture {
            ad.pickRandomHomeVisitPhoto()
        }
        refreshBackgroundImage()
        
        if profilesEnabled {
            goalTitle.text = "\(ProfileManager.shared.activeProfileName())'s \(currentYear) Goals"
        } else {
            goalTitle.text = "\(currentYear) Goal Progress"
        }
        let attributedString = NSMutableAttributedString(string: goalTitle.text!)
        attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(3.0), range: NSRange(location: 0, length: attributedString.length))
        goalTitle.attributedText = attributedString
        
        if annualVisitGoal == 0 && ad.needsVisitRefresh {
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue("SET GOAL IN APP", forKey: "goalProgress")
        }
        
        if checkedForUpdate?.daysBetweenDate(toDate: Date()) ?? 1 > 0 {
            ad.refreshTemples()
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            achievementButtonWidth.constant = 100
        } else {
            let size = view.frame.width * 0.20
            achievementButtonWidth.constant = size
        }
        achievementBtnView.layer.cornerRadius = 10
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // set colors based on theme
        theme = UserDefaults.standard.string(forKey: "themeSelected") ?? "3830"
        templeColor = UIColor(named: "Temples"+theme) ?? UIColor.purple
        historicalColor = UIColor(named: "Historical"+theme) ?? UIColor.orange
        announcedColor = UIColor(named: "Announced"+theme) ?? UIColor.yellow
        constructionColor = UIColor(named: "Construction"+theme) ?? UIColor.olive()
        visitorCenterColor = UIColor(named: "VisitorCenters"+theme) ?? UIColor.yellow
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Animate the transition between tabs
        guard let fromView = self.tabBarController?.selectedViewController?.view, let toView = viewController.view else {
            return false
        }
        if fromView != toView {
            UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        }

        return true
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizer.Direction.right {
            tabBarController?.selectedIndex = 4
        } else if gesture.direction == UISwipeGestureRecognizer.Direction.left {
            tabBarController?.selectedIndex = 1
        }
    }

    fileprivate func setImage(landscape: Bool) {
        var defaultImageName = "PCC"
        if self.traitCollection.horizontalSizeClass == .regular {
            defaultImageName = "PCCW"
        }
        
        if landscape {
            defaultImageName = "PCCL"
            if UIDevice.current.userInterfaceIdiom == .pad {
                goalSpacerConstraint = goalSpacerConstraint.changeMultiplier(multiplier: 0.04)
            } else {
                goalSpacerConstraint = goalSpacerConstraint.changeMultiplier(multiplier: 0.09)
            }
        }
        if homeDefaultPicture {
            backgroundImage.image = UIImage(imageLiteralResourceName: defaultImageName)
            visitDate.isHidden = true
        } else {
            if homeVisitPicture {
                if let imageData = homeVisitPictureData {
                    backgroundImage.image = UIImage(data: imageData)
                    visitDate.text = homeVisitDate
                    visitDate.isHidden = false
                } else {
                    backgroundImage.image = UIImage(imageLiteralResourceName: defaultImageName)
                    visitDate.isHidden = true
                }
            } else {
                if let imageData = homeAlternatePicture {
                    backgroundImage.image = UIImage(data: imageData)
                    visitDate.isHidden = true
                } else {
                    backgroundImage.image = UIImage(imageLiteralResourceName: defaultImageName)
                    visitDate.isHidden = true
                }
            }
        }
    }
    
    func refreshBackgroundImage() {
        // Refresh the background image based on current settings
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let interfaceOrientation = windowScene.interfaceOrientation
            let isLandscape = interfaceOrientation.isLandscape
            setImage(landscape: isLandscape)
        } else {
            setImage(landscape: false)
        }
    }
    
    @objc func appDidBecomeActive() {
        // Refresh background image when app becomes active
        refreshBackgroundImage()
    }
    
    deinit {
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Pop Welcome message
        if changesDate != "" {
            var changesMsg = changesMsg1
            if changesMsg2 != ""
            {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg2)
            }
            if changesMsg3 != ""
            {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg3)
            }
            let alert = UIAlertController(title: changesDate + " Message", message: changesMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle OK (cancel) Logic here")
                // clear out message now that it has been presented
                changesDate = ""
            }))
            self.present(alert, animated: true)
        }
        
        if ad.needsVisitRefresh {
            ad.getVisits()
            refreshBackgroundImage()
        }
        goal.text = goalProgress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if completed.count > 0 {
            if let iconImage = UIImage(named: completed[0].iconName) {
                achievementBtn.setImage(iconImage, for: .normal)
            } else {
                achievementBtn.setImage(UIImage(named: "ach12MT"), for: .normal)
            }
            achievementBtnView.isHidden = false
        } else {
            achievementBtnView.isHidden = true
        }
        
        updateProfileButton()
        
        // Home Screen Customizations
        appName.textColor = UIColor.home()
        wrapLabelWithOverlay(label: appName, backgroundColor: UIColor.home(), opacity: 0.0)
        holyPlaces.textColor = UIColor.home()
        wrapLabelWithOverlay(label: holyPlaces, backgroundColor: UIColor.home(), opacity: 0.0)
        reference.textColor = UIColor.home()
        wrapLabelWithOverlay(label: reference, backgroundColor: UIColor.home(), opacity: 0.0)
        goalTitle.textColor = UIColor.home()
        wrapLabelWithOverlay(label: goalTitle, backgroundColor: UIColor.home())
        goal.textColor = UIColor.home()
        wrapLabelWithOverlay(label: goal, backgroundColor: UIColor.home())
        info.tintColor = UIColor.home()
        topLine.backgroundColor = UIColor.home()
        bottomLine.backgroundColor = UIColor.home()
        share.titleLabel?.textColor = UIColor.home()
        settings.titleLabel?.textColor = UIColor.home()
        visitDate.textColor = UIColor.home()

        if UIDevice.current.userInterfaceIdiom != .pad {
            AppUtility.lockOrientation(.portrait)
        }
        
        // Show "What's New" pop-up for new app version
        showWhatsNewPopup()
        
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation.isPortrait && !UIApplication.shared.isSplitOrSlideOver {
            setImage(landscape: true)
        } else {
            setImage(landscape: false)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if homeTextColor == 0 {
            return .lightContent
        } else {
            return .default
        }
        
    }
    func wrapLabelWithOverlay(label: UILabel, backgroundColor: UIColor = .black, opacity: CGFloat = 0.05, cornerRadius: CGFloat = 8) {
        guard let superview = label.superview else { return }

        // Remove existing overlay if it exists
        superview.subviews
            .filter { $0.tag == 999 && $0.frame.intersects(label.frame) }
            .forEach { $0.removeFromSuperview() }

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = backgroundColor.withAlphaComponent(opacity)
        overlay.layer.cornerRadius = cornerRadius
        overlay.layer.masksToBounds = true
        overlay.tag = 999 // Tag to identify the overlay

        superview.insertSubview(overlay, belowSubview: label)

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -8),
            overlay.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            overlay.topAnchor.constraint(equalTo: label.topAnchor, constant: -4),
            overlay.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4)
        ])

        label.layer.shadowColor = (backgroundColor == .black ? UIColor.white.cgColor : UIColor.black.cgColor)
        label.layer.shadowOffset = CGSize(width: 1, height: 1)
        label.layer.shadowOpacity = 0.7
        label.layer.shadowRadius = 1
    }

    // MARK: - What's New Pop-up
    private func showWhatsNewPopup() {
        // Get current app version
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("Could not retrieve app version")
            return
        }
        
        // Check if this version's pop-up has already been shown
        let lastVersionShown = UserDefaults.standard.string(forKey: "lastAppVersionShown")
        if lastVersionShown == currentVersion {
            print("Pop-up already shown for version \(currentVersion)")
            return // Pop-up already shown for this version
        }
        
        // Define "What's New" content for each version
        let whatsNewContent: [String: String] = [
            "5.7": """
                New:
                - Map Timeline now starts from the very beginning — Kirtland Temple (1836) and the original Nauvoo Temple (1846) appear before St. George, the first modern active temple
                - Temple pins show the name that was in use at the time as you move through the timeline
                
                Bug Fixes:
                - Back button missing when opening the map from a place detail
                - Home tab background image briefly flashed the default photo on launch when a custom image was set
                - Summary tab crash when top places included a renamed temple
                """,
            "5.6": """
                New:
                - Map Timeline — tap Timeline on now full-screen map to watch temples spread across the world year by year, or tap Play for an animated journey from 1877 to today
                - Historical names and images for renamed places — older visits keep the name and photo from when you were there
                - Redesigned Share on the Home tab — App Store/Google Play links, QR codes, and a printable promo PDF
                
                Improvements:
                - Info screen rebuilt in SwiftUI; Info, Settings, Map filters, and Achievements now open as sheets on iPad
                """,
            "5.5": """
                What's new:
                - Copy visits to another profile using the new select mode on the Visits tab — search for visits, select all results, and copy them in one tap
                - Visit import now treats matching place and date as duplicates, even when comments differ
                
                Version 5.4 recap:
                - Record a visit for multiple profiles at once; notes add a \"Visit Recorded for:\" line when the visit isn't only for your active profile
                
                Version 5.3 recap:
                - Profiles: Track visits separately for family members — enable in Settings and switch profiles from the Home screen
                - Watch app updated with new images and improved background launch reliability
                - Large widget now navigates directly to the featured visit
                """,
            "5.4": """
                What's new:
                - Record a visit for multiple profiles at once; notes add a \"Visit Recorded for:\" line when the visit isn't only for your active profile
                - Couple of bug fixes and improvements
                
                Version 5.3 recap:
                - Profiles for family members, watch and widget updates, map marker tweaks, large-widget visit shortcut, and fixes for saving edits and Home tab lag
                """,
            "5.3": """
                New:
                - Profiles: Track visits separately for family members — enable in Settings and switch profiles from the Home screen
                
                Improvements:
                - Watch app updated with new images and improved background launch reliability
                - Map marker sizes refined at various zoom levels
                - Medium and small widget layouts adjusted for better readability
                - Large widget now navigates directly to the featured visit
                
                Bug Fixes:
                - Fixed an issue saving visit edits
                - Fixed lag when selecting the Home tab
                """,
            "5.2": """
                Enjoy a more connected experience with widgets and improved reliability throughout the app.

                New Widgets:
                - Large widget: Daily temple visit photos with place name and visit date
                - Medium widget: Latest achievement and current year goal progress
                - Small widget: Daily inspirational quote
                
                Improvements:
                - Fixed temple visit reminder notifications
                - Updated filter icon for better clarity
                - Visit detail view now shows the temple's place image when no visit photo is attached
                - A number of bug fixes
                """,
            "5.1": """
                Bug Fixes:
                - Fixed scope control buttons (All/Visited/Not Visited) touch area issues on iOS 26 liquid glass UI
                - Fixed keyboard covering entry fields on Record Visit screen - content now auto-scrolls to keep fields visible
                
                Enhancements:
                - Entry fields now auto-select their values when tapped for easier editing (Record Visit and Settings screens)
                """,
            "5.0": """
                - Visual updates: 
                    - Support for new Liquid Glass UI
                    - Map pins resize smoothly as you zoom
                    - Visited/Not Visited scope buttons surfaced on Places tab
                    - New button icons in Visit tab header
                - Cleaner navigation: 
                    - Tab bar hidden on child views
                    - Inactive tab names are hidden
                    - Place details from map view now independent of Places tab
                    - Visit filters moved to a quick-access header button
                - Improved search with support for multiple terms.
                - Visits tab has an enhanced sort menu and sort-selected subtitle.
                - Visit photos can now be included in an export/import.
                - Customize in Settings the default message when adding a visit.
                - Stability improvements for saving visits and other bugs.
                """,
            "4.8": """
                Recently added features:
                
                * A new companion Apple Watch app displays a celestial-themed timer and gently taps your wrist at set intervals — ideal for staying attentive in a temple session.
                
                * Tapping on a Place address will now display navigation options with Apple Maps, Google Maps and Waze.
                
                * Updated the Achievements with all new, hand-drawn icons that look great in dark mode and added new Endowment and Historic Sites achievements.
                
                * New 'Announced Date' sort option on the Places tab to easily see which temples were announced at each conference.
                """
        ]
        
        // Get content for current version, or skip if none defined
        guard let message = whatsNewContent[currentVersion] else {
            print("No 'What's New' content defined for version \(currentVersion)")
            return
        }
        
        // Create pop-up view
        let popupView = UIView()
        popupView.translatesAutoresizingMaskIntoConstraints = false
        // Use tertiary system background for better contrast in dark mode
        popupView.backgroundColor = UIColor.tertiarySystemBackground
        popupView.layer.cornerRadius = 12
        popupView.layer.masksToBounds = true
        popupView.layer.borderWidth = 1
        popupView.layer.borderColor = UIColor(named: "BaptismsBlue")?.cgColor ?? UIColor.blue.cgColor
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let titleText = "What's New in Version \(currentVersion)"
        titleLabel.text = titleText
        titleLabel.font = UIFont(name: "Baskerville-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        // Use primary label color - adapts to dark mode automatically
        titleLabel.textColor = UIColor.label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0 // Allow wrapping if needed
        print("Title set to: \(titleText)") // Debug print to confirm title
        
        // Message label
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.font = UIFont(name: "Baskerville", size: 16) ?? UIFont.systemFont(ofSize: 16)
        // Use primary label color - adapts to dark mode automatically
        messageLabel.textColor = UIColor.label
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        
        // OK button
        let okButton = UIButton(type: .system)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.setTitle("OK", for: .normal)
        okButton.titleLabel?.font = UIFont(name: "Baskerville", size: 18) ?? UIFont.systemFont(ofSize: 18)
        okButton.setTitleColor(UIColor(named: "BaptismsBlue") ?? UIColor.blue, for: .normal)
        okButton.addTarget(self, action: #selector(dismissWhatsNewPopup), for: .touchUpInside)
        
        // Stack view to arrange title, message, and button
        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel, okButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill // Ensure subviews fill the width
        stackView.distribution = .equalSpacing // Distribute space evenly
        
        popupView.addSubview(stackView)
        view.addSubview(popupView)
        
        // Constraints
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            popupView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7), // Increased to ensure space
            
            stackView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -20),
            
            titleLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        
        // Animate pop-up appearance
        popupView.alpha = 0
        popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3) {
            popupView.alpha = 1
            popupView.transform = .identity
        }
        
        // Store the current version to prevent re-showing
        UserDefaults.standard.set(currentVersion, forKey: "lastAppVersionShown")
        print("Showing 'What's New' pop-up for version \(currentVersion)")
    }
    
    @objc private func dismissWhatsNewPopup(_ sender: UIButton) {
        // Animate pop-up dismissal
        if let popupView = sender.superview?.superview {
            UIView.animate(withDuration: 0.3, animations: {
                popupView.alpha = 0
                popupView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { _ in
                popupView.removeFromSuperview()
            })
        }
    }
}
