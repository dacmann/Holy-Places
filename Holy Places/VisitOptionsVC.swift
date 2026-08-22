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
    // Protocol for future use if needed
}

class VisitOptionsVC: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate, XMLParserDelegate {
    
    //MARK: - Variables
    var delegateOptions: SendVisitOptionsDelegate? = nil
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //var nearestEnabled: Bool?
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
    var pictureData: Data?
    var pictureBase64String: String = ""
    var currentText = ""
    var visitDateIsValid = false
    let dateFormatter = DateFormatter()
    let dateFormatterFile = DateFormatter()
    var importCount = 0
    var duplicates = 0
    var photoImportCount = 0
    var skippedInvalid = 0
    var fileName = String()
    var exportCount = 0
    private var estimateGeneration = 0
    
    /// Locale-stable calendar date for XML (import/export). Independent of device language.
    private let xmlDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let legacyFullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let legacyEnglishFullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    //MARK: - Outlets
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var txtExport: UIButton!
    @IBOutlet weak var xmlExport: UIButton!
    @IBOutlet weak var csvExport: UIButton!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var includePhotos: UISwitch!
    @IBOutlet weak var estimatedSize: UILabel!
    
    //MARK: - Standard Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        dateFormatter.dateStyle = .full
        dateFormatterFile.dateFormat = "yyyyMMdd"
        if profilesEnabled {
            let profileName = ProfileManager.shared.activeProfileName()
                .replacingOccurrences(of: " ", with: "_")
            fileName = "HolyPlaces_\(profileName)_Visits-\(dateFormatterFile.string(from: Date.init()))"
        } else {
            fileName = "HolyPlacesVisits-\(dateFormatterFile.string(from: Date.init()))"
        }
        
        // Set up photo export UI
        updateEstimatedSize()
        includePhotos.addTarget(self, action: #selector(includePhotosChanged), for: .valueChanged)
    }
    
    
    //MARK: - Photo Export Functions
    @objc func includePhotosChanged() {
        updateEstimatedSize()
    }
    
    func updateEstimatedSize() {
        estimateGeneration += 1
        let generation = estimateGeneration
        let includePhotoData = includePhotos.isOn
        if includePhotoData {
            estimatedSize.text = "Estimated size: calculating…"
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let bytes = self?.calculateEstimatedFileSize(includePhotos: includePhotoData) ?? 0
            DispatchQueue.main.async {
                guard let self, generation == self.estimateGeneration else { return }
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
                formatter.countStyle = .file
                self.estimatedSize.text = "Estimated size: \(formatter.string(fromByteCount: bytes))"
            }
        }
    }
    
    func calculateEstimatedFileSize(includePhotos: Bool) -> Int64 {
        let context = ad.persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
                fetchRequest.predicate = ProfileManager.shared.visitProfilePredicate()
                let searchResults = try context.fetch(fetchRequest)
                
                var estimatedSize: Int64 = 1000
                for visit in searchResults {
                    estimatedSize += Int64(visit.holyPlace?.count ?? 0) * 2
                    estimatedSize += Int64(visit.comments?.count ?? 0) * 2
                    estimatedSize += 200
                    
                    if includePhotos, let pictureData = visit.picture {
                        let jpegBytes = VisitPhotoCompression.encodedData(from: pictureData)?.count ?? pictureData.count
                        // XML stores photos as base64 (4 bytes per 3) plus picture/CDATA tags
                        estimatedSize += Int64((jpegBytes + 2) / 3 * 4) + 40
                    }
                }
                return estimatedSize
            } catch {
                print("Error calculating file size: \(error)")
                return 0
            }
        }
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
        
        // Filter by effective profile
        fetchRequest.predicate = ProfileManager.shared.visitProfilePredicate()
        
        // Sort by dateVisited
        let sortDescriptor = NSSortDescriptor(key: "dateVisited", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let profileLabel = profilesEnabled ? " (\(ProfileManager.shared.activeProfileName()))" : ""
        
        if type == "txt" {
            visits = "My Holy Places Visits\(profileLabel)\n Exported on \(dateFormatter.string(from: Date.init()))\n"
        } else {
            let exportStamp = ISO8601DateFormatter().string(from: Date())
            visits = "<?xml version=\"1.0\" encoding=\"utf-8\"?><Document><ExportDate>\(exportStamp)</ExportDate>"
            if profilesEnabled {
                visits.append("<Profile>\(xmlEscape(ProfileManager.shared.activeProfileName()))</Profile>")
            }
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
                guard let placeName = visit.holyPlace, let visited = visit.dateVisited else { continue }
                let commentsText = visit.comments ?? ""
                switch type {
                case "txt":
                    visits.append("\(placeName)\n")
                    visits.append("\(dateFormatter.string(from: visited))\n")
                    visits.append(commentsText)
                    if visit.isFavorite {
                        visits.append("\n⭐️ Favorite Visit")
                    }
                case "csv":
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateStyle = .short
                    let escapedComments = commentsText.replacingOccurrences(of: "\"", with: "\"\"")
                    visits.append("\(placeName),\(visit.type ?? ""),\(dateFormatter2.string(from: visited)),\"\(escapedComments)\"")
                default: // xml
                    visits.append("<Visit><holyPlace>\(xmlEscape(placeName))</holyPlace>")
                    visits.append("<type>\(xmlEscape(visit.type ?? ""))</type>")
                    visits.append("<dateVisited>\(xmlDateFormatter.string(from: visited))</dateVisited>")
                    visits.append("<comments>\(xmlCDATA(commentsText))</comments>")
                    visits.append("<isFavorite>\(visit.isFavorite)</isFavorite>")
                    
                    // Add photo if includePhotos is enabled and photo exists
                    if includePhotos.isOn, let pictureData = visit.picture {
                        if let exportData = VisitPhotoCompression.encodedData(from: pictureData) {
                            print("🔍 Export: Photo \(pictureData.count) → \(exportData.count) bytes for \(visit.holyPlace!)")
                            visits.append("<picture><![CDATA[\(exportData.base64EncodedString())]]></picture>")
                        } else {
                            print("❌ Export: Picture data is not a valid image - omitting photo for \(visit.holyPlace!)")
                            visits.append("<picture></picture>")
                        }
                    } else {
                        visits.append("<picture></picture>")
                    }
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
            if type == "xml" && includePhotos.isOn {
                let photoCount = searchResults.filter { $0.picture != nil }.count
                message.text = "Exported \(exportCount) visits with \(photoCount) photos to \(type) file."
            } else {
                message.text = "Exported \(exportCount) visits to \(type) file."
            }
            message.textColor = templeColor
            // Update visit count 
            ad.needsVisitRefresh = true
            ad.getVisits()
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt url: [URL]) {
        
        // Reset counters
        importCount = 0
        duplicates = 0
        photoImportCount = 0
        skippedInvalid = 0
        
        let fileURL = url[0]
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let parser = XMLParser(contentsOf: fileURL) else {
            let alert = UIAlertController(title: "Import Failure", message: "The selected file could not be read.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
            return
        }
        
        parser.delegate = self
        if parser.parse() {
            var message = photoImportCount > 0 ?
                "Successfully imported \(importCount) visits with \(photoImportCount) photos; \(duplicates) duplicate visits skipped" :
                "Successfully imported \(importCount) visits; \(duplicates) duplicate visits skipped"
            if skippedInvalid > 0 {
                message += "; \(skippedInvalid) visits skipped (missing place or date)"
            }
            let alert = UIAlertController(title: "Import Completed", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            ad.needsVisitRefresh = true
            ad.getVisits()
        } else {
            print("Data parsing aborted")
            var detail = "The XML file selected isn't formatted properly."
            if let error = parser.parserError {
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parser.lineNumber)")
                detail += " \(error.localizedDescription) (line \(parser.lineNumber))"
            }
            let alert = UIAlertController(title: "Import Failure", message: detail, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
        
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        eName = elementName
        currentText = ""
        if elementName == "Visit" {
            holyPlace = String()
            comments = String()
            visitDate = Date()
            visitDateIsValid = false
            hoursWorked = Double()
            sealings = Int16()
            endowments = Int16()
            initiatories = Int16()
            confirmations = Int16()
            baptisms = Int16()
            type = String()
            isFavorite = false
            pictureData = nil
            pictureBase64String = ""
        }
    }
    
    // foundCharacters of parser — XMLParser may deliver an element's text in multiple chunks.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
        if eName == "picture" {
            pictureBase64String += string
        }
    }
    
    // didEndElement of parser
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "holyPlace": holyPlace = value
        case "comments": comments = currentText
        case "dateVisited":
            if let date = parseImportedVisitDate(value) {
                visitDate = date
                visitDateIsValid = true
            } else {
                visitDateIsValid = false
                print("Import: could not parse dateVisited '\(value)'")
            }
        case "hoursWorked": hoursWorked = Double(value) ?? 0
        case "sealings": sealings = Int16(value) ?? 0
        case "endowments": endowments = Int16(value) ?? 0
        case "initiatories": initiatories = Int16(value) ?? 0
        case "confirmations": confirmations = Int16(value) ?? 0
        case "baptisms": baptisms = Int16(value) ?? 0
        case "type": type = value
        case "isFavorite": isFavorite = value.lowercased() == "true"
        case "picture":
            let base64 = pictureBase64String.trimmingCharacters(in: .whitespacesAndNewlines)
            if !base64.isEmpty {
                if let data = Data(base64Encoded: base64) {
                    pictureData = VisitPhotoCompression.encodedData(from: data) ?? data
                } else {
                    print("Import: failed to decode Base64 image data for visit: \(holyPlace)")
                }
            }
        default:
            break
        }
        currentText = ""
        eName = ""
        
        if elementName == "Visit" {
            if !visitDateIsValid || holyPlace.isEmpty {
                skippedInvalid += 1
                return
            }
            
            let context = getContext()
            
            // Check for old place names and apply date-aware renaming
            if !allPlaces.contains(where: { $0.templeName == holyPlace }) {
                for temple in allPlaces {
                    if let change = temple.nameChanges.first(where: { $0.oldName == holyPlace }) {
                        if let cutoff = change.changeDate, visitDate < cutoff {
                            // Visit predates the rename — preserve the historical name
                            print("📅 Imported visit kept as '\(holyPlace)' (visit date predates rename to \(temple.templeName))")
                        } else {
                            print("🛠 Imported visit renamed from \(holyPlace) to \(temple.templeName)")
                            holyPlace = temple.templeName
                        }
                        break
                    }
                }
            }
            
            // Check for duplicate before saving (same place on same day)
            do {
            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dateVisited == %@ && holyPlace == %@", visitDate as NSDate, holyPlace as String)
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
                    visit.year = ad.calendarYearString(for: visitDate)
                    visit.type = type
                    visit.shiftHrs = hoursWorked
                    visit.isFavorite = isFavorite
                    visit.picture = pictureData
                    visit.profileId = ProfileManager.shared.effectiveProfileId()
                    
                    // Count photos for import message
                    if pictureData != nil {
                        photoImportCount += 1
                        print("🔍 Import: Saved photo data, size: \(pictureData!.count) bytes for visit: \(holyPlace)")
                    }
                    
                    //save the object
                    do {
                        try context.save()
                    } catch let error as NSError  {
                        print("Could not save \(error), \(error.userInfo)")
                    } catch {}
                    //            print("Saving Visit completed")
                    importCount += 1
                    
                } else {
                    // Duplicate found - check if we should update with photo
                    let existingVisit = searchResults.first!
                    
                    // If existing visit doesn't have a photo but XML includes photo data, update it
                    if existingVisit.picture == nil && pictureData != nil {
                        print("🔍 Import: Updating existing visit with photo for: \(holyPlace)")
                        existingVisit.picture = pictureData
                        photoImportCount += 1
                        
                        // Save the updated visit
                        do {
                            try context.save()
                            print("🔍 Import: Successfully updated existing visit with photo data, size: \(pictureData!.count) bytes for visit: \(holyPlace)")
                        } catch let error as NSError {
                            print("Could not save updated visit \(error), \(error.userInfo)")
                        } catch {}
                        
                        // Count this as an import (photo update) rather than a duplicate
                        importCount += 1
                    } else {
                        // No photo update needed - count as duplicate
                        duplicates += 1
                    }
                }
            } catch {
                print("Error with request: \(error)")
            }
            
        }
    }

    /// New backups use `yyyy-MM-dd`. Older files used DateFormatter `.full`
    /// (e.g. "Sunday, October 19, 1980"), which is locale-dependent.
    private func parseImportedVisitDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let date = xmlDateFormatter.date(from: trimmed) {
            return Calendar.current.startOfDay(for: date)
        }
        // Same-device language as the original export
        if let date = legacyFullDateFormatter.date(from: trimmed) {
            return Calendar.current.startOfDay(for: date)
        }
        // English iPhone/iPad backups, even if this device's language differs
        if let date = legacyEnglishFullDateFormatter.date(from: trimmed) {
            return Calendar.current.startOfDay(for: date)
        }
        return nil
    }
    
    private func xmlEscape(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }
    
    private func xmlCDATA(_ string: String) -> String {
        let safe = string.replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>")
        return "<![CDATA[\(safe)]]>"
    }

    //MARK: - Navigation
    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
