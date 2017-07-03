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
        // Add Show All button on right side of navigation bar
        let button = UIBarButtonItem(title: "Show All", style: .plain, target: self, action: #selector(showAll(_:)))
        let options = ["Map", "Sat"]
        self.navigationItem.rightBarButtonItem = button
        let mapOptions = UISegmentedControl(items: options)
        mapOptions.selectedSegmentIndex = 0
        mapOptions.addTarget(self, action: #selector(changeMap(_:)), for: .valueChanged)
        let attr = NSDictionary(object: UIFont(name: "Baskerville", size: 14.0)!, forKey: NSFontAttributeName as NSCopying)
        mapOptions.setTitleTextAttributes(attr as? [AnyHashable : Any], for: .normal)
        self.navigationItem.titleView = mapOptions
        // Show the user current location
        mapView.showsUserLocation = true
    }
    
    func changeMap(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            mapView.mapType = .satellite
        default:
            mapView.mapType = .standard
        }
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
            let mapCamera = MKMapCamera(lookingAtCenter: mapCenter, fromEyeCoordinate: mapCenter, eyeAltitude: 4000)
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
        // Right accessory view
        //        let image = UIImage(#imageLiteral(resourceName: "nav"))
        let button = UIButton(type: .custom)
        button.setTitle("⤴️", for: .normal)
        //        button.setImage(UIImage.init(named: "nav"), for: UIControlState())
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        view.rightCalloutAccessoryView = button
        view.isEnabled = true
        view.canShowCallout = true
        view.pinTintColor = pinColor(type: annotation.type)
        return view
    }

    // MARK: - Navigation

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let placemark = MKPlacemark(coordinate: view.annotation!.coordinate, addressDictionary: nil)
        // The map item is the place location
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = (view.annotation?.title)!
        print(view.annotation?.title as Any)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }

}
