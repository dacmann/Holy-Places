//
//  InfoVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/26/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import MessageUI

class InfoVC: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var profile_picture: UIImageView!
    @IBOutlet weak var version: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        version.text = "Version: " + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String?)! + " | " + placeDataVersion
        
        profile_picture.layer.cornerRadius = profile_picture.frame.size.width / 2
        profile_picture.clipsToBounds = true
        profile_picture.layer.borderWidth = 3
        profile_picture.layer.borderColor = UIColor.white.cgColor

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func contactMe(_ sender: UIButton) {
        sendEmail()
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
}
