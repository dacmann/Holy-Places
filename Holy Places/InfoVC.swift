//
//  InfoVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/26/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit

class InfoVC: UIViewController, MFMailComposeViewControllerDelegate {

    var alertController: UIAlertController?
    @IBOutlet weak var profile_picture: UIImageView!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var greatTipBtn: CustomButton!
    @IBOutlet weak var greaterTipBtn: CustomButton!
    @IBOutlet weak var greatestTipBtn: CustomButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SKPaymentQueue.default().add(self)
        
        version.text = "Version: " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String?)! + " | " + placeDataVersion
        
        //profile_picture.layer.cornerRadius = profile_picture.frame.size.width / 2
        profile_picture.layer.cornerRadius = 10.0
        profile_picture.clipsToBounds = true
        profile_picture.layer.borderWidth = 3
        profile_picture.layer.borderColor = UIColor.white.cgColor

        // Do any additional setup after loading the view.
        greatTipBtn.setTitle(greatTip, for: .normal)
        greaterTipBtn.setTitle(greaterTip, for: .normal)
        greatestTipBtn.setTitle(greatestTip, for: .normal)

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
    @IBAction func tipGreat(_ sender: UIButton) {
        let payment = SKPayment.init(product: greatTipPC)
        SKPaymentQueue.default().add(payment)
    }
    @IBAction func tipGreater(_ sender: UIButton) {
        let payment = SKPayment.init(product: greaterTipPC)
        SKPaymentQueue.default().add(payment)
    }
    @IBAction func tipGreatest(_ sender: UIButton) {
        let payment = SKPayment.init(product: greatestTipPC)
        SKPaymentQueue.default().add(payment)
    }

    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            
            mail.mailComposeDelegate = self
            
            // determine device
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            mail.setToRecipients(["dacmann@icloud.com"])
            mail.setSubject("Holy Places App Feedback")
            mail.setMessageBody("<br><br><br><p>----------------------</p><p>Device: " + (identifier) + "</p><p>" + (version.text)! + "</p><p>----------------------</p>", isHTML: true)
            
            present(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//        
//        for transaction in transactions {
//            switch transaction.transactionState {
//            case .purchased:
//                // thanks for the purchase
//                SKPaymentQueue.default().finishTransaction(transaction)
//                self.alertController = UIAlertController(title: "Thanks for tip", message: "I really appreciate your support.", preferredStyle: .alert)
//                break
//            case .failed:
//                SKPaymentQueue.default().finishTransaction(transaction)
//                break
//            default:
//                break
//            }
//        }
//        
//    }
    

    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
}
