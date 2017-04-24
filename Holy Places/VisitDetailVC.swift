//
//  VisitDetailVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/13/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

class VisitDetailVC: UIViewController {
    
    //MARK:- Variables & Outlets
    var dateOfVisit: Date?
    
    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var visitDate: UILabel!
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var comments: UILabel!
    
    //MARK:- CoreData functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    func setDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd YYYY"
        visitDate.text = formatter.string(from: dateOfVisit!)
    }
    
    func editVisit (_ sender: Any) {
        
        let visit = self.detailVisit
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "RecordVisitVC") as! RecordVisitVC
        controller.detailVisit = visit
        controller.navigationItem.leftItemsSupplementBackButton = true
        navigationController?.pushViewController(controller, animated: true)

    }
    
    
    //MARK:- Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        populateView()
        setDate()
    }

    // function for read-only view of recorded visit
    func populateView() {
        // Update the user interface for the detail item.
        if let detail = self.detailVisit {
            if let label = self.templeName {
                label.text = detail.holyPlace
                dateOfVisit = detail.dateVisited as Date?
                var ordinances = "\n"
                if detail.type == "T" {
                    if detail.sealings > 0 {
                        ordinances.append("\nSealings: \(detail.sealings.description)")
                    }
                    if detail.endowments > 0 {
                        ordinances.append("\nEndowments: \(detail.endowments.description)")
                    }
                    if detail.initiatories > 0 {
                        ordinances.append("\nInitiatories: \(detail.initiatories.description)")
                    }
                    if detail.confirmations > 0 {
                        ordinances.append("\nConfirmations: \(detail.confirmations.description)")
                    }
                    if detail.baptisms > 0 {
                        ordinances.append("\nBaptisms: \(detail.baptisms.description)")
                    }
                }
                if ordinances != "\n" {
                    comments.text = detail.comments! + ordinances
                } else {
                    comments.text = detail.comments
                }
                
                comments.sizeToFit()
                // load image
                if let imageData = detail.picture {
                    let image = UIImage(data: imageData as Data)
                    pictureView.image = image
                    pictureView.isHidden = false
                } else {
                    pictureView.isHidden = true
                }
                
            }
        }
    }
    
    var detailVisit: Visit? {
        didSet {
            // populate the view
            self.populateView()
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editVisit(_:)))
            self.navigationItem.rightBarButtonItem = editButton
        }
    }

        // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation

    

}
