//
//  WebsiteVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/28/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class WebsiteVC: UIViewController, UIWebViewDelegate {

    var urlPlace: String?
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        if self.webView != nil {
            if let url = URL(string: urlPlace!) {
                let request = URLRequest(url: url)
                webView.loadRequest(request)
            }
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
