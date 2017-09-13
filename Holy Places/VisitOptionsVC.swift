//
//  VisitOptionsVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 2/8/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

protocol SendVisitOptionsDelegate {
    func FilterOptions(row: Int)
    func SortOptions(row: Int)
}

class VisitOptionsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
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
    let visitFile = "HolyPlacesVisits.txt"
    //var fileURL = NSURL()
    
    //MARK: - Outlets
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pickerFilter: UIPickerView!
    @IBOutlet weak var pickerSort: UIPickerView!
    @IBOutlet weak var exportButton: UIBarButtonItem!
    
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
        getVisits()
        do {
            try export(visits, title: "MyHolyPlaces")
        } catch {
            print("Error with export: \(error)")
        }
    }
    
    func export(_ string: String, title: String) throws {
        // create a file path in a temporary directory
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(visitFile)
        
        // save the string to the file
        try string.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        
        // open share dialog
        
        // Initialize Document Interaction Controller
        self.docController = UIDocumentInteractionController(url: URL(fileURLWithPath: filePath))
        // Configure Document Interaction Controller
        //self.docController!.delegate = self
        // Present Open In Menu
        self.docController!.presentOptionsMenu(from: exportButton, animated: true) // create an outlet from an Export bar button outlet, then use it as the `from` argument
    }
    
    //MARK: - CoreData Functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    // Retrieve the Visits data from CoreData
    func getVisits () {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Sort by dateVisited
        let sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd YYYY"
        
        // Add title and date to visits string
        visits = "My Holy Places Visits\n Exported on " + formatter.string(from: Date.init()) + "\n"
        
        do {
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            //Check the size of the returned results
            //print ("num of results = \(searchResults.count)")
            visits.append(" Total Number of Visits: \(searchResults.count)\n\n")
            
            //Loop through each
            for visit in searchResults as [NSManagedObject] {
                visits.append(visit.value(forKey: "holyPlace") as! String)
                visits.append("\n ")
                visits.append(formatter.string(from: visit.value(forKey: "dateVisited") as! Date))
                visits.append("\n ")
                visits.append(visit.value(forKey: "comments") as! String)
                
                if visit.value(forKey: "type") as! String == "T" {
                    if visit.value(forKey: "sealings") as! Int > 0 {
                        visits.append("\n Sealings: ")
                        visits.append(((visit.value(forKey: "sealings") as? Int)?.description)!)
                    }
                    if visit.value(forKey: "endowments") as! Int > 0 {
                        visits.append("\n Endowments: ")
                        visits.append(((visit.value(forKey: "endowments") as? Int)?.description)!)
                    }
                    if visit.value(forKey: "initiatories") as! Int > 0 {
                        visits.append("\n Initiatories: ")
                        visits.append(((visit.value(forKey: "initiatories") as? Int)?.description)!)
                    }
                    if visit.value(forKey: "confirmations") as! Int > 0 {
                        visits.append("\n Confirmations: ")
                        visits.append(((visit.value(forKey: "confirmations") as? Int)?.description)!)
                    }
                    if visit.value(forKey: "baptisms") as! Int > 0 {
                        visits.append("\n Baptisms: ")
                        visits.append(((visit.value(forKey: "baptisms") as? Int)?.description)!)
                    }
                }
                visits.append("\n\n")
            }
            //print(visits)
        } catch {
            print("Error with request: \(error)")
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
