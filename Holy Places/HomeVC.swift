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
        // Button to share Holy Places app
        let textToShare = "Holy Places of the Lord - Temples and Historic Sites by Derek Cordon"
        
        if let myWebsite = NSURL(string: "https://apps.apple.com/us/app/holy-places-of-the-lord/id1200184537") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    
    //MARK: - Standard Methods
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        goalTitle.text = "\(currentYear) Goal Progress"
        // Adjust spacing of letters of Goal Progress
        let attributedString = NSMutableAttributedString(string: goalTitle.text!)
        attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(3.0), range: NSRange(location: 0, length: attributedString.length))
        goalTitle.attributedText = attributedString
        
        if annualVisitGoal == 0 {
            // goal.text = "SET GOAL"
            // Update value for Today Widget
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue("SET GOAL IN APP", forKey: "goalProgress")
        }
        
       
        // Check for update
        if checkedForUpdate?.daysBetweenDate(toDate: Date()) ?? 1 > 0 {
            ad.refreshTemples()
        }
        
        ad.getVisits()
        goal.text = goalProgress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set size of achievement button
        if UIDevice.current.userInterfaceIdiom == .pad {
            achievementButtonWidth.constant = 100
        } else {
            let size = view.frame.width * 0.20
            achievementButtonWidth.constant = size
        }
        
        // round corners of view
        achievementBtnView.layer.cornerRadius = 10

        // Set image of button to latest achievement
        if completed.count > 0 {
            if let iconImage = UIImage(named: completed[0].iconName) {
                // image exists
                achievementBtn.setImage(iconImage, for: .normal)
            } else {
                achievementBtn.setImage(UIImage(named: "ach12MT"), for: .normal)
            }
            
            achievementBtnView.isHidden = false
        } else {
            achievementBtnView.isHidden = true
        }

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
            // Set background image to Provo City Center temple
            backgroundImage.image = UIImage(imageLiteralResourceName: defaultImageName)
            visitDate.isHidden = true
        } else {
            if homeVisitPicture {
                if let imageData = homeVisitPictureData {
                    backgroundImage.image = UIImage(data: imageData)
                    visitDate.text = homeVisitDate
                    visitDate.isHidden = false
                }
            } else {
                if let imageData = homeAlternatePicture {
                    backgroundImage.image = UIImage(data: imageData)
                    visitDate.isHidden = true
                }
            }
        }
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

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let interfaceOrientation = windowScene.interfaceOrientation
            let isLandscape = interfaceOrientation.isLandscape
            
            if isLandscape {
                setImage(landscape: true)
            } else {
                setImage(landscape: false)
            }
        }

       /* if UIApplication.shared.statusBarOrientation.isLandscape && !UIApplication.shared.isSplitOrSlideOver {
            setImage(landscape: true)
        } else {
            setImage(landscape: false)
        }
        */
        // Lock Orientation to Portrait only for small devices
//        let width = UIScreen.main.bounds.width
//        print("screen width is \(width)")
//        if width < 400 {
        if UIDevice.current.userInterfaceIdiom != .pad {
            AppUtility.lockOrientation(.portrait)
        }
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

    //MARK: - In-App Purchases
//    var productRequest: SKProductsRequest!
//    
//    // Fetch information about your products from the App Store.
//    func fetchProducts(matchingIdentifiers identifiers: [String]) {
//        // Create a set for your product identifiers.
//        let productIdentifiers = Set(identifiers)
//        // Initialize the product request with the above set.
//        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
//        productRequest.delegate = self
//        
//        // Send the request to the App Store.
//        productRequest.start()
//    }
//    
//    // Get the App Store's response
//    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
//        // Parse products retrieved from StoreKit
//        if response.products.count > 0 {
//            // Use availableProducts to populate UI.
//            let availableProducts = response.products
//            
//            // format price for local currency
//            let formatter = NumberFormatter()
//            formatter.numberStyle = .currency
//            formatter.locale = availableProducts[0].priceLocale
//            
//            greatTip = availableProducts[0].localizedTitle + "\n" + formatter.string(from: availableProducts[0].price)!
//            greatTipPC = availableProducts[0]
//            greaterTip = availableProducts[1].localizedTitle + "\n" + formatter.string(from: availableProducts[1].price)!
//            greaterTipPC = availableProducts[1]
//            greatestTip = availableProducts[2].localizedTitle + "\n" + formatter.string(from: availableProducts[2].price)!
//            greatestTipPC = availableProducts[2]
//        }
//    }

}
