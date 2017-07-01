//
//  MapVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 6/29/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {

    var mapCenter = CLLocationCoordinate2D()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.configureView()
        let button = UIBarButtonItem(title: "All", style: .plain, target: self, action: #selector(showAll(_:)))
//        let mapButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showAll(_:)))
        self.navigationItem.rightBarButtonItem = button
    }
    
    func showAll(_ sender: Any) {
        mapPoints.removeAll()
        for place in allPlaces {
            mapPoints.append(MapPoint(title: (place.templeName), coordinate: CLLocationCoordinate2D(latitude: (place.cllocation.coordinate.latitude), longitude: (place.cllocation.coordinate.longitude)), type: (place.templeType)))
        }
        mapView.addAnnotations(mapPoints)
        self.navigationItem.rightBarButtonItem?.title = nil
    }
    
    func configureView() {
        if self.mapView != nil {
            mapView.addAnnotations(mapPoints)
            mapCenter = mapPoints[0].coordinate
            mapView.setCenter(mapCenter, animated: false)
            mapView.selectAnnotation(mapPoints[0], animated: true)
            let mapCamera = MKMapCamera(lookingAtCenter: mapCenter, fromEyeCoordinate: mapCenter, eyeAltitude: 2000)
            mapView.setCamera(mapCamera, animated: false)
        }
    }

    func pinColor(type:String) -> UIColor {
        switch type {
        case "T":
            return UIColor.darkRed()
        case "H":
            return UIColor.darkLimeGreen()
        case "C":
            return UIColor.darkOrange()
        case "V":
            return UIColor.strongYellow()
        default:
            return UIColor.lead()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKPinAnnotationView
        guard let annotation = annotation as? MapPoint else {return nil}
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.title!) as? MKPinAnnotationView {
            view = dequeuedView
        } else { //make a new view
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotation.title)
        }
        view.isEnabled = true
        view.canShowCallout = true
        view.pinTintColor = pinColor(type: annotation.type)
        return view
    }

    // MARK: - Navigation



}
