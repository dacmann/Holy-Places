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
    var placeType = String()
    
    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var visitDate: UIButton!
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var comments: UILabel!
    
    //MARK:- CoreData functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    func setDate() {
        //dateOfVisit = sender.date
        if let button = self.visitDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM dd YYYY"
            let visitDateAtt = NSAttributedString(string: formatter.string(from: dateOfVisit!))
            button.setAttributedTitle(visitDateAtt, for: .normal)
        }
    }
    
    func editVisit (_ sender: Any) {
        
        let visit = self.detailVisit
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "RecordVisitVC") as! RecordVisitVC
        controller.detailVisit = visit
        controller.navigationItem.leftItemsSupplementBackButton = true
        navigationController?.pushViewController(controller, animated: true)
//        self.present(controller, animated: true, completion: nil)
        
//        templeView.isHidden = false
//        sealingsStepO.isHidden = false
//        sealingsStepO.value = Double(sealings.text!)!
//        endowmentsStepO.isHidden = false
//        endowmentsStepO.value = Double(endowments.text!)!
//        initiatoriesStepO.isHidden = false
//        initiatoriesStepO.value = Double(initiatories.text!)!
//        confirmationsStepO.isHidden = false
//        confirmationsStepO.value = Double(confirmations.text!)!
//        baptismsStepO.isHidden = false
//        baptismsStepO.value = Double(baptisms.text!)!
//        comments.text = detailVisit?.comments
//        comments.isEditable = true
//        visitDate.isEnabled = true
//        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveEdit(_:)))
//        self.navigationItem.rightBarButtonItem = saveButton
//        keyboardDone()
    }
    
    
    //MARK:- Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        populateView()
        setDate()
    }

    
    func doneButtonAction(){
        self.view.endEditing(true)
    }


    
    // function for read-only view of recorded visit
    func populateView() {
        // Update the user interface for the detail item.
        if let detail = self.detailVisit {
            if let label = self.templeName {
                label.text = detail.holyPlace
                dateOfVisit = detail.dateVisited as Date?
                visitDate.isEnabled = false
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
