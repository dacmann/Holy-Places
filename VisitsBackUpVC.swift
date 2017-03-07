//
//  VisitsBackUpVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 3/6/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

class VisitsBackUpVC: UIViewController {

    
    //MARK: - Variables
    var visits = String()
    let visitFile = "HolyPlacesVisits.txt"
    var fileURL = NSURL()
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    // UIDocumentInteractionController instance is a class property
    var docController:UIDocumentInteractionController!
    
    // called when bar button item is pressed
    @IBAction func shareDoc(sender: AnyObject) {
        // present UIDocumentInteractionController
        docController.presentOptionsMenu(from: sender as! UIBarButtonItem, animated: true)
    }
    
    //MARK: - Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        getVisits()
        
        // Instantiate the interaction controller
        self.docController = UIDocumentInteractionController(url: fileURL as URL)
        
    }

    //MARK: - CoreData Functions
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    // Retrieve the Visits data from CoreData
    func getVisits () {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        var visits = String()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd YYYY"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let path = dir.appendingPathComponent(visitFile)
                fileURL = path.absoluteURL as NSURL
                
                //go get the results
                let searchResults = try getContext().fetch(fetchRequest)
                
                //Check the size of the returned results
                print ("num of results = \(searchResults.count)")

                
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
            } catch {
                print("Error with request: \(error)")
            }
            do {
                try visits.write(to: fileURL as URL, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                print("Error with write: \(error)")
            }
        }
    }

    @IBAction func exportToNotes(_ sender: UIButton) {
        
        //reading
//        do {
//            let text2 = try String(contentsOf: fileURL as URL, encoding: String.Encoding.utf8)
//            print(text2)
//        }
//        catch {/* error handling here */}
        // present UIDocumentInteractionController
        docController.presentOptionsMenu(from: CGRect(x: 0, y: 0, width: 100, height: 100), in: toolBar, animated: true)
    }
    
    @IBAction func exportToXML(_ sender: UIButton) {
    }
    
    // MARK: - Navigation

    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    


}
