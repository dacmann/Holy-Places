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

protocol SendVisitOptionsDelegate {
    func FilterOptions(row: Int)
    func SortOptions(row: Int)
}

class VisitOptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIDocumentPickerDelegate, UINavigationControllerDelegate, XMLParserDelegate {
    
    //MARK: - Variables
    var delegateOptions: SendVisitOptionsDelegate? = nil
    
    var filterSelected: Int?
    var sortSelected: Int?
    //var nearestEnabled: Bool?
    var filterChoices = ["Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction"  ]
    var sortOptions = ["Latest Visit", "Group by Place"]
    // UIDocumentInteractionController instance is a class property
    var docController:UIDocumentInteractionController!
    var visits = String()
    var eName: String = String()
    var holyPlace = String()
    var comments = String()
    var visitDate = Date()
    var sealings = Int16()
    var endowments = Int16()
    var initiatories = Int16()
    var confirmations = Int16()
    var baptisms = Int16()
    var type = String()
    let dateFormatter = DateFormatter()
    var importCount = 0
    
    //MARK: - Outlets
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerFilter: UIPickerView!
    @IBOutlet weak var pickerSort: UIPickerView!
    @IBOutlet weak var txtExport: UIBarButtonItem!
    @IBOutlet weak var xmlExport: UIBarButtonItem!
    @IBOutlet weak var csvExport: UIBarButtonItem!
    
    //MARK: - Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        pickerFilter.dataSource = self
        pickerFilter.delegate = self
        pickerFilter.selectRow(filterSelected!, inComponent: 0, animated: true)
        pickerSort.dataSource = self
        pickerSort.delegate = self
        pickerSort.selectRow(sortSelected!, inComponent: 0, animated: true)
        
        dateFormatter.dateStyle = .full
    }
    
    //MARK: - PickerView Functions
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel!
        if label == nil {
            label = UILabel()
        }
        var data = filterChoices[row]
        if pickerView.tag == 1 {
            data = sortOptions[row]
        }
        let title = NSAttributedString(string: data, attributes: [NSAttributedStringKey.font: UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)])
        label?.attributedText = title
        label?.textAlignment = .center
        
        switch data {
        case "Active Temples":
            label?.textColor = UIColor.darkRed()
        case "Historical Sites":
            label?.textColor = UIColor.darkLimeGreen()
        case "Visitors' Centers":
            label?.textColor = UIColor.strongYellow()
        case "Temples Under Construction":
            label?.textColor = UIColor.darkOrange()
        default:
            label?.textColor = UIColor.lead()
        }
        return label!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return sortOptions.count
        } else {
            return filterChoices.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return sortOptions[row]
        } else {
            return filterChoices[row]
        }
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
    @IBAction func exportAction(_ sender: UIBarButtonItem) {
        getVisits(type: "txt")
        do {
            try exportFile(visits, title: "HolyPlacesVisits", type: "txt")
        } catch {
            print("Error with export: \(error)")
        }
    }
    @IBAction func exportXmlAction(_ sender: UIBarButtonItem) {
        getVisits(type: "xml")
        do {
            try exportFile(visits, title: "HolyPlacesVisits", type: "xml")
        } catch {
            print("Error with export: \(error)")
        }
    }
    @IBAction func exportCsvAction(_ sender: UIBarButtonItem) {
        getVisits(type: "csv")
        do {
            try exportFile(visits, title: "HolyPlacesVisits", type: "csv")
        } catch {
            print("Error with export: \(error)")
        }
    }
    @IBAction func importVisits(_ sender: UIButton) {
        let importMenu = UIDocumentPickerViewController(documentTypes: [kUTTypeXML as String], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
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
        
        // create an outlet from an Export bar button outlet, then use it as the `from` argument
        switch type {
        case "txt":
            self.docController!.presentOptionsMenu(from: txtExport, animated: true)
        case "csv":
            self.docController!.presentOptionsMenu(from: csvExport, animated: true)
        default: // xml
            self.docController!.presentOptionsMenu(from: xmlExport, animated: true)
        }
    }
    
    //MARK: - CoreData Functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
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
            
            //Check the size of the returned results
            //print ("num of results = \(searchResults.count)")
            
            switch type {
            case "txt":
                visits.append(" Total Number of Visits: \(searchResults.count)\n\n")
            case "csv":
                visits = "holyPlace,type,dateVisited,comments,sealings,endowments,initiatories,confirmations,baptisms\n"
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
                case "csv":
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateStyle = .short
                    visits.append("\(visit.holyPlace!),\(visit.type!),\(dateFormatter2.string(from: visit.dateVisited!)),\"\(visit.comments!)\"")
                default: // xml
                    visits.append("<Visit><holyPlace>\(visit.holyPlace!)</holyPlace>")
                    visits.append("<type>\(visit.type!)</type>")
                    visits.append("<dateVisited>\(dateFormatter.string(from: visit.dateVisited!))</dateVisited>")
                    visits.append("<comments><![CDATA[\(visit.comments!)]]></comments>")
                }
                
                if visit.value(forKey: "type") as! String == "T" {
                    switch type {
                    case "txt":
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
                        visits.append(",\(visit.sealings),\(visit.endowments),\(visit.initiatories),\(visit.confirmations),\(visit.baptisms)")
                    default: //xml
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
                    visits.append("\n")
                default: // xml
                    // include picture binary data
                    //                    if visit.picture != nil {
                    //                        visits.append("<picture>\(visit.picture?.base64EncodedString() ?? "")</picture>")
                    //                    }
                    visits.append("</Visit>")
                }
            }
            if type == "xml" {
                // Add closing tags
                visits.append("</Visits></Document>")
            }
//            print(visits)
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        let myURL = url as URL
//        print("The Url is : \(myURL)")
        guard let parser = XMLParser(contentsOf: myURL as URL) else {
            print("Cannot Read Data")
            return
        }
        
        parser.delegate = self
        if parser.parse() {
            let alert = UIAlertController(title: "Import Successful", message: "Successfully imported \(importCount) visits", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
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
    public func documentMenu(_ documentMenu:     UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        if elementName == "Visit" {
            holyPlace = String()
            comments = String()
            visitDate = Date()
            sealings = Int16()
            endowments = Int16()
            initiatories = Int16()
            confirmations = Int16()
            baptisms = Int16()
            type = String()
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
            case "sealings": sealings = Int16(string)!
            case "endowments": endowments = Int16(string)!
            case "initiatories": initiatories = Int16(string)!
            case "confirmations": confirmations = Int16(string)!
            case "baptisms": baptisms = Int16(string)!
            case "type": type = string
            default: return
            }
        }
    }
    
    // didEndElement of parser
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Visit" {
            let context = getContext()
            
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
            
            //save the object
            do {
                try context.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            } catch {}
//            print("Saving Visit completed")
            importCount += 1
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
