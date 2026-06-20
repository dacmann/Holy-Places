//
//  Temples.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreLocation

// Represents a single name change event for a place, carrying the historical
// name, the date the new name took effect, and an optional historical image URL.
struct NameChange: Codable {
    let oldName: String
    /// The first day the new name applies. Visits dated before this date keep
    /// the historical name. nil means the rename applies to all dates.
    let changeDate: Date?
    /// URL of the place image that was valid under the old name.
    let oldImageURL: String?
    /// Downloaded image data cached locally for offline display.
    var oldImageData: Data?
}

class Temple: NSObject {
    
    var templeId = String()
    var templeName = String()
    var templeAddress = String()
    var templeSnippet = String()
    var templeCityState = String()
    var templeCountry = String()
    var templePhone = String()
    var templeLatitude = Double()
    var templeLongitude = Double()
    var templeOrder = Int16()
    var templeAnnouncedDate: Date?
    var templePictureURL = String()
    var templeType = String()
    var templeSiteURL = String()
    var readerView = Bool()
    var infoURL = String?("")
    var templeSqFt = Int32?(0)
    var fhCode = String?("")
    
    var cllocation: CLLocation
    var distance : Double?
    var coordinate : CLLocationCoordinate2D

    /// Rich rename history with optional change dates and historical images.
    var nameChanges: [NameChange] = []

    /// Legacy flat list derived from nameChanges — kept so existing callers compile unchanged.
    var oldNames: [String] {
        return nameChanges.map { $0.oldName }
    }

    /// Returns the name this place was known by at the given visit date.
    func effectiveName(for date: Date) -> String {
        for change in nameChanges {
            if let cutoff = change.changeDate, date < cutoff {
                return change.oldName
            }
        }
        return templeName
    }

    /// Returns the NameChange whose oldName matches visit.holyPlace AND whose
    /// changeDate is after the visit date (meaning this visit should use the historical name/image).
    func applicableNameChange(for holyPlace: String, visitDate: Date) -> NameChange? {
        return nameChanges.first {
            $0.oldName == holyPlace &&
            ($0.changeDate.map { visitDate < $0 } ?? false)
        }
    }

    init(Id:String = "", Name:String!, Address:String!, Snippet:String!, CityState:String!, Country:String!, Phone:String!, Latitude:Double!, Longitude:Double!, Order:Int16, AnnouncedDate: Date?, PictureURL:String!, SiteURL:String!, Type:String!, ReaderView:Bool, InfoURL:String, SqFt:Int32, FHCode:String?) {
        templeId = Id
        templeName = Name
        templeAddress = Address
        templeSnippet = Snippet
        templeCityState = CityState
        templeCountry = Country
        templePhone = Phone
        templeLatitude = Latitude
        templeLongitude = Longitude
        templeOrder = Order
        templeAnnouncedDate = AnnouncedDate
        templePictureURL = PictureURL
        templeType = Type
        cllocation = CLLocation(latitude: Latitude!, longitude: Longitude!)
        coordinate = CLLocationCoordinate2D(latitude: Latitude!, longitude: Longitude!)
        templeSiteURL = SiteURL
        readerView = ReaderView
        infoURL = InfoURL
        templeSqFt = SqFt
        fhCode = FHCode
    }
    
    
    // Function to calculate the distance from given location.
    func calculateDistance(fromLocation: CLLocation?) {
        distance = cllocation.distance(from: fromLocation!)
    }
}
