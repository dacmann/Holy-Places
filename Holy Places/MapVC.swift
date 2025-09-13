//
//  MapVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 6/29/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import MapKit

class ResizablePinAnnotationView: MKPinAnnotationView {
    var baseSize: CGFloat = 30.0
    var minSize: CGFloat = 18.0
    var maxSize: CGFloat = 40.0
    
    func updateSize(for zoomLevel: Double) {
        // Calculate size based on zoom level
        // Higher altitude (more zoomed out) = smaller pins
        // Lower altitude (more zoomed in) = larger pins
        
        // Use a more reasonable range for the app's zoom levels
        // The app uses altitudes from ~1000 (very zoomed in) to ~10000000 (very zoomed out)
        let minAltitude: Double = 1000
        let maxAltitude: Double = 10000000
        
        let normalizedZoom = max(0, min(1, (zoomLevel - minAltitude) / (maxAltitude - minAltitude)))
        let size = minSize + (maxSize - minSize) * (1 - normalizedZoom)
        
        // Update the frame size
        let newSize = max(minSize, min(maxSize, size))
        self.frame = CGRect(x: 0, y: 0, width: newSize, height: newSize)
        
        // Center the pin properly
        self.centerOffset = CGPoint(x: 0, y: -newSize/2)
    }
}

class MapVC: UIViewController, MKMapViewDelegate {

    var placeName = String()
    var optionSelected = false
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var mapPlaces: [Temple] = []
    var alreadyVisitedTab = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add Show Options button on right side of navigation bar
        let button = UIBarButtonItem(title: "Filters", style: .plain, target: self, action: #selector(options(_:)))
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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        if let navigationController = self.navigationController {
            if navigationController.viewControllers.first == self && !alreadyVisitedTab {
                optionSelected = true
                if ad.coordinateOfUser != nil {
                    mapCenter = CLLocationCoordinate2D(latitude: ad.coordinateOfUser.coordinate.latitude, longitude: ad.coordinateOfUser.coordinate.longitude)
                } else {
                    // default to Temple Square
                    mapCenter = CLLocationCoordinate2D(latitude: 40.7707425, longitude: -111.8932596)
                }
                
                mapZoomLevel = 10000000
                alreadyVisitedTab = true
            }
        }
        self.configureView()

        if optionSelected {
            mapThePlaces()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // save Place updates on main thread
        if ad.newFileParsed {
            ad.storePlaces()
            ad.savePlaceVersion()
            checkedForUpdate = Date()
            ad.newFileParsed = false
        }
        // Pop message when update has occured
        if changesDate != "" {
            var changesMsg = changesMsg1
            if changesMsg2 != ""
            {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg2)
            }
            if changesMsg3 != ""
            {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg3)
            }
            let alert = UIAlertController(title: changesDate + " Update", message: changesMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Handle OK (cancel) Logic here")
                // clear out message now that it has been presented
                changesDate = ""
            }))
            self.present(alert, animated: true)
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
            return templeColor
            //return UIColor.purple
        case "H":
            return historicalColor
        case "A":
            return announcedColor
        case "C":
            return constructionColor
        case "V":
            return visitorCenterColor
        default:
            return defaultColor
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "pin"
        var view : ResizablePinAnnotationView
        guard let annotation = annotation as? MapPoint else {return nil}
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ResizablePinAnnotationView {
            view = dequeuedView
        } else { //make a new view
            view = ResizablePinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
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
//        view.image
        view.pinTintColor = pinColor(type: annotation.type)
        annotation.title = " "
        
        // Set initial size based on current zoom level
        view.updateSize(for: mapView.camera.altitude)
        
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Update pin sizes when zoom level changes
        let currentAltitude = mapView.camera.altitude
        mapZoomLevel = currentAltitude
        
        // Update all visible annotation views
        for annotation in mapView.annotations {
            if let annotationView = mapView.view(for: annotation) as? ResizablePinAnnotationView {
                annotationView.updateSize(for: currentAltitude)
            }
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
            places = mapPlaces
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
                        if let myTabBar = ad.window?.rootViewController as? UITabBarController {
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
