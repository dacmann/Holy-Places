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

    var placeName = String()
    var optionSelected = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var mapPlaces: [Temple] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add Show Options button on right side of navigation bar
        let button = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(options(_:)))
        self.navigationItem.rightBarButtonItem = button
        
        // Create Map or Aerial control
        let options = ["Standard", "Aerial"]
        let mapOptions = UISegmentedControl(items: options)
        mapOptions.selectedSegmentIndex = 0
        mapOptions.addTarget(self, action: #selector(changeMap(_:)), for: .valueChanged)
        let attr = NSDictionary(object: UIFont(name: "Baskerville", size: 14.0)!, forKey: NSAttributedString.Key.font as NSCopying)
        mapOptions.setTitleTextAttributes(attr as? [AnyHashable : Any] as? [NSAttributedString.Key : Any], for: .normal)
        self.navigationItem.titleView = mapOptions
        
        // Show the user current location
        mapView.showsUserLocation = true
        
        // Change the font and color for the navigation Bar text
        let barbuttonFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)
        if #available(iOS 13.0, *) {
            let style = UINavigationBarAppearance()
            style.configureWithDefaultBackground()
            style.backgroundColor = .white
            style.buttonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor.ocean()]
            style.doneButtonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor.ocean()]
            style.titleTextAttributes = [
                .foregroundColor : UIColor.ocean(), // Navigation bar title color
                .font : navbarFont // Navigation bar title font
            ]
            navigationController?.navigationBar.standardAppearance = style
            
        } else {
            // Fallback on earlier versions
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor.ocean()], for: UIControl.State.normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barbuttonFont, NSAttributedString.Key.foregroundColor:UIColor.ocean()], for: UIControl.State.highlighted)
            
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: navbarFont, NSAttributedString.Key.foregroundColor:UIColor.lead()]
            UINavigationBar.appearance().tintColor = UIColor.ocean()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {

        if let navigationController = self.navigationController {
            if navigationController.viewControllers.first == self {
                optionSelected = true
                if appDelegate.coordinateOfUser != nil {
                    mapCenter = CLLocationCoordinate2D(latitude: appDelegate.coordinateOfUser.coordinate.latitude, longitude: appDelegate.coordinateOfUser.coordinate.longitude)
                } else {
                    // default to Temple Square
                    mapCenter = CLLocationCoordinate2D(latitude: 40.7707425, longitude: -111.8932596)
                }
                
                mapZoomLevel = 10000000
            }
        }
        self.configureView()

        if optionSelected {
            mapThePlaces()
        }
    }
    
    @objc func changeMap(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            mapView.mapType = .satellite
        default:
            mapView.mapType = .standard
        }
    }
    
    func mapThePlaces() {
        
        // Filter the request
        switch mapFilterRow {
        case 0:
            mapPlaces = allPlaces
        case 1:
            // Active Temples
            mapPlaces = activeTemples
        case 2:
            // Historical Sites
            mapPlaces = historical
        case 3:
            // Visitors' Centers
            mapPlaces = visitors
        case 4:
            // Under Construction
            mapPlaces = construction
        case 5:
            // Announced
            mapPlaces = announced
        default:
            // All Temples
            mapPlaces = allTemples
        }
        
        // Filter the places by Visited filter
        let filteredPlaces = mapPlaces.filter { place in
            let categoryMatch = (mapVisitedFilter == 0) || (mapVisitedFilter == 1 && visits.contains(place.templeName)) || (mapVisitedFilter == 2 && !(visits.contains(place.templeName)))
            return categoryMatch
        }
        
        mapView.removeAnnotations(mapPoints)
        mapPoints.removeAll()                                                                                                                                                                                                   
        for place in filteredPlaces {
            mapPoints.append(MapPoint(title: (place.templeName), coordinate: CLLocationCoordinate2D(latitude: (place.cllocation.coordinate.latitude), longitude: (place.cllocation.coordinate.longitude)), type: (place.templeType)))
        }
        mapView.addAnnotations(mapPoints)
        if let found = mapPoints.firstIndex(where:{$0.name == mapPoint.name}) {
            mapView.selectAnnotation(mapPoints[found], animated: true)
        }
    }
    
    func configureView() {
        if self.mapView != nil {
            mapView.addAnnotations(mapPoints)
            mapView.setCenter(mapCenter, animated: false)
            // Determine the current 
            if let found = mapPoints.firstIndex(where:{$0.name == mapPoint.name}) {
                mapView.selectAnnotation(mapPoints[found], animated: true)
            }
            let mapCamera = MKMapCamera(lookingAtCenter: mapCenter, fromEyeCoordinate: mapCenter, eyeAltitude: mapZoomLevel)
            mapView.setCamera(mapCamera, animated: false)
        }
    }

    func pinColor(type:String) -> UIColor {
        switch type {
        case "T":
            return UIColor.darkRed()
        case "H":
            return UIColor.darkLimeGreen()
        case "A":
            return UIColor.brown
        case "C":
            return UIColor.darkOrange()
        case "V":
            return UIColor.strongYellow()
        default:
            return UIColor.lead()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "pin"
        var view : MKPinAnnotationView
        guard let annotation = annotation as? MapPoint else {return nil}
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            view = dequeuedView
        } else { //make a new view
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        // Left accessory view
        let leftAccessory = UIButton(frame: CGRect(x: 0,y: 0,width: 120,height: 38))
        leftAccessory.setTitle(annotation.name, for: .normal)
        leftAccessory.titleLabel?.numberOfLines = 2
        leftAccessory.titleLabel?.minimumScaleFactor = 0.5
        leftAccessory.titleLabel?.adjustsFontSizeToFitWidth = true
        leftAccessory.setTitleColor(pinColor(type: annotation.type), for: .normal)
        leftAccessory.titleLabel?.font = UIFont(name: "Baskerville", size: 16)
        view.leftCalloutAccessoryView = leftAccessory
        
        // Right accessory view
        let rightAccessory = UIButton(type: .custom)
        rightAccessory.setTitle("⤴️", for: .normal)
        rightAccessory.frame = CGRect(x: 0, y: 0, width: 24, height: 30)
        view.rightCalloutAccessoryView = rightAccessory
        
        // Additional settings for the annotation
        view.isEnabled = true
        view.canShowCallout = true
        view.pinTintColor = pinColor(type: annotation.type)
        annotation.title = " "
        return view
    }

    // MARK: - Navigation
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let found = allPlaces.firstIndex(where:{$0.templeLatitude == view.annotation?.coordinate.latitude}) {
            let place = allPlaces[found]
//            print(place.templeName)
            placeName = place.templeName
            mapPoint = MapPoint(title: placeName, coordinate: view.annotation!.coordinate, type: place.templeType)
        }
    }

    @objc func options(_ sender: Any) {
        optionSelected = true
        mapZoomLevel = mapView.camera.altitude
        self.performSegue(withIdentifier: "viewMapOptions", sender: self)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == view.rightCalloutAccessoryView {
            // Launch Apple Maps with the selected Map location
            let placemark = MKPlacemark(coordinate: view.annotation!.coordinate, addressDictionary: nil)
            // The map item is the place location
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = placeName
            let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        } else {
            // Clicked on Place Name to bring up Details
            // Switch Places tab data to current map data
//            places = mapPlaces - Was causing crashes - Not sure why this was added to begin with
            placeFilterRow = mapFilterRow
            // Find details for selected pin
            if let found = places.firstIndex(where:{$0.templeLatitude == view.annotation?.coordinate.latitude}) {
                print(found)
                let place = places[found]
                selectedPlaceRow = found
//                print(place.templeName)
                placeName = place.templeName
//                print(places[selectedPlaceRow].templeName)
                if control == view.leftCalloutAccessoryView {
                    // Navigate back to the Detail Page but swap out the details with the selected Place from the Map
                    detailItem = place
                    // Save the current Camera altitude
                    mapZoomLevel = mapView.camera.altitude
                    if self.navigationController?.popViewController(animated: true) == nil {
                        // navigate to the place details
                        if let myTabBar = appDelegate.window?.rootViewController as? UITabBarController {
                            myTabBar.selectedIndex = 1
                            let nvc = myTabBar.selectedViewController as? UINavigationController
                            let vc = nvc?.viewControllers.first as? TableViewController
                            nvc?.popToRootViewController(animated: false)
                            _ = vc!.openForPlace(shortcutIdentifier: .ViewPlace)
                        }
                    }
                }
            }
        }
    }

}
