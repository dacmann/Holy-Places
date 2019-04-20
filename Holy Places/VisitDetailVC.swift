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
                var sealings = ""
                var endowments = ""
                var initiatories = ""
                var confirmations = ""
                var baptisms = ""
                var shiftHrs = ""
                if detail.type == "T" {
                    if detail.sealings > 0 {
                        sealings = "\nSealings: \(detail.sealings.description)"
                        ordinances.append(sealings)
                    }
                    if detail.endowments > 0 {
                        endowments = "\nEndowments: \(detail.endowments.description)"
                        ordinances.append(endowments)
                    }
                    if detail.initiatories > 0 {
                        initiatories = "\nInitiatories: \(detail.initiatories.description)"
                        ordinances.append(initiatories)
                    }
                    if detail.confirmations > 0 {
                        confirmations = "\nConfirmations: \(detail.confirmations.description)"
                        ordinances.append(confirmations)
                    }
                    if detail.baptisms > 0 {
                        baptisms = "\nBaptisms: \(detail.baptisms.description)"
                        ordinances.append(baptisms)
                    }
                    if detail.shiftHrs > 0 {
                        shiftHrs = "\nHours Worked: \(detail.shiftHrs.description)"
                        ordinances.append(shiftHrs)
                    }
                }
                if ordinances != "" {
                    ordinancesPerformed.isHidden = false
                } else {
                    ordinancesPerformed.isHidden = true
                }
                // color code the ordinance recorded
                let attributedText = NSMutableAttributedString(string: ordinances)
                if detail.sealings > 0 {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.eggplant()], range: getRangeOfSubString(subString: sealings, fromString: ordinances))
                }
                if detail.endowments > 0 {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.darkTangerine()], range: getRangeOfSubString(subString: endowments, fromString: ordinances))
                }
                if detail.initiatories > 0 {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.olive()], range: getRangeOfSubString(subString: initiatories, fromString: ordinances))
                }
                if detail.confirmations > 0 {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.flame()], range: getRangeOfSubString(subString: confirmations, fromString: ordinances))
                }
                if detail.baptisms > 0 {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ocean()], range: getRangeOfSubString(subString: baptisms, fromString: ordinances))
                }
                if detail.shiftHrs > 0 {
                    attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.iron()], range: getRangeOfSubString(subString: shiftHrs, fromString: ordinances))
                }
//                ordinancesPerformed.text = ordinances
                ordinancesPerformed.attributedText = attributedText
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
    
    func getRangeOfSubString(subString: String, fromString: String) -> NSRange {
        let sampleLinkRange = fromString.range(of: subString)!
        let startPos = fromString.distance(from: fromString.startIndex, to: sampleLinkRange.lowerBound)
        let endPos = fromString.distance(from: fromString.startIndex, to: sampleLinkRange.upperBound)
        let linkRange = NSMakeRange(startPos, endPos - startPos)
        return linkRange
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
