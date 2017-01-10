//
//  DetailViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/10/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var templeSnippet: UILabel!
    @IBOutlet weak var templeDescription: UIWebView!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                let templeURL: String = detail.templeName.folding(options: .diacriticInsensitive, locale: .current)
                print(templeURL)
                templeDescription.loadHTMLString(detail.templeDescription, baseURL: nil)
                templeSnippet.text = detail.templeSnippet
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var detailItem: Temple? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

}
