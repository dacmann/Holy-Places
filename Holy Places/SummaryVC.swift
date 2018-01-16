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
    
    @IBOutlet weak var titleYr1: UILabel!
    @IBOutlet weak var attendedTempleYr: UILabel!
    @IBOutlet weak var sealingsPerformedYr: UILabel!
    @IBOutlet weak var endowmentsPerformedYr: UILabel!
    @IBOutlet weak var initiatoriesPerformedYr: UILabel!
    @IBOutlet weak var confirmationsPerformedYr: UILabel!
    @IBOutlet weak var baptismsPerformedYr: UILabel!
    @IBOutlet weak var ordinancesPerformedYr: UILabel!
    
    @IBOutlet weak var titleYr2: UILabel!
    @IBOutlet weak var attendedTempleYr2: UILabel!
    @IBOutlet weak var sealingsPerformedYr2: UILabel!
    @IBOutlet weak var endowmentsPerformedYr2: UILabel!
    @IBOutlet weak var initiatoriesPerformedYr2: UILabel!
    @IBOutlet weak var confirmationsPerformedYr2: UILabel!
    @IBOutlet weak var baptismsPerformedYr2: UILabel!
    @IBOutlet weak var ordinancesPerformedYr2: UILabel!

    @IBOutlet weak var sealingsPerformedTotal: UILabel!
    @IBOutlet weak var attendedTempleTotal: UILabel!
    @IBOutlet weak var endowmentsPerformedTotal: UILabel!
    @IBOutlet weak var initiatoriesPerformedTotal: UILabel!
    @IBOutlet weak var confirmationsPerformedTotal: UILabel!
    @IBOutlet weak var baptismsPerformedTotal: UILabel!
    @IBOutlet weak var ordinancesPerformedTotal: UILabel!
    
    @IBOutlet weak var mostVisitedPlace1: UILabel!
    @IBOutlet weak var mostVisitedPlace2: UILabel!
    @IBOutlet weak var mostVisitedPlace3: UILabel!
    @IBOutlet weak var mostVisitedCount1: UILabel!
    @IBOutlet weak var mostVisitedCount2: UILabel!
    @IBOutlet weak var mostVisitedCount3: UILabel!
    
    
    var yearOffset = 0
    
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
            var attendedTotal = 0
            var sealingsTotal = 0
            var endowmentsTotal = 0
            var initiatoriesTotal = 0
            var confirmationsTotal = 0
            var baptismsTotal = 0
            var ordinancesTotal = 0
            
            for temple in searchResults as [Visit] {
                // add to total counts
                attendedTotal += 1
                sealingsTotal += temple.value(forKey: "sealings") as! Int
                endowmentsTotal += temple.value(forKey: "endowments") as! Int
                initiatoriesTotal += temple.value(forKey: "initiatories") as! Int
                confirmationsTotal += temple.value(forKey: "confirmations") as! Int
                baptismsTotal += temple.value(forKey: "baptisms") as! Int
            }
            
            getYearTotals(visits: searchResults)
            
            ordinancesTotal = sealingsTotal + endowmentsTotal + initiatoriesTotal + confirmationsTotal + baptismsTotal
            
            // populate Total labels on view
            attendedTempleTotal.text = attendedTotal.description
            sealingsPerformedTotal.text = sealingsTotal.description
            endowmentsPerformedTotal.text = endowmentsTotal.description
            initiatoriesPerformedTotal.text = initiatoriesTotal.description
            confirmationsPerformedTotal.text = confirmationsTotal.description
            baptismsPerformedTotal.text = baptismsTotal.description
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
            
            // Deteremine most visited places
            let fetchRequest2 = NSFetchRequest<NSDictionary>(entityName:"Visit")
            fetchRequest2.predicate = nil
            let nameExpr = NSExpression(forKeyPath: "holyPlace")
            let countExpr = NSExpressionDescription()
            
            countExpr.name = "count"
            countExpr.expression = NSExpression(forFunction: "count:", arguments: [ nameExpr ])
            countExpr.expressionResultType = .integer64AttributeType
            
            fetchRequest2.resultType = .dictionaryResultType
            fetchRequest2.sortDescriptors = [ NSSortDescriptor(key: "holyPlace", ascending: true) ]
            fetchRequest2.propertiesToGroupBy = ["holyPlace"]
            fetchRequest2.propertiesToFetch = [ "holyPlace", countExpr ]
            
            let searchResults2 = try getContext().fetch(fetchRequest2)
            let itemResult = searchResults2.sorted { $0.value(forKey: "count") as! Int > $1.value(forKey: "count") as! Int }
            
            var counter = 0
            for place in itemResult {
                let placeName = place.object(forKey: "holyPlace") as! String
                let placeCount = String(format: "%@", place.object(forKey: "count") as! CVarArg)
                
                counter += 1
                switch counter {
                case 1:
                    mostVisitedPlace1.text = placeName
                    mostVisitedCount1.text = placeCount
                case 2:
                    mostVisitedPlace2.text = placeName
                    mostVisitedCount2.text = placeCount
                case 3:
                    mostVisitedPlace3.text = placeName
                    mostVisitedCount3.text = placeCount
                default:
                    break
                }
                print("\(placeName) - \(placeCount)")
                if counter == 3 {
                    break
                }
            }

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
    
    func getYearTotals(visits: [Visit]) {
        
        var sealings = 0
        var endowments = 0
        var initiatories = 0
        var confirmations = 0
        var baptisms = 0
        var ordinances = 0
        var attended = 0
        var sealings2 = 0
        var endowments2 = 0
        var initiatories2 = 0
        var confirmations2 = 0
        var baptisms2 = 0
        var ordinances2 = 0
        var attended2 = 0
        
        let year1 = String(Int(currentYear)! + yearOffset)
        let year2 = String(Int(currentYear)! + yearOffset - 1)
        titleYr1.text = year1
        titleYr2.text = year2
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        
        for temple in visits {
            // check for ordinances performed in 2 specific years based on offset
            let yearVisited = formatter.string(from: temple.dateVisited!)
            if (yearVisited == year1) {
                attended += 1
                sealings += Int(temple.sealings)
                endowments += Int(temple.endowments)
                initiatories += Int(temple.initiatories)
                confirmations += Int(temple.confirmations)
                baptisms += Int(temple.baptisms)
            }
            if (yearVisited == year2) {
                attended2 += 1
                sealings2 += Int(temple.sealings)
                endowments2 += Int(temple.endowments)
                initiatories2 += Int(temple.initiatories)
                confirmations2 += Int(temple.confirmations)
                baptisms2 += Int(temple.baptisms)
            }
        }
        
        ordinances = sealings + endowments + initiatories + confirmations + baptisms
        
        attendedTempleYr.text = attended.description
        sealingsPerformedYr.text = sealings.description
        endowmentsPerformedYr.text = endowments.description
        initiatoriesPerformedYr.text = initiatories.description
        confirmationsPerformedYr.text = confirmations.description
        baptismsPerformedYr.text = baptisms.description
        ordinancesPerformedYr.text = ordinances.description
        
        ordinances2 = sealings2 + endowments2 + initiatories2 + confirmations2 + baptisms2
        
        attendedTempleYr2.text = attended2.description
        sealingsPerformedYr2.text = sealings2.description
        endowmentsPerformedYr2.text = endowments2.description
        initiatoriesPerformedYr2.text = initiatories2.description
        confirmationsPerformedYr2.text = confirmations2.description
        baptismsPerformedYr2.text = baptisms2.description
        ordinancesPerformedYr2.text = ordinances2.description

    }

}
