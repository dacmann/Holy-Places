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
    @IBOutlet weak var ordinancesPerformed: UILabel!
    
    //MARK:- CoreData functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    func setDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd YYYY"
        visitDate.text = formatter.string(from: dateOfVisit!)
        visitDate.textColor = UIColor.lead()
    }
    
    @objc func editVisit (_ sender: Any) {
        
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(VisitDetailVC.imageClicked))
        pictureView.addGestureRecognizer(tap)
        pictureView.isUserInteractionEnabled = true
        
        // Change the back button on the Edit Visit VC to Cancel
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
        
        // Add swipe gestures to navigate to other visits
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)

    }

    override func viewWillAppear(_ animated: Bool) {
        populateView()
        setDate()
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == UISwipeGestureRecognizer.Direction.up {
//            print("Swipe Up")
            if selectedVisitRow < visitsInTable.count - 1 {
                selectedVisitRow += 1
                detailVisit = visitsInTable[selectedVisitRow]
                setDate()
            }
        }
        else if gesture.direction == UISwipeGestureRecognizer.Direction.down {
//            print("Swipe Down")
            if selectedVisitRow > 0 {
                selectedVisitRow -= 1
                detailVisit = visitsInTable[selectedVisitRow]
                setDate()
            }
        }
    }
    
    @objc func imageClicked()
    {
        print("Tapped on Image")
        // navigate to another
        self.performSegue(withIdentifier: "viewImage", sender: self)
    }
    

    // function for read-only view of recorded visit
    func populateView() {
        // Update the user interface for the detail item.
        if let detail = self.detailVisit {
            if let label = self.templeName {
                label.text = detail.holyPlace
                dateOfVisit = detail.dateVisited as Date?
                var ordinances = ""
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
                    if detail.shiftHrs > 0 {
                        ordinances.append("\nHours Worked: \(detail.shiftHrs.description)")
                    }
                }
                if ordinances != "" {
                    ordinancesPerformed.isHidden = false
                } else {
                    ordinancesPerformed.isHidden = true
                }
                ordinancesPerformed.text = ordinances
                comments.text = detail.comments
                
                if let theType = detail.type {
                    switch theType {
                    case "T":
                        templeName.textColor = UIColor.darkRed()
                    case "H":
                        templeName.textColor = UIColor.darkLimeGreen()
                    case "C":
                        templeName.textColor = UIColor.darkOrange()
                    case "V":
                        templeName.textColor = UIColor.strongYellow()
                    default:
                        templeName.textColor = UIColor.lead()
                    }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage" {
            
            let destViewController: VisitImageVC = segue.destination as! VisitImageVC
            
            destViewController.img = pictureView.image // pass your imageview
        }
    }

    

}
