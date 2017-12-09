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
class HomeVC: UIViewController, XMLParserDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: - Outlets & Actions
    @IBOutlet weak var info: UIButton!
    @IBOutlet weak var goal: UIButton!
    @IBOutlet weak var goalTitle: UILabel!
    @IBOutlet weak var settings: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var holyPlaces: UILabel!
    @IBOutlet weak var reference: UILabel!
    @IBOutlet weak var topLine: UIView!
    @IBOutlet weak var bottomLine: UIView!
    @IBOutlet weak var share: UIButton!
    @IBOutlet weak var visitDate: UILabel!
    
    @IBAction func shareHolyPlaces(_ sender: UIButton) {
        // Button to share Holy Places app
        let textToShare = "Holy Places - LDS Temples and Historic Sites by Derek Cordon"
        
        if let myWebsite = NSURL(string: "https://itunes.apple.com/us/app/holy-places-lds-temples-historic/id1200184537?mt=8") {
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
        
        settings.setTitle("\u{2699}\u{0000FE0E}", for: .normal)
        
                
    }
    
    override func viewWillAppear(_ animated: Bool) {
        goalTitle.text = "\(currentYear) Goal Progress"
        // Adjust spacing of letters of Goal Progress
        let attributedString = NSMutableAttributedString(string: goalTitle.text!)
        attributedString.addAttribute(NSAttributedStringKey.kern, value: CGFloat(3.0), range: NSRange(location: 0, length: attributedString.length))
        goalTitle.attributedText = attributedString
        
        if annualVisitGoal == 0 {
            goal.setTitle("SET GOAL", for: .normal)
            UserDefaults.init(suiteName: "group.net.dacworld.holyplaces")?.setValue("SET GOAL IN APP", forKey: "goalProgress")
        } else {
            appDelegate.getVisits()
            goal.setTitle(goalProgress, for: .normal)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Determine if check hasn't occurred today
//        print(checkedForUpdate?.daysBetweenDate(toDate: Date()) as Any)
        if (checkedForUpdate?.daysBetweenDate(toDate: Date()))! > 0 {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.refreshTemples()
        }
        
        // Check for update and pop message
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
            let alert = UIAlertController(title: changesDate + " Update", message: changesMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            // clear out message now that it has been presented
            changesDate = ""
        }
        
        // Home Screen Customizations
        holyPlaces.textColor = UIColor.home()
//        holyPlaces.shadowColor = .gray
        reference.textColor = UIColor.home()
//        reference.shadowColor = .gray
        goalTitle.textColor = UIColor.home()
//        goalTitle.shadowColor = .gray
//        
        info.tintColor = UIColor.home()
////        info.layer.shadowColor = UIColor.gray.cgColor
////        info.layer.shadowRadius = 5
////        info.layer.shadowOpacity = 1.0
//        
        topLine.backgroundColor = UIColor.home()
        bottomLine.backgroundColor = UIColor.home()
        share.titleLabel?.textColor = UIColor.home()
        goal.titleLabel?.textColor = UIColor.home()
        settings.titleLabel?.textColor = UIColor.home()
        visitDate.textColor = UIColor.home()

        if homeDefaultPicture {
            // Set background image to Provo City Center temple
            if self.traitCollection.horizontalSizeClass == .regular {
                backgroundImage.image = UIImage(imageLiteralResourceName: "PCCW")
            } else {
                backgroundImage.image = UIImage(imageLiteralResourceName: "PCC")
            }
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if homeTextColor == 0 {
            return .lightContent
        } else {
            return .default
        }
        
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
