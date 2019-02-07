//
//  Temples.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreLocation

class Temple: NSObject {
    
    var templeName = String()
    var templeAddress = String()
    var templeSnippet = String()
    var templeCityState = String()
    var templeCountry = String()
    var templePhone = String()
    var templeLatitude = Double()
    var templeLongitude = Double()
    var templeOrder = Int16()
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

    init(Name:String!, Address:String!, Snippet:String!, CityState:String!, Country:String!, Phone:String!, Latitude:Double!, Longitude:Double!, Order:Int16, PictureURL:String!, SiteURL:String!, Type:String!, ReaderView:Bool, InfoURL:String, SqFt:Int32, FHCode:String?){
        templeName = Name
        templeAddress = Address
        templeSnippet = Snippet
        templeCityState = CityState
        templeCountry = Country
        templePhone = Phone
        templeLatitude = Latitude
        templeLongitude = Longitude
        templeOrder = Order
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
