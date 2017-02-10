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
    
    var cllocation: CLLocation
    var distance : Double?
    var coordinate : CLLocationCoordinate2D

    init(Name:String!, Address:String!, Snippet:String!, CityState:String!, Country:String!, Phone:String!, Latitude:Double!, Longitude:Double!, Order:Int16, PictureURL:String!, SiteURL:String!, Type:String!){
        self.templeName = Name
        self.templeAddress = Address
        self.templeSnippet = Snippet
        self.templeCityState = CityState
        self.templeCountry = Country
        self.templePhone = Phone
        self.templeLatitude = Latitude
        self.templeLongitude = Longitude
        self.templeOrder = Order
        self.templePictureURL = PictureURL
        self.templeType = Type
        self.cllocation = CLLocation(latitude: Latitude!, longitude: Longitude!)
        self.coordinate = CLLocationCoordinate2D(latitude: Latitude!, longitude: Longitude!)
        //self.distance = distance
        self.templeSiteURL = SiteURL
    }
    
    
    // Function to calculate the distance from given location.
    func calculateDistance(fromLocation: CLLocation?) {
        distance = cllocation.distance(from: fromLocation!)
    }
}
