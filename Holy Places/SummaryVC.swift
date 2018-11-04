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

class SummaryVC: UIViewController, NSFetchedResultsControllerDelegate, XMLParserDelegate {

    //MARK: - Outlets
    @IBOutlet weak var quote: UILabel!
    @IBOutlet weak var templesVisited: UILabel!
    @IBOutlet weak var templesTotal: UILabel!
    @IBOutlet weak var historicalVisited: UILabel!
    @IBOutlet weak var historicalTotal: UILabel!
    @IBOutlet weak var visitorsCentersVisited: UILabel!
    @IBOutlet weak var visitorsCentersTotal: UILabel!
    @IBOutlet weak var hoursWorked: UILabel!
    
    @IBOutlet weak var titleYr1: UIButton!
    @IBOutlet weak var attendedTempleYr: UILabel!
    @IBOutlet weak var hoursWorkedYr: UILabel!
    @IBOutlet weak var sealingsPerformedYr: UILabel!
    @IBOutlet weak var endowmentsPerformedYr: UILabel!
    @IBOutlet weak var initiatoriesPerformedYr: UILabel!
    @IBOutlet weak var confirmationsPerformedYr: UILabel!
    @IBOutlet weak var baptismsPerformedYr: UILabel!
    @IBOutlet weak var ordinancesPerformedYr: UILabel!
    
    @IBOutlet weak var titleYr2: UIButton!
    @IBOutlet weak var attendedTempleYr2: UILabel!
    @IBOutlet weak var hoursWorkedYr2: UILabel!
    @IBOutlet weak var sealingsPerformedYr2: UILabel!
    @IBOutlet weak var endowmentsPerformedYr2: UILabel!
    @IBOutlet weak var initiatoriesPerformedYr2: UILabel!
    @IBOutlet weak var confirmationsPerformedYr2: UILabel!
    @IBOutlet weak var baptismsPerformedYr2: UILabel!
    @IBOutlet weak var ordinancesPerformedYr2: UILabel!

    @IBOutlet weak var hoursWorkedTotal: UILabel!
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
    @IBOutlet weak var mostVisitedPlace4: UILabel!
    @IBOutlet weak var mostVisitedPlace5: UILabel!
    @IBOutlet weak var mostVisitedPlace6: UILabel!
    @IBOutlet weak var mostVisitedPlace7: UILabel!
    @IBOutlet weak var mostVisitedPlace8: UILabel!
    @IBOutlet weak var mostVisitedPlace9: UILabel!
    @IBOutlet weak var mostVisitedPlace10: UILabel!
    @IBOutlet weak var mostVisitedPlace11: UILabel!
    @IBOutlet weak var mostVisitedPlace12: UILabel!
    
    @IBOutlet weak var mostVisitedCount1: UILabel!
    @IBOutlet weak var mostVisitedCount2: UILabel!
    @IBOutlet weak var mostVisitedCount3: UILabel!
    @IBOutlet weak var mostVisitedCount4: UILabel!
    @IBOutlet weak var mostVisitedCount5: UILabel!
    @IBOutlet weak var mostVisitedCount6: UILabel!
    @IBOutlet weak var mostVisitedCount7: UILabel!
    @IBOutlet weak var mostVisitedCount8: UILabel!
    @IBOutlet weak var mostVisitedCount9: UILabel!
    @IBOutlet weak var mostVisitedCount10: UILabel!
    @IBOutlet weak var mostVisitedCount11: UILabel!
    @IBOutlet weak var mostVisitedCount12: UILabel!
    
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var visitsStackViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainStackView: UIStackView!
    
    //MARK: - Variables
    var yearOffset = 0
    var eName: String = String()
    var summaryQuote: String = String()
    var quoteNum = 0
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    //MARK: - Standard Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        templesTotal.text = activeTemples.count.description
        historicalTotal.text = historical.count.description
        visitorsCentersTotal.text = visitors.count.description

        // Load quotes into array if not done yet
        if summaryQuotes.count == 0 {
            guard let myURL = Bundle.main.url(forResource: "SummaryQuotes", withExtension: "xml") else {
                print("URL not defined properly")
                return
            }
            guard let parser = XMLParser(contentsOf: myURL as URL) else {
                print("Cannot Read Data")
                return
            }
            parser.delegate = self
            if parser.parse() {
                print("Successly parsed")
            } else {
                print("Data parsing aborted")
                let error = parser.parserError!
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parser.lineNumber)")
                summaryQuotes.append("\"The supreme benefits of membership in the Church can only be realized through the exalting ordinances of the temple.\"\r\n~ Russell M. Nelson ~")
            }
        }
        quoteNum = Int(arc4random_uniform(UInt32(summaryQuotes.count)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getTotals()
        // Cycle through the quotes sequentially
        if quoteNum == summaryQuotes.count {
            quoteNum = 0
        }
        quote.text = summaryQuotes[quoteNum]
        quoteNum += 1
    }
    
    override func viewWillLayoutSubviews() {
        if UIApplication.shared.statusBarOrientation.isLandscape && !UIApplication.shared.isSplitOrSlideOver {
            changeConfiguration(landscape: true)
        } else {
            changeConfiguration(landscape: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UIApplication.shared.statusBarOrientation.isLandscape && !UIApplication.shared.isSplitOrSlideOver {
            changeConfiguration(landscape: true)
        } else {
            changeConfiguration(landscape: false)
        }
    }
    
    //MARK: - Layout
    fileprivate func changeConfiguration(landscape: Bool) {
        if landscape {
            if UIDevice.current.userInterfaceIdiom == .pad {
                headerHeightConstraint.constant = 132
            } else {
                headerHeightConstraint.constant = 100
            }
            // Change stack view to horizontal
            mainStackView.axis = .horizontal
            visitsStackViewWidthConstraint = visitsStackViewWidthConstraint.changeMultiplier(multiplier: 0.45)
        } else {
            if self.traitCollection.horizontalSizeClass == .regular {
                headerHeightConstraint.constant = 200
            } else {
                headerHeightConstraint.constant = 132
            }
            // Change stack view to vertical
            mainStackView.axis = .vertical
            if UIDevice.current.userInterfaceIdiom == .pad {
                visitsStackViewWidthConstraint = visitsStackViewWidthConstraint.changeMultiplier(multiplier: 0.9)
            } else {
                visitsStackViewWidthConstraint = visitsStackViewWidthConstraint.changeMultiplier(multiplier: 1.0)
            }
            
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        if fromInterfaceOrientation.isLandscape || UIApplication.shared.isSplitOrSlideOver {
            changeConfiguration(landscape: false)
        } else {
            changeConfiguration(landscape: true)
        }
    }
    
    //MARK: - Button actions
    
    @IBAction func titleYr1Btn(_ sender: UIButton) {
        if yearOffset < 0 {
            yearOffset += 1
            // get temple visits
            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            do {
                let searchResults = try getContext().fetch(fetchRequest)
                getYearTotals(visits: searchResults)
            } catch {
                print("Error with request: \(error)")
            }
        }
    }
    
    @IBAction func titleYr2Btn(_ sender: UIButton) {
        
        yearOffset -= 1
        
        // get temple visits
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
        do {
            let searchResults = try getContext().fetch(fetchRequest)
            getYearTotals(visits: searchResults)
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    //MARK: - Tallying functions
    func getTotals () {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        var visitCnt = 0
        var year = "1830"
        var month = 1
        let yearFormat = DateFormatter()
        yearFormat.dateFormat = "yyyy"
        let monthFormat = DateFormatter()
        monthFormat.dateFormat = "MM"

        initAchievements()
        distinctHistoricSitesVisited.removeAll()
        distinctTemplesVisited.removeAll()
        do {
            // get temple visits
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            let sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            var searchResults = try getContext().fetch(fetchRequest)
            
            // count ordinances for each temple visited
            var attendedTotal = 0
            var sealingsTotal = 0
            var endowmentsTotal = 0
            var initiatoriesTotal = 0
            var confirmationsTotal = 0
            var baptismsTotal = 0
            var ordinancesTotal = 0
            var shiftHoursTotal = 0.0
            var didOrdinances = false
            
            for temple in searchResults as [Visit] {
                // add to total counts
                
                sealingsTotal += Int(temple.sealings)
                endowmentsTotal += Int(temple.endowments)
                initiatoriesTotal += Int(temple.initiatories)
                confirmationsTotal += Int(temple.confirmations)
                baptismsTotal += Int(temple.baptisms)
                shiftHoursTotal += temple.shiftHrs
                
                // Check if ordnances were performed at this visit
                if Int(temple.baptisms) > 0 || Int(temple.confirmations) > 0 || Int(temple.initiatories) > 0 || Int(temple.endowments) > 0 || Int(temple.sealings) > 0 {
                    didOrdinances = true
                } else {
                    didOrdinances = false
                }
                
                if excludeNonOrdinanceVisits {
                    if didOrdinances {
                        attendedTotal += 1
                    }
                } else {
                    attendedTotal += 1
                }
                
                // determine unique temples visited
                if !distinctTemplesVisited.contains(temple.holyPlace!) {
                    distinctTemplesVisited.append(temple.holyPlace!)
                    if distinctTemplesVisited.count == 10 {
                        updateAchievement(achievement:"ach10T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 20 {
                        updateAchievement(achievement:"ach20T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 30 {
                        updateAchievement(achievement:"ach30T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 40 {
                        updateAchievement(achievement:"ach40T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 50 {
                        updateAchievement(achievement:"ach50T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 75 {
                        updateAchievement(achievement:"ach75T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 100 {
                        updateAchievement(achievement:"ach100T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 125 {
                        updateAchievement(achievement:"ach125T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 150 {
                        updateAchievement(achievement:"ach150T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 175 {
                        updateAchievement(achievement:"ach175T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                    if distinctTemplesVisited.count == 200 {
                        updateAchievement(achievement:"ach200T", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                    }
                }
                
                // Check for Ordinance Achievements
                switch baptismsTotal {
                case 25 ... 49:
                    updateAchievement(achievement: "ach25B", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 50 ... 99:
                    updateAchievement(achievement: "ach50B", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100B", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200B", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400B", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 800...:
                    updateAchievement(achievement: "ach800B", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                default:
                    break
                }
                
                switch initiatoriesTotal {
                case 25 ... 49:
                    updateAchievement(achievement: "ach25I", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 50 ... 99:
                    updateAchievement(achievement: "ach50I", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100I", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200I", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400I", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 800... :
                    updateAchievement(achievement: "ach800I", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                default:
                    break
                }

                switch endowmentsTotal {
                case 10 ... 24:
                    updateAchievement(achievement: "ach10E", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 25 ... 49:
                    updateAchievement(achievement: "ach25E", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 50 ... 99:
                    updateAchievement(achievement: "ach50E", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100E", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200E", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 400... :
                    updateAchievement(achievement: "ach400E", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                default:
                    break
                }

                switch sealingsTotal {
                case 50 ... 99:
                    updateAchievement(achievement: "ach50S", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 100 ... 199:
                    updateAchievement(achievement: "ach100S", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 200 ... 399:
                    updateAchievement(achievement: "ach200S", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 400 ... 799:
                    updateAchievement(achievement: "ach400S", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 800 ... 1599:
                    updateAchievement(achievement: "ach800S", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                case 1600... :
                    updateAchievement(achievement: "ach1600S", dateAchieved: temple.dateVisited!, placeAchieved: temple.holyPlace!)
                default:
                    break
                }
                
                //  Check for consecutive month achievements if ordinaces performed
                if didOrdinances {
                    let monthVisited = Int(monthFormat.string(from: temple.dateVisited!))
                    let yearVisited = yearFormat.string(from: temple.dateVisited!)
                    if (monthVisited == 1) {
                        // reset the year to year of visit
                        year = yearVisited
                        month = 1
                    }
                    if monthVisited == 12 && month == 12 && yearVisited == year {
                        // Check if all twelve months had visits
                        achievements.append(Achievement(Name: "Temple Consistent - \(yearVisited)", Details: "Ordinances completed each month", IconName: "ach12MT", Achieved: temple.dateVisited!, PlaceAchieved: temple.holyPlace!))
                        month = 0
                    }
                    if monthVisited == month + 1 && yearVisited == year {
                        // check if subsequent month has a visit and increment month
                        month += 1
                    }
                }
            }

            getYearTotals(visits: searchResults)
            
            // Check for Historic Sites Achievement
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
            fetchRequest.sortDescriptors = [sortDescriptor]
            searchResults = try getContext().fetch(fetchRequest)
            for site in searchResults as [Visit] {
                // determine unique temples visited
                if !distinctHistoricSitesVisited.contains(site.holyPlace!) {
                    distinctHistoricSitesVisited.append(site.holyPlace!)
                    if distinctHistoricSitesVisited.count == 10 {
                        updateAchievement(achievement:"ach10H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 25 {
                        updateAchievement(achievement:"ach25H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 40 {
                        updateAchievement(achievement:"ach40H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 55 {
                        updateAchievement(achievement:"ach55H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 70 {
                        updateAchievement(achievement:"ach70H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 85 {
                        updateAchievement(achievement:"ach85H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }
                    if distinctHistoricSitesVisited.count == 99 {
                        updateAchievement(achievement:"ach99H", dateAchieved: site.dateVisited!, placeAchieved: site.holyPlace!)
                    }

                }
            }
            
            ordinancesTotal = sealingsTotal + endowmentsTotal + initiatoriesTotal + confirmationsTotal + baptismsTotal
            
            // populate Total labels on view
            attendedTempleTotal.text = attendedTotal.description
            sealingsPerformedTotal.text = sealingsTotal.description
            endowmentsPerformedTotal.text = endowmentsTotal.description
            initiatoriesPerformedTotal.text = initiatoriesTotal.description
            confirmationsPerformedTotal.text = confirmationsTotal.description
            baptismsPerformedTotal.text = baptismsTotal.description
            ordinancesPerformedTotal.text = ordinancesTotal.description
            hoursWorkedTotal.text = shiftHoursTotal.description
            
            // get number of Unique Temples visited
            fetchRequest.predicate = NSPredicate(format: "type == %@", "T")
            searchResults = try getContext().fetch(fetchRequest)
            var distinct = NSSet(array: searchResults.map { $0.holyPlace! })
            templesVisited.text = distinct.count.description
            visitCnt = searchResults.count

            // get number of Unique Historical sites visited
            fetchRequest.predicate = NSPredicate(format: "type == %@", "H")
            searchResults = try getContext().fetch(fetchRequest)
            distinct = NSSet(array: searchResults.map { $0.holyPlace! })
            historicalVisited.text = distinct.count.description
            visitCnt += searchResults.count
            
            // get number of Unique Visitors' Centers visited
            fetchRequest.predicate = NSPredicate(format: "type == %@", "V")
            searchResults = try getContext().fetch(fetchRequest)
            distinct = NSSet(array: searchResults.map { $0.holyPlace! })
            visitorsCentersVisited.text = distinct.count.description
            visitCnt += searchResults.count
            
            // Deteremine most visited places
            let fetchRequest2 = NSFetchRequest<NSDictionary>(entityName:"Visit")
            fetchRequest2.predicate = nil
            fetchRequest2.sortDescriptors = [NSSortDescriptor(key: "holyPlace", ascending: true)]
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
            var textColor = UIColor()
            for place in itemResult {
                let placeName = place.object(forKey: "holyPlace") as! String
                let placeCount = String(format: "%@", place.object(forKey: "count") as! CVarArg)
                
                // Determine type
                if let found = allPlaces.index(where:{$0.templeName == placeName}) {
                    switch allPlaces[found].templeType {
                    case "T":
                        textColor = UIColor.darkRed()
                    case "H":
                        textColor = UIColor.darkLimeGreen()
                    case "C":
                        textColor = UIColor.darkOrange()
                    case "V":
                        textColor = UIColor.strongYellow()
                    default:
                        textColor = UIColor.lead()
                    }
                }
                counter += 1
                switch counter {
                case 1:
                    mostVisitedPlace1.text = placeName
                    mostVisitedCount1.text = placeCount
                    mostVisitedPlace1.textColor = textColor
                    mostVisitedCount1.textColor = textColor
                case 2:
                    mostVisitedPlace2.text = placeName
                    mostVisitedCount2.text = placeCount
                    mostVisitedPlace2.textColor = textColor
                    mostVisitedCount2.textColor = textColor
                case 3:
                    mostVisitedPlace3.text = placeName
                    mostVisitedCount3.text = placeCount
                    mostVisitedPlace3.textColor = textColor
                    mostVisitedCount3.textColor = textColor
                case 4:
                    mostVisitedPlace4.text = placeName
                    mostVisitedCount4.text = placeCount
                    mostVisitedPlace4.textColor = textColor
                    mostVisitedCount4.textColor = textColor
                case 5:
                    mostVisitedPlace5.text = placeName
                    mostVisitedCount5.text = placeCount
                    mostVisitedPlace5.textColor = textColor
                    mostVisitedCount5.textColor = textColor
                case 6:
                    mostVisitedPlace6.text = placeName
                    mostVisitedCount6.text = placeCount
                    mostVisitedPlace6.textColor = textColor
                    mostVisitedCount6.textColor = textColor
                case 7:
                    mostVisitedPlace7.text = placeName
                    mostVisitedCount7.text = placeCount
                    mostVisitedPlace7.textColor = textColor
                    mostVisitedCount7.textColor = textColor
                case 8:
                    mostVisitedPlace8.text = placeName
                    mostVisitedCount8.text = placeCount
                    mostVisitedPlace8.textColor = textColor
                    mostVisitedCount8.textColor = textColor
                case 9:
                    mostVisitedPlace9.text = placeName
                    mostVisitedCount9.text = placeCount
                    mostVisitedPlace9.textColor = textColor
                    mostVisitedCount9.textColor = textColor
                case 10:
                    mostVisitedPlace10.text = placeName
                    mostVisitedCount10.text = placeCount
                    mostVisitedPlace10.textColor = textColor
                    mostVisitedCount10.textColor = textColor
                case 11:
                    mostVisitedPlace11.text = placeName
                    mostVisitedCount11.text = placeCount
                    mostVisitedPlace11.textColor = textColor
                    mostVisitedCount11.textColor = textColor
                case 12:
                    mostVisitedPlace12.text = placeName
                    mostVisitedCount12.text = placeCount
                    mostVisitedPlace12.textColor = textColor
                    mostVisitedCount12.textColor = textColor
                default:
                    break
                }
//                print("\(placeName) - \(placeCount)")
                if counter == 12 {
                    break
                }
            }
            
            // Hide Hours Worked row if not enabled
            hoursWorked.isHidden = !ordinanceWorker
            hoursWorkedYr.isHidden = !ordinanceWorker
            hoursWorkedYr2.isHidden = !ordinanceWorker
            hoursWorkedTotal.isHidden = !ordinanceWorker

            // If entered a few visits, prompt for a rating
            if visitCnt > 3 {
                if #available(iOS 10.3, *) {
//                    SKStoreReviewController.requestReview()
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
        var shiftHrs = 0.0
        var sealings2 = 0
        var endowments2 = 0
        var initiatories2 = 0
        var confirmations2 = 0
        var baptisms2 = 0
        var ordinances2 = 0
        var attended2 = 0
        var shiftHrs2 = 0.0
        
        let year1 = String(Int(currentYear)! + yearOffset)
        let year2 = String(Int(currentYear)! + yearOffset - 1)
        if yearOffset < 0 {
            titleYr1.setTitle("<\(year1)", for: .normal)
        } else {
            titleYr1.setTitle(year1, for: .normal)
        }
        titleYr2.setTitle("\(year2)>", for: .normal)
//        titleYr2.setTitle(year2, for: .normal)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        
        for temple in visits {
            // check for ordinances performed in 2 specific years based on offset
            let yearVisited = formatter.string(from: temple.dateVisited!)
            if (yearVisited == year1) {
                
                sealings += Int(temple.sealings)
                endowments += Int(temple.endowments)
                initiatories += Int(temple.initiatories)
                confirmations += Int(temple.confirmations)
                baptisms += Int(temple.baptisms)
                shiftHrs += temple.shiftHrs
                if excludeNonOrdinanceVisits {
                    if Int(temple.baptisms) > 0 || Int(temple.confirmations) > 0 || Int(temple.initiatories) > 0 || Int(temple.endowments) > 0 || Int(temple.sealings) > 0 {
                        attended += 1
                    }
                } else {
                    attended += 1
                }
            }
            if (yearVisited == year2) {
                
                sealings2 += Int(temple.sealings)
                endowments2 += Int(temple.endowments)
                initiatories2 += Int(temple.initiatories)
                confirmations2 += Int(temple.confirmations)
                baptisms2 += Int(temple.baptisms)
                shiftHrs2 += temple.shiftHrs
                if excludeNonOrdinanceVisits {
                    if Int(temple.baptisms) > 0 || Int(temple.confirmations) > 0 || Int(temple.initiatories) > 0 || Int(temple.endowments) > 0 || Int(temple.sealings) > 0 {
                        attended2 += 1
                    }
                } else {
                    attended2 += 1
                }
            }
        }
        
        ordinances = sealings + endowments + initiatories + confirmations + baptisms
        
        attendedTempleYr.text = attended.description
        hoursWorkedYr.text = shiftHrs.description
        sealingsPerformedYr.text = sealings.description
        endowmentsPerformedYr.text = endowments.description
        initiatoriesPerformedYr.text = initiatories.description
        confirmationsPerformedYr.text = confirmations.description
        baptismsPerformedYr.text = baptisms.description
        ordinancesPerformedYr.text = ordinances.description
        
        ordinances2 = sealings2 + endowments2 + initiatories2 + confirmations2 + baptisms2
        
        attendedTempleYr2.text = attended2.description
        hoursWorkedYr2.text = shiftHrs2.description
        sealingsPerformedYr2.text = sealings2.description
        endowmentsPerformedYr2.text = endowments2.description
        initiatoriesPerformedYr2.text = initiatories2.description
        confirmationsPerformedYr2.text = confirmations2.description
        baptismsPerformedYr2.text = baptisms2.description
        ordinancesPerformedYr2.text = ordinances2.description

    }
    
    func updateAchievement(achievement:String, dateAchieved:Date, placeAchieved:String) {
        if let location = achievements.index(where:{$0.iconName == achievement}) {
            // Only update if not already achieved
            if achievements[location].achieved == nil {
                achievements[location].achieved = dateAchieved
                achievements[location].placeAchieved = placeAchieved
            }
        }
    }
    
    func initAchievements() {
        achievements.removeAll()
        // Ordinances - Baptisms
        achievements.append(Achievement(Name: "Excellent! (Baptisms)", Details: "25 Baptisms", IconName: "ach25B"))
        achievements.append(Achievement(Name: "Wonderful! (Baptisms)", Details: "50 Baptisms", IconName: "ach50B"))
        achievements.append(Achievement(Name: "Incredible! (Baptisms)", Details: "100 Baptisms", IconName: "ach100B"))
        achievements.append(Achievement(Name: "Extraordinary! (Baptisms)", Details: "200 Baptisms", IconName: "ach200B"))
        achievements.append(Achievement(Name: "Astounding! (Baptisms)", Details: "400 Baptisms", IconName: "ach400B"))
        achievements.append(Achievement(Name: "Unbelievable! (Baptisms)", Details: "800 Baptisms", IconName: "ach800B"))
        // Ordinances - Initiatories
        achievements.append(Achievement(Name: "Excellent! (Initiatories)", Details: "25 Iniatories", IconName: "ach25I"))
        achievements.append(Achievement(Name: "Wonderful! (Initiatories)", Details: "50 Iniatories", IconName: "ach50I"))
        achievements.append(Achievement(Name: "Incredible! (Initiatories)", Details: "100 Iniatories", IconName: "ach100I"))
        achievements.append(Achievement(Name: "Extraordinary! (Initiatories)", Details: "200 Iniatories", IconName: "ach200I"))
        achievements.append(Achievement(Name: "Astounding! (Initiatories)", Details: "400 Iniatories", IconName: "ach400I"))
        achievements.append(Achievement(Name: "Unbelievable! (Initiatories)", Details: "800 Iniatories", IconName: "ach800I"))
        // Ordinances - Endowments
        achievements.append(Achievement(Name: "Excellent! (Endowments)", Details: "10 Endowments", IconName: "ach10E"))
        achievements.append(Achievement(Name: "Wonderful! (Endowments)", Details: "25 Endowments", IconName: "ach25E"))
        achievements.append(Achievement(Name: "Incredible! (Endowments)", Details: "50 Endowments", IconName: "ach50E"))
        achievements.append(Achievement(Name: "Extraordinary! (Endowments)", Details: "100 Endowments", IconName: "ach100E"))
        achievements.append(Achievement(Name: "Astounding! (Endowments)", Details: "200 Endowments", IconName: "ach200E"))
        achievements.append(Achievement(Name: "Unbelievable! (Endowments)", Details: "400 Endowments", IconName: "ach400E"))
        // Ordinances - Sealings
        achievements.append(Achievement(Name: "Excellent! (Sealings)", Details: "50 Sealings", IconName: "ach50S"))
        achievements.append(Achievement(Name: "Wonderful! (Sealings)", Details: "100 Sealings", IconName: "ach100S"))
        achievements.append(Achievement(Name: "Incredible! (Sealings)", Details: "200 Sealings", IconName: "ach200S"))
        achievements.append(Achievement(Name: "Extraordinary! (Sealings)", Details: "400 Sealings", IconName: "ach400S"))
        achievements.append(Achievement(Name: "Astounding! (Sealings)", Details: "800 Sealings", IconName: "ach800S"))
        achievements.append(Achievement(Name: "Unbelievable! (Sealings)", Details: "1600 Sealings", IconName: "ach1600S"))
        // Temples
        achievements.append(Achievement(Name: "Temple Admirer", Details: "Visit 10 different temples", IconName: "ach10T"))
        achievements.append(Achievement(Name: "Temple Lover", Details: "Visit 20 different temples", IconName: "ach20T"))
        achievements.append(Achievement(Name: "Temple Devotee", Details: "Visit 30 different temples", IconName: "ach30T"))
        achievements.append(Achievement(Name: "Temple Enthusiast", Details: "Visit 40 different temples", IconName: "ach40T"))
        achievements.append(Achievement(Name: "Temple Fanatic", Details: "Visit 50 different temples", IconName: "ach50T"))
        achievements.append(Achievement(Name: "Temple Zealot", Details: "Visit 75 different temples", IconName: "ach75T"))
        achievements.append(Achievement(Name: "Temple Visionary", Details: "Visit 100 different temples", IconName: "ach100T"))
        achievements.append(Achievement(Name: "Temple Addict", Details: "Visit 125 different temples", IconName: "ach125T"))
        achievements.append(Achievement(Name: "Temple Aficionado", Details: "Visit 150 different temples", IconName: "ach150T"))
        if activeTemples.count > 174 {
            achievements.append(Achievement(Name: "Temple Buff", Details: "Visit 175 different temples", IconName: "ach175T"))
        }
        if activeTemples.count > 199 {
            achievements.append(Achievement(Name: "Temple Ultraist", Details: "Visit 200 different temples", IconName: "ach200T"))
        }
        // Historic Sites
        achievements.append(Achievement(Name: "History Admirer", Details: "Visit 10 different historic sites", IconName: "ach10H"))
        achievements.append(Achievement(Name: "History Lover", Details: "Visit 25 different historic sites", IconName: "ach25H"))
        achievements.append(Achievement(Name: "History Enthusiast", Details: "Visit 40 different historic sites", IconName: "ach40H"))
        achievements.append(Achievement(Name: "History Zealot", Details: "Visit 55 different historic sites", IconName: "ach55H"))
        achievements.append(Achievement(Name: "History Aficionado", Details: "Visit 70 different historic sites", IconName: "ach70H"))
        achievements.append(Achievement(Name: "History Buff", Details: "Visit 85 different historic sites", IconName: "ach85H"))
        achievements.append(Achievement(Name: "History Ultraist", Details: "Visit 99 different historic sites", IconName: "ach99H"))
    }

    //MARK: - XML Parser
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        if elementName == "Quote" {
            summaryQuote = String()
        }
    }
    
    // foundCharacters of parser
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !string.isEmpty {
            switch eName {
            case "Quote": summaryQuote = string
            default: return
            }
        }
    }
    
    // didEndElement of parser
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Quote" {
           summaryQuotes.append(summaryQuote.replacingOccurrences(of: "*", with: "\r\n"))
        }
    }
}
