//
//  MapVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 6/29/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import MapKit

class ResizableMarkerAnnotationView: MKMarkerAnnotationView {
    var minScale: CGFloat = 0.2
    var maxScale: CGFloat = 1.0
    
    func updateSize(for zoomLevel: Double) {
        // Use transform to scale the marker based on zoom level
        // Higher altitude (more zoomed out) = smaller markers
        // Lower altitude (more zoomed in) = larger markers
        
        let minAltitude: Double = 1000
        let maxAltitude: Double = 25000000  // ~25,000 km - markers stay larger longer when zooming out
        
        // Calculate normalized zoom (0 = zoomed in, 1 = zoomed out)
        let normalizedZoom = max(0, min(1, (zoomLevel - minAltitude) / (maxAltitude - minAltitude)))
        
        // Calculate scale (inverted: zoomed out = smaller)
        let scale = maxScale - (normalizedZoom * (maxScale - minScale))
        
        // Apply transform to scale the marker
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        // Always show all markers
        self.displayPriority = .required
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        transform = .identity
    }
}

class MapVC: UIViewController, MKMapViewDelegate {

    var placeName = String()
    var optionSelected = false
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var mapPlaces: [Temple] = []
    var alreadyVisitedTab = false
    var fromPlaceDetail = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    private var markerSizeDisplayLink: CADisplayLink?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color to match system background for dark mode
        view.backgroundColor = UIColor.systemBackground

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
                // First time accessing map tab
                optionSelected = true
                if ad.coordinateOfUser != nil {
                    mapCenter = CLLocationCoordinate2D(latitude: ad.coordinateOfUser.coordinate.latitude, longitude: ad.coordinateOfUser.coordinate.longitude)
                } else {
                    // default to Temple Square
                    mapCenter = CLLocationCoordinate2D(latitude: 40.7707425, longitude: -111.8932596)
                }
                mapZoomLevel = 3000000  // 3000km - reasonable for showing all places
                // Don't set alreadyVisitedTab yet - do it after configureView check
            } else if navigationController.viewControllers.first == self && alreadyVisitedTab {
                // Returning to map tab - rebuild places but keep current zoom level
                mapPoints.removeAll()
                mapView.removeAnnotations(mapView.annotations)
                optionSelected = true
                // Clear any selected annotation
                if let selectedAnnotation = mapView.selectedAnnotations.first {
                    mapView.deselectAnnotation(selectedAnnotation, animated: false)
                }
            }
        }
        
        // Handle coming from place detail
        if fromPlaceDetail {
            tabBarController?.tabBar.isHidden = true
            // Set background color to match system background for dark mode
            view.backgroundColor = UIColor.systemBackground
            mapZoomLevel = 2000  // Neighborhood level zoom
        } else {
            tabBarController?.tabBar.isHidden = false
            // Reset to default background when tab bar is shown
            view.backgroundColor = UIColor.systemBackground
        }
        
        if optionSelected {
            mapThePlaces()
        }
        
        // Only set region when coming from place detail or first time
        if fromPlaceDetail || (navigationController?.viewControllers.first == self && !alreadyVisitedTab) {
            self.configureView()
            alreadyVisitedTab = true  // Set this AFTER configureView is called
        }
        
        // Update marker sizes after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateAllMarkerSizes()
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
        
        // If coming from place detail, don't rebuild all places - keep single selection
        if !fromPlaceDetail {
            mapView.removeAnnotations(mapPoints)
            mapPoints.removeAll()                                                                                                                                                                                                   
            for place in filteredPlaces {
                mapPoints.append(MapPoint(title: (place.templeName), coordinate: CLLocationCoordinate2D(latitude: (place.cllocation.coordinate.latitude), longitude: (place.cllocation.coordinate.longitude)), type: (place.templeType)))
            }
            mapView.addAnnotations(mapPoints)
            // Clear any selected annotation when rebuilding all places
            if let selectedAnnotation = mapView.selectedAnnotations.first {
                mapView.deselectAnnotation(selectedAnnotation, animated: false)
            }
            
            // Force update marker sizes after annotations are added
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateAllMarkerSizes()
            }
        }
        
        // Only select annotation if coming from place detail
        if fromPlaceDetail, let found = mapPoints.firstIndex(where:{$0.name == mapPoint.name}) {
            mapView.selectAnnotation(mapPoints[found], animated: true)
        }
    }
    
    func configureView() {
        if self.mapView != nil {
            // Set region FIRST (without animation) so markers are created at correct size
            let region = MKCoordinateRegion(center: mapCenter, latitudinalMeters: mapZoomLevel, longitudinalMeters: mapZoomLevel)
            mapView.setRegion(region, animated: false)
            
            mapView.addAnnotations(mapPoints)
            mapView.setCenter(mapCenter, animated: false)
            // Determine the current 
            if let found = mapPoints.firstIndex(where:{$0.name == mapPoint.name}) {
                mapView.selectAnnotation(mapPoints[found], animated: true)
            }
            
            // Force update marker sizes after a brief delay to ensure they're rendered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateAllMarkerSizes()
            }
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
        
        let identifier = "marker"
        var view : ResizableMarkerAnnotationView
        guard let annotation = annotation as? MapPoint else {return nil}
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ResizableMarkerAnnotationView {
            view = dequeuedView
        } else { //make a new view
            view = ResizableMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
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
        view.markerTintColor = pinColor(type: annotation.type)
        view.glyphImage = nil  // Use default glyph
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
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        startMarkerSizeUpdates()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        stopMarkerSizeUpdates()
        updateAllMarkerSizes()
        // Extra pass for annotations that may have just appeared at edges
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.updateAllMarkerSizes()
        }
    }
    
    private func startMarkerSizeUpdates() {
        guard markerSizeDisplayLink == nil else { return }
        markerSizeDisplayLink = CADisplayLink(target: self, selector: #selector(updateAllMarkerSizes))
        markerSizeDisplayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopMarkerSizeUpdates() {
        markerSizeDisplayLink?.invalidate()
        markerSizeDisplayLink = nil
    }
    
    @objc func updateAllMarkerSizes() {
        // Update marker sizes based on current zoom level
        let currentAltitude = mapView.camera.altitude
        
        // Update only MapPoint annotation views (skip user location, etc.)
        for annotation in mapView.annotations.compactMap({ $0 as? MapPoint }) {
            if let annotationView = mapView.view(for: annotation) as? ResizableMarkerAnnotationView {
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
                    // Navigate directly to PlaceDetailVC from map
                    detailItem = place
                    mapZoomLevel = mapView.camera.altitude
                    
                    // Create PlaceDetailVC instance directly
                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    if let placeDetailVC = storyBoard.instantiateViewController(withIdentifier: "PlaceDetail") as? PlaceDetailVC {
                        placeDetailVC.fromMap = true
                        self.navigationController?.pushViewController(placeDetailVC, animated: true)
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopMarkerSizeUpdates()
        
        // Show tab bar when leaving map (in case it was hidden)
        tabBarController?.tabBar.isHidden = false
        
        // Reset the flag for next time
        fromPlaceDetail = false
    }

}
