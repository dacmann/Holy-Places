//
//  VisitOptionsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 2/8/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import UniformTypeIdentifiers

protocol SendVisitOptionsDelegate {
    func FilterOptions(row: Int)
    func SortOptions(row: Int)
}

class VisitOptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIDocumentPickerDelegate, UINavigationControllerDelegate, XMLParserDelegate {
    
    //MARK: - Variables
    var delegateOptions: SendVisitOptionsDelegate? = nil
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var filterSelected: Int?
    var sortSelected: Int?
    //var nearestEnabled: Bool?
    var filterChoices = ["All Visits", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction", "Other"  ]
    // UIDocumentInteractionController instance is a class property
    var docController:UIDocumentInteractionController!
    var visits = String()
    var eName: String = String()
    var holyPlace = String()
    var comments = String()
    var visitDate = Date()
    var hoursWorked = Double()
    var sealings = Int16()
    var endowments = Int16()
    var initiatories = Int16()
    var confirmations = Int16()
    var baptisms = Int16()
    var type = String()
    var isFavorite = false
    let dateFormatter = DateFormatter()
    let dateFormatterFile = DateFormatter()
    var importCount = 0
    var duplicates = 0
    var fileName = String()
    var exportCount = 0
    
    //MARK: - Outlets
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerFilter: UIPickerView!
    @IBOutlet weak var txtExport: UIButton!
    @IBOutlet weak var xmlExport: UIButton!
    @IBOutlet weak var csvExport: UIButton!
    @IBOutlet weak var message: UILabel!
    
    //MARK: - Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        pickerFilter.dataSource = self
        pickerFilter.delegate = self
        pickerFilter.selectRow(filterSelected!, inComponent: 0, animated: true)
        
        dateFormatter.dateStyle = .full
        dateFormatterFile.dateFormat = "yyyyMMdd"
        fileName = "HolyPlacesVisits-\(dateFormatterFile.string(from: Date.init()))"
    }
    
    //MARK: - PickerView Functions
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel?
        if label == nil {
            label = UILabel()
        }
        let data = filterChoices[row]
        let title = NSAttributedString(string: data, attributes: [NSAttributedString.Key.font: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch data {
        case "Active Temples":
            label?.textColor = templeColor
        case "Historical Sites":
            label?.textColor = historicalColor
        case "Visitors' Centers":
            label?.textColor = visitorCenterColor
        case "Temples Under Construction":
            label?.textColor = constructionColor
        default:
            label?.textColor = defaultColor
        }
        return label!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return filterChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filterChoices[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            sortSelected = row
        } else {
            filterSelected = row
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: - Export Functions
    @IBAction func exportTxtAction(_ sender: UIButton) {
        getVisits(type: "txt")
        do {
            try exportFile(visits, title: fileName, type: "txt")
        } catch {
            print("Error with export: \(error)")
        }
    }
    
    @IBAction func exportXmlAction(_ sender: UIButton) {
        getVisits(type: "xml")
        do {
            try exportFile(visits, title: fileName, type: "xml")
            // Keep track of when backup was last performed
            let defaults = UserDefaults.standard
            defaults.set(Date(), forKey: "backupDate")
        } catch {
            print("Error with export: \(error)")
        }
    }
    
    @IBAction func exportCsvAction(_ sender: UIButton) {
        getVisits(type: "csv")
        do {
            try exportFile(visits, title: fileName, type: "csv")
        } catch {
            print("Error with export: \(error)")
        }
    }
    
    @IBAction func importVisits(_ sender: UIButton) {
        let types = [UTType.xml]
        let importMenu = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .fullScreen
        self.present(importMenu, animated: true)
    }
    
    func exportFile(_ string: String, title: String, type: String) throws {
        // create a file path in a temporary directory
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(title).\(type)")
        
        // save the string to the file
        try string.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
        // open share dialog
        // Initialize Document Interaction Controller
        self.docController = UIDocumentInteractionController(url: URL(fileURLWithPath: filePath))
        // Configure Document Interaction Controller
        // Present Open In Menu
        
        // create an outlet from an Export button outlet, then use it as the `from` argument
        switch type {
        case "txt":
            self.docController.presentOptionsMenu(from: txtExport.frame, in: self.view, animated: true)
        case "csv":
            self.docController.presentOptionsMenu(from: csvExport.frame, in: self.view, animated: true)
        default: // xml
            self.docController.presentOptionsMenu(from: xmlExport.frame, in: self.view, animated: true)
        }
    }
    
    //MARK: - CoreData Functions
    func getContext () -> NSManagedObjectContext {
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return ad.persistentContainer.viewContext
    }
    
    // Retrieve the Visits data from CoreData
    func getVisits (type: String) {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Sort by dateVisited
        let sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if type == "txt" {
            // Add title and date to visits string
            visits = "My Holy Places Visits\n Exported on \(dateFormatter.string(from: Date.init()))\n"
        } else {
            visits = "<?xml version=\"1.0\" encoding=\"utf-8\"?><Document><ExportDate>\(Date.init())</ExportDate>"
        }
        
        do {
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            exportCount = searchResults.count
            //Check the size of the returned results
            //print ("num of results = \(searchResults.count)")
            
            switch type {
            case "txt":
                visits.append(" Total Number of Visits: \(exportCount)\n\n")
            case "csv":
                visits = "holyPlace,type,dateVisited,comments,hoursWorked,sealings,endowments,initiatories,confirmations,baptisms,isFavorite\n"
            default: // xml
                visits.append("<TotalVisits>\(searchResults.count)</TotalVisits><Visits>")
            }
            
            //Loop through each
            for visit in searchResults as [Visit] {
                switch type {
                case "txt":
                    visits.append("\(visit.holyPlace!)\n")
                    visits.append("\(dateFormatter.string(from: visit.dateVisited!))\n")
                    visits.append(visit.comments!)
                    if visit.isFavorite {
                        visits.append("\n⭐️ Favorite Visit")
                    }
                case "csv":
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateStyle = .short
                    visits.append("\(visit.holyPlace!),\(visit.type!),\(dateFormatter2.string(from: visit.dateVisited!)),\"\(visit.comments!)\"")
                default: // xml
                    visits.append("<Visit><holyPlace>\(visit.holyPlace!)</holyPlace>")
                    visits.append("<type>\(visit.type!)</type>")
                    visits.append("<dateVisited>\(dateFormatter.string(from: visit.dateVisited!))</dateVisited>")
                    visits.append("<comments><![CDATA[\(visit.comments!)]]></comments>")
                    visits.append("<isFavorite>\(visit.isFavorite)</isFavorite>")
                }
                
                if visit.value(forKey: "type") as! String == "T" {
                    switch type {
                    case "txt":
                        if visit.shiftHrs > 0 {
                            visits.append("\n Hours Worked: \(visit.shiftHrs)")
                        }
                        if visit.sealings > 0 {
                            visits.append("\n Sealings: \(visit.sealings)")
                        }
                        if visit.endowments > 0 {
                            visits.append("\n Endowments: \(visit.endowments)")
                        }
                        if visit.initiatories > 0 {
                            visits.append("\n Initiatories: \(visit.initiatories)")
                        }
                        if visit.confirmations > 0 {
                            visits.append("\n Confirmations: \(visit.confirmations)")
                        }
                        if visit.baptisms > 0 {
                            visits.append("\n Baptisms: \(visit.baptisms)")
                        }
                    case "csv":
                        visits.append(",\(visit.shiftHrs),\(visit.sealings),\(visit.endowments),\(visit.initiatories),\(visit.confirmations),\(visit.baptisms)")
                    default: //xml
                        visits.append("<hoursWorked>\(visit.shiftHrs)</hoursWorked>")
                        visits.append("<sealings>\(visit.sealings)</sealings>")
                        visits.append("<endowments>\(visit.endowments)</endowments>")
                        visits.append("<initiatories>\(visit.initiatories)</initiatories>")
                        visits.append("<confirmations>\(visit.confirmations)</confirmations>")
                        visits.append("<baptisms>\(visit.baptisms)</baptisms>")
                    }
                }
                switch type {
                case "txt":
                    visits.append("\n\n")
                case "csv":
                    visits.append(",\(visit.isFavorite)\n")
                default: 
                    visits.append("</Visit>")
                }
            }
            if type == "xml" {
                // Add closing tags
                visits.append("</Visits></Document>")
            }
//            print(visits)
            message.text = "Exported \(exportCount) visits to \(type) file."
            message.textColor = templeColor
            // Update visit count 
            ad.getVisits()
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt url: [URL]) {
        
        guard let parser = XMLParser(contentsOf: url[0]) else {
            print("Cannot Read Data")
            return
        }
        
        parser.delegate = self
        if parser.parse() {
            let alert = UIAlertController(title: "Import Completed", message: "Successfully imported \(importCount) visits; \(duplicates) duplicate visits skipped", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            ad.getVisits()
        } else {
            print("Data parsing aborted")
            let error = parser.parserError!
            print("Error Description:\(error.localizedDescription)")
            print("Line number: \(parser.lineNumber)")
            let alert = UIAlertController(title: "Import Failure", message: "The XML file selected isn't formatted properly", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
        
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        if elementName == "Visit" {
            holyPlace = String()
            comments = String()
            visitDate = Date()
            hoursWorked = Double()
            sealings = Int16()
            endowments = Int16()
            initiatories = Int16()
            confirmations = Int16()
            baptisms = Int16()
            type = String()
            isFavorite = false
        }
    }
    
    // foundCharacters of parser
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !string.isEmpty {
            switch eName {
            case "holyPlace": holyPlace = string
            case "comments": comments = string
            case "dateVisited":
                if dateFormatter.date(from: string) == nil {
                    parser.abortParsing()
                    break
                }
                visitDate = dateFormatter.date(from: string)!
            case "hoursWorked": hoursWorked = Double(string)!
            case "sealings": sealings = Int16(string)!
            case "endowments": endowments = Int16(string)!
            case "initiatories": initiatories = Int16(string)!
            case "confirmations": confirmations = Int16(string)!
            case "baptisms": baptisms = Int16(string)!
            case "type": type = string
            case "isFavorite": isFavorite = string.lowercased() == "true"
            default: return
            }
        }
    }
    
    // didEndElement of parser
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Visit" {
            let context = getContext()
            
            // ✅ Check for old place names and update them
            if !allPlaces.contains(where: { $0.templeName == holyPlace }) {
                for temple in allPlaces {
                    if temple.oldNames.contains(holyPlace) {
                        print("🛠 Imported visit renamed from \(holyPlace) to \(temple.templeName)")
                        holyPlace = temple.templeName
                        break
                    }
                }
            }
            
            // Check for duplicate before saving
            do {
            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dateVisited == %@ && holyPlace == %@ && comments == %@", visitDate as NSDate, holyPlace as String, comments as String)
                let searchResults = try getContext().fetch(fetchRequest)
                if searchResults.count == 0 {
                    
                    //insert a new object in the Visit entity
                    let visit = NSEntityDescription.insertNewObject(forEntityName: "Visit", into: context) as! Visit
                    
                    //set the entity values
                    visit.holyPlace = holyPlace
                    visit.baptisms = baptisms
                    visit.confirmations = confirmations
                    visit.initiatories = initiatories
                    visit.endowments = endowments
                    visit.sealings = sealings
                    visit.comments = comments
                    visit.dateVisited = visitDate
                    visit.type = type
                    visit.shiftHrs = hoursWorked
                    visit.isFavorite = isFavorite
                    
                    //save the object
                    do {
                        try context.save()
                    } catch let error as NSError  {
                        print("Could not save \(error), \(error.userInfo)")
                    } catch {}
                    //            print("Saving Visit completed")
                    importCount += 1
                    
                } else {
//                    print("Duplicate - not importing")
                    duplicates += 1
                }
            } catch {
                print("Error with request: \(error)")
            }
            
        }
    }

    //MARK: - Navigation
    @IBAction func goBack(_ sender: UIButton) {
        if delegateOptions != nil {
            delegateOptions?.FilterOptions(row: filterSelected!)
            delegateOptions?.SortOptions(row: sortSelected!)
        }
        self.dismiss(animated: true, completion: nil)
    }
    

}
