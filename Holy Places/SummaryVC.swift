//
//  SummaryVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/23/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import StoreKit

class SummaryVC: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var quote: UILabel!
    @IBOutlet weak var templesVisited: UILabel!
    @IBOutlet weak var templesTotal: UILabel!
    @IBOutlet weak var historicalVisited: UILabel!
    @IBOutlet weak var historicalTotal: UILabel!
    @IBOutlet weak var visitorsCentersVisited: UILabel!
    @IBOutlet weak var visitorsCentersTotal: UILabel!
    @IBOutlet weak var sealingsPerformedYr: UILabel!
    @IBOutlet weak var sealingsPerformedTotal: UILabel!
    @IBOutlet weak var endowmentsPerformedYr: UILabel!
    @IBOutlet weak var endowmentsPerformedTotal: UILabel!
    @IBOutlet weak var initiatoriesPerformedYr: UILabel!
    @IBOutlet weak var initiatoriesPerformedTotal: UILabel!
    @IBOutlet weak var confirmationsPerformedYr: UILabel!
    @IBOutlet weak var confirmationsPerformedTotal: UILabel!
    @IBOutlet weak var baptismsPerformedYr: UILabel!
    @IBOutlet weak var baptismsPerformedTotal: UILabel!
    @IBOutlet weak var attendedTempleTotal: UILabel!
    @IBOutlet weak var attendedTempleYr: UILabel!
    @IBOutlet weak var ordinancesPerformedYr: UILabel!
    @IBOutlet weak var ordinancesPerformedTotal: UILabel!
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        templesTotal.text = activeTemples.count.description
        historicalTotal.text = historical.count.description
        visitorsCentersTotal.text = visitors.count.description
        //summary.backgroundColor = UIColor.ocean()
        //summary.textColor = UIColor.white

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        quote.text = "\"The all-important and crowning blessings of membership in the Church are those blessings which we receive in the temples of God.\" \n- Thomas S. Monson"
        getTotals()
    }

    func getTotals () {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        var visitCnt = 0
        do {
            // get temple visits
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            var searchResults = try getContext().fetch(fetchRequest)
            
            // count ordinances for each temple visited
            
            var attended = 0
            var sealings = 0
            var endowments = 0
            var initiatories = 0
            var confirmations = 0
            var baptisms = 0
            var ordinances = 0
            
            var attendedTotal = 0
            var sealingsTotal = 0
            var endowmentsTotal = 0
            var initiatoriesTotal = 0
            var confirmationsTotal = 0
            var baptismsTotal = 0
            var ordinancesTotal = 0
            
            for temple in searchResults as [Visit] {
                //print((temple.value(forKey: "dateVisited") as! Date).daysBetweenDate(toDate: Date()))
                // check for ordinaces performed in the last year
                if (temple.value(forKey: "dateVisited") as! Date).daysBetweenDate(toDate: Date()) < 366 {
                    attended += 1
                    sealings += Int(temple.sealings)
                    endowments += Int(temple.endowments)
                    initiatories += Int(temple.initiatories)
                    confirmations += Int(temple.confirmations)
                    baptisms += Int(temple.baptisms)
                }
                // add to total counts
                attendedTotal += 1
                sealingsTotal += temple.value(forKey: "sealings") as! Int
                endowmentsTotal += temple.value(forKey: "endowments") as! Int
                initiatoriesTotal += temple.value(forKey: "initiatories") as! Int
                confirmationsTotal += temple.value(forKey: "confirmations") as! Int
                baptismsTotal += temple.value(forKey: "baptisms") as! Int
            }
            
            ordinances = sealings + endowments + initiatories + confirmations + baptisms
            ordinancesTotal = sealingsTotal + endowmentsTotal + initiatoriesTotal + confirmationsTotal + baptismsTotal
            
            // populate labels on view
            attendedTempleYr.text = attended.description
            attendedTempleTotal.text = attendedTotal.description
            sealingsPerformedTotal.text = sealingsTotal.description
            sealingsPerformedYr.text = sealings.description
            endowmentsPerformedTotal.text = endowmentsTotal.description
            endowmentsPerformedYr.text = endowments.description
            initiatoriesPerformedTotal.text = initiatoriesTotal.description
            initiatoriesPerformedYr.text = initiatories.description
            confirmationsPerformedTotal.text = confirmationsTotal.description
            confirmationsPerformedYr.text = confirmations.description
            baptismsPerformedTotal.text = baptismsTotal.description
            baptismsPerformedYr.text = baptisms.description
            ordinancesPerformedYr.text = ordinances.description
            ordinancesPerformedTotal.text = ordinancesTotal.description
            
            // get number of Temples visited
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            searchResults = try getContext().fetch(fetchRequest)
            var distinct = NSSet(array: searchResults.map { $0.holyPlace! })
            templesVisited.text = distinct.count.description
            visitCnt = searchResults.count

            // get number of Historical sites visited
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
            searchResults = try getContext().fetch(fetchRequest)
            distinct = NSSet(array: searchResults.map { $0.holyPlace! })
            historicalVisited.text = distinct.count.description
            visitCnt += searchResults.count
            
            // get number of Visitors' Centers visited
            fetchRequest.predicate = NSPredicate(format: "type == %@", "V")
            searchResults = try getContext().fetch(fetchRequest)
            distinct = NSSet(array: searchResults.map { $0.holyPlace! })
            visitorsCentersVisited.text = distinct.count.description
            visitCnt += searchResults.count

            // If entered a couple of visits, prompt for a rating
            if visitCnt > 1 {
                if #available(iOS 10.3, *) {
                    SKStoreReviewController.requestReview()
                }
            }
          
        } catch {
            print("Error with request: \(error)")
        }
    }

}
