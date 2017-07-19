//
//  MapPoint.swift
//  Holy Places
//
//  Created by Derek Cordon on 6/29/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import MapKit
import UIKit

class MapPoint: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var type: String
    var name: String?
    
    init(title: String, coordinate: CLLocationCoordinate2D, type: String) {
        self.title = title
        self.coordinate = coordinate
        self.type = type
        self.name = title
    }
}
