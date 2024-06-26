//
//  InfoVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/26/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import MessageUI
import SafariServices
//import StoreKit

class InfoVC: UIViewController, MFMailComposeViewControllerDelegate {

    var alertController: UIAlertController?
    @IBOutlet weak var profile_picture: UIImageView!
    @IBOutlet weak var sticker_sheet: UIImageView!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var logo: UIImageView!
//    @IBOutlet weak var greatTipBtn: CustomButton!
//    @IBOutlet weak var greaterTipBtn: CustomButton!
//    @IBOutlet weak var greatestTipBtn: CustomButton!
    @IBOutlet weak var logoWidth: NSLayoutConstraint!
    @IBOutlet weak var greetings: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SKPaymentQueue.default().add(self)
        
        version.text = "Version: " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String?)! + " | " + placeDataVersion!

        // Do any additional setup after loading the view.
//        greatTipBtn.setTitle(greatTip, for: .normal)
//        greaterTipBtn.setTitle(greaterTip, for: .normal)
//        greatestTipBtn.setTitle(greatestTip, for: .normal)
        
        self.view.layoutIfNeeded()
        profile_picture.layer.cornerRadius = profile_picture.frame.size.width / 10
        profile_picture.layer.masksToBounds = true
        sticker_sheet.layer.cornerRadius = sticker_sheet.frame.size.width / 10
        sticker_sheet.layer.masksToBounds = true

    }

    override func viewDidLayoutSubviews() {
        let screenSize: CGRect = UIScreen.main.bounds
        print(screenSize.height)
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight :
            //logoWidth.constant = greetings.frame.width / 2
            logo.isHidden = true
            profile_picture.isHidden = true
        default :
            logoWidth.constant = greetings.frame.width / 2
            profile_picture.isHidden = false
            if screenSize.height < 800 {
                logo.isHidden = true
                greetings.text = "Greetings! I hope this App assists and motivates all who use it to frequently visit these Holy Places."
            }
        }
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        switch toInterfaceOrientation {
        case .landscapeLeft, .landscapeRight :
            //logoWidth.constant = greetings.frame.width / 2
            logo.isHidden = true
            profile_picture.isHidden = true
        case .portrait, .portraitUpsideDown, .unknown :
            logoWidth.constant = greetings.frame.width / 2
            logo.isHidden = false
            profile_picture.isHidden = false
        @unknown default:
            print("Not handled")
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneBtn(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func contactMe(_ sender: UIButton) {
        sendEmail()
    }
//    @IBAction func tipGreat(_ sender: UIButton) {
//        let payment = SKPayment.init(product: greatTipPC)
//        SKPaymentQueue.default().add(payment)
//    }
//    @IBAction func tipGreater(_ sender: UIButton) {
//        let payment = SKPayment.init(product: greaterTipPC)
//        SKPaymentQueue.default().add(payment)
//    }
//    @IBAction func tipGreatest(_ sender: UIButton) {
//        let payment = SKPayment.init(product: greatestTipPC)
//        SKPaymentQueue.default().add(payment)
//    }

    func sendEmail() {
        // determine device
        let identifier = UIDevice.current.modelName
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["dacmann@icloud.com"])
            mail.setSubject("Holy Places App Feedback")
            mail.setMessageBody("<br><br><br><p>----------------------</p><p>Device: \(identifier) </p><p> " + (version.text)! + " </p><p>----------------------</p>", isHTML: true)
            
            present(mail, animated: true, completion: nil)
        } else {
            // If the default Mail app isn't configured, provide an alternative action
            if let url = URL(string: "mailto:dacmann@icloud.com?subject=Holy%20Places%20App%20Feedback") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func quizGameLink(_ sender: UIButton) {
        if let appStoreURL = URL(string: "https://apps.apple.com/app/id1294022470") {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func fairMormonLink(_ sender: UIButton) {
        if let url = URL(string: "http://oneclimbs.com/2011/11/21/restoring-the-pentagram-to-its-proper-place/") {
//            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        }
    }
    
    @IBAction func faqLink(_ sender: UIButton) {
        if let url = URL(string: "https://dacworld.net/holyplaces/holyplacesfaq.html") {
//            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
        }
    }
    
}
