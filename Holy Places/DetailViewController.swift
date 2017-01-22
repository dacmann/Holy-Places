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
    @IBOutlet weak var templeImage: UIImageView!
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var phoneNumber: UITextView!

    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                //let templeURL: String = detail.templeName.folding(options: .diacriticInsensitive, locale: .current)
                //print(detail.templePictureURL)
                templeSnippet.text = detail.templeSnippet
                templeImage.downloadedFrom(link: detail.templePictureURL)
                address.text = detail.templeAddress + "\n" + detail.templeCityState + "\n" + detail.templeCountry
                phoneNumber.text = detail.templePhone
            }
        }
    }
    
    @IBAction func webSite(_ sender: UIButton) {
        if let url = URL(string: (self.detailItem?.templeSiteURL)!) {
            UIApplication.shared.open(url, options: [:]) {
                boolean in
                // do something with the boolean
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "recordVisit" {
            let temple = self.detailItem
            let controller = (segue.destination as! VisitDetailVC)
            controller.detailItem = temple
        }
    }

}
