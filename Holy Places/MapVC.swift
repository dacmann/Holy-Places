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
        // Don't reset transform — viewFor will call updateSize with the correct altitude,
        // and resetting to .identity causes a visible full-size flash on reuse.
    }
}

class MapVC: UIViewController, MKMapViewDelegate {

    var placeName = String()
    var optionSelected = false
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var mapPlaces: [Temple] = []
    var alreadyVisitedTab = false
    var fromPlaceDetail = false
    
    // MARK: - Timeline state
    var timelineBarButtonItem: UIBarButtonItem?
    var timelineContainerView: UIView?
    var timelineSlider: UISlider?
    var timelineDateLabel: UILabel?
    var timelinePlayButton: UIButton?
    var timelinePrevButton: UIButton?
    var timelineNextButton: UIButton?
    var isTimelineVisible = false
    var timelineEndDate: Date?
    var isTimelinePlaying = false
    var timelineTimer: Timer?
    var timelineMinDate: Date?
    var timelineMaxDate: Date?
    var sortedDedicationDates: [Date] = []
    var sortedDedicationYears: [Int] = []
    var savedMapFilterRow = Int()
    var savedMapVisitedFilter = Int()
    private var postRebuildSizeTimer: Timer?
    var timelineCountBadge: UILabel?
    private var savedTabBarStandardAppearance: UITabBarAppearance?
    private var savedTabBarScrollEdgeAppearance: UITabBarAppearance?

    @IBOutlet weak var mapView: MKMapView!
    
    private var markerSizeDisplayLink: CADisplayLink?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extend the map edge-to-edge under the nav bar and tab bar
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        
        // Set background color to match system background for dark mode
        view.backgroundColor = UIColor.systemBackground

        let navBarFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let navBarAttrs: [NSAttributedString.Key: Any] = [.font: navBarFont]

        // Add Show Options button on right side of navigation bar
        let button = UIBarButtonItem(title: "Filters", style: .plain, target: self, action: #selector(options(_:)))
        button.setTitleTextAttributes(navBarAttrs, for: .normal)
        button.setTitleTextAttributes(navBarAttrs, for: .highlighted)
        self.navigationItem.rightBarButtonItem = button
        
        // Add Timeline button on left side of navigation bar (always enabled)
        let tlButton = UIBarButtonItem(title: "Timeline", style: .plain, target: self, action: #selector(timelineButtonTapped(_:)))
        tlButton.setTitleTextAttributes(navBarAttrs, for: .normal)
        tlButton.setTitleTextAttributes(navBarAttrs, for: .highlighted)
        self.navigationItem.leftBarButtonItem = tlButton
        timelineBarButtonItem = tlButton
        
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
        
        setupTimelineOverlay()
        registerAppearanceChangeHandler()
    }
    
    // MARK: - Timeline overlay setup
    
    func setupTimelineOverlay() {
        // Shadow wrapper — clear background so the shadow renders against the blur inside
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true
        container.layer.cornerRadius = 14
        container.layer.cornerCurve = .continuous
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.22
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        mapView.addSubview(container)

        // Frosted-glass background — added first so it sits behind buttons/slider
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.layer.cornerRadius = 14
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        blurView.alpha = 0.72
        blurView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blurView)

        // Play/Pause button
        let playBtn = UIButton(type: .system)
        playBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)), for: .normal)
        playBtn.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        playBtn.translatesAutoresizingMaskIntoConstraints = false
        playBtn.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
        container.addSubview(playBtn)
        
        // Previous year button
        let prevBtn = UIButton(type: .system)
        prevBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)), for: .normal)
        prevBtn.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        prevBtn.translatesAutoresizingMaskIntoConstraints = false
        prevBtn.addTarget(self, action: #selector(prevYearTapped), for: .touchUpInside)
        container.addSubview(prevBtn)
        
        // Slider
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchBegan(_:)), for: .touchDown)
        // Set a placeholder thumb so UISlider knows the thumb dimensions before the
        // timeline is first shown. All year thumbs are the same size (4 digits, same font),
        // so this prevents the layout-offset jump on first reveal.
        let placeholderThumb = makeThumbImage(year: 1877)
        slider.setThumbImage(placeholderThumb, for: .normal)
        slider.setThumbImage(placeholderThumb, for: .highlighted)
        container.addSubview(slider)
        
        // Next year button
        let nextBtn = UIButton(type: .system)
        nextBtn.setImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)), for: .normal)
        nextBtn.tintColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.addTarget(self, action: #selector(nextYearTapped), for: .touchUpInside)
        container.addSubview(nextBtn)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -12),
            container.heightAnchor.constraint(equalToConstant: 56),

            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            playBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            playBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            playBtn.widthAnchor.constraint(equalToConstant: 44),
            playBtn.heightAnchor.constraint(equalToConstant: 44),
            
            prevBtn.leadingAnchor.constraint(equalTo: playBtn.trailingAnchor, constant: 2),
            prevBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            prevBtn.widthAnchor.constraint(equalToConstant: 44),
            prevBtn.heightAnchor.constraint(equalToConstant: 44),
            
            slider.leadingAnchor.constraint(equalTo: prevBtn.trailingAnchor, constant: 0),
            slider.trailingAnchor.constraint(equalTo: nextBtn.leadingAnchor, constant: 0),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            nextBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6),
            nextBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nextBtn.widthAnchor.constraint(equalToConstant: 44),
            nextBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        timelineContainerView = container
        timelineSlider = slider
        timelinePlayButton = playBtn
        timelinePrevButton = prevBtn
        timelineNextButton = nextBtn
        
        // Count badge — circle below the left end of the timeline bar
        let badge = UILabel()
        badge.font = UIFont(name: "Baskerville", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.isHidden = true
        badge.layer.cornerRadius = 26
        badge.layer.masksToBounds = true
        badge.backgroundColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        mapView.addSubview(badge)
        
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 8),
            badge.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            badge.widthAnchor.constraint(equalToConstant: 52),
            badge.heightAnchor.constraint(equalToConstant: 52),
        ])
        
        timelineCountBadge = badge
    }
    
    func makeThumbImage(year: Int) -> UIImage {
        let text = "\(year)"
        let font = UIFont(name: "Baskerville", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        let isDark = traitCollection.userInterfaceStyle == .dark
        // Light mode: white text on blue pill; dark mode: dark navy text on lighter blue pill
        let textColor: UIColor = isDark
            ? UIColor(red: 0.05, green: 0.10, blue: 0.30, alpha: 1)
            : UIColor(red: 0.92, green: 0.95, blue: 1.00, alpha: 1)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let hPad: CGFloat = 12
        let vPad: CGFloat = 7
        let size = CGSize(width: textSize.width + hPad * 2, height: textSize.height + vPad * 2)
        let fillColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            fillColor.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.height / 2).fill()
            let textRect = CGRect(x: hPad, y: vPad, width: textSize.width, height: textSize.height)
            (text as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
    
    private func registerAppearanceChangeHandler() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: MapVC, _: UITraitCollection) in
            if let endDate = self.timelineEndDate {
                self.updateDateLabel(for: endDate)
            }
            if let badge = self.timelineCountBadge, let text = badge.text, let count = Int(text) {
                self.updateCountBadge(count: count)
            }
        }
    }
    
    func applyThumbImage(year: Int) {
        let img = makeThumbImage(year: year)
        timelineSlider?.setThumbImage(img, for: .normal)
        timelineSlider?.setThumbImage(img, for: .highlighted)
    }
    
    // MARK: - Timeline button state
    
    func updateTimelineButtonState() {
        // Button is always available except when viewing a single place from detail
        timelineBarButtonItem?.isEnabled = !fromPlaceDetail
        if fromPlaceDetail {
            hideTimeline()
        }
    }
    
    func precomputeTimelineDates() {
        let dates = activeTemples.compactMap { $0.templeDedicationDate }.sorted()
        guard !dates.isEmpty else { return }
        sortedDedicationDates = dates
        timelineMinDate = dates.first
        timelineMaxDate = dates.last
        // Build sorted unique years for threshold detection
        var seen = Set<Int>()
        sortedDedicationYears = dates.compactMap { d -> Int? in
            let y = dedicationYear(from: d)
            return seen.insert(y).inserted ? y : nil
        }
    }
    
    func dedicationYear(from date: Date) -> Int {
        return Calendar.current.component(.year, from: date)
    }
    
    func updateCountBadge(count: Int) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        timelineCountBadge?.textColor = isDark
            ? UIColor(red: 0.05, green: 0.10, blue: 0.30, alpha: 1)
            : UIColor(red: 0.92, green: 0.95, blue: 1.00, alpha: 1)
        timelineCountBadge?.backgroundColor = UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue
        timelineCountBadge?.text = "\(count)"
        timelineCountBadge?.isHidden = !isTimelineVisible
    }
    
    @objc func timelineButtonTapped(_ sender: Any) {
        if isTimelineVisible {
            hideTimeline()
        } else {
            showTimeline()
        }
    }
    
    func showTimeline() {
        // Save current filter state and switch to Active Temples / All scope
        savedMapFilterRow = mapFilterRow
        savedMapVisitedFilter = mapVisitedFilter
        mapFilterRow = 1
        mapVisitedFilter = 0
        
        precomputeTimelineDates()
        guard let minDate = timelineMinDate, timelineMaxDate != nil else { return }
        
        isTimelineVisible = true
        timelineEndDate = minDate
        timelineSlider?.value = 0
        timelineContainerView?.isHidden = false
        updateDateLabel(for: minDate)
        mapThePlaces()
    }
    
    func hideTimeline() {
        guard isTimelineVisible else { return }
        stopTimelinePlayback()
        isTimelineVisible = false
        timelineEndDate = nil
        timelineContainerView?.isHidden = true
        timelineCountBadge?.isHidden = true
        timelinePlayButton?.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)), for: .normal)
        // Revert to All Holy Places on dismiss
        mapFilterRow = 0
        mapVisitedFilter = 0
        mapThePlaces()
    }
    
    func updateDateLabel(for date: Date) {
        applyThumbImage(year: dedicationYear(from: date))
    }
    
    func dateForSliderValue(_ value: Float) -> Date? {
        guard let minDate = timelineMinDate, let maxDate = timelineMaxDate else { return nil }
        let minT = minDate.timeIntervalSince1970
        let maxT = maxDate.timeIntervalSince1970
        let t = minT + Double(value) * (maxT - minT)
        return Date(timeIntervalSince1970: t)
    }
    
    @objc func sliderTouchBegan(_ sender: UISlider) {
        stopTimelinePlayback()
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        guard let date = dateForSliderValue(sender.value) else { return }
        updateDateLabel(for: date)
        let previousYear = timelineEndDate.map { dedicationYear(from: $0) }
        let newYear = dedicationYear(from: date)
        timelineEndDate = date
        if previousYear != newYear {
            mapThePlaces()
        }
    }
    
    func sliderValue(for date: Date) -> Float {
        guard let minDate = timelineMinDate, let maxDate = timelineMaxDate else { return 0 }
        let minT = minDate.timeIntervalSince1970
        let maxT = maxDate.timeIntervalSince1970
        guard maxT > minT else { return 0 }
        return Float((date.timeIntervalSince1970 - minT) / (maxT - minT))
    }
    
    @objc func prevYearTapped() {
        stopTimelinePlayback()
        guard let current = timelineEndDate else { return }
        let currentYear = dedicationYear(from: current)
        guard let prevYear = sortedDedicationYears.last(where: { $0 < currentYear }),
              let targetDate = sortedDedicationDates.first(where: { dedicationYear(from: $0) == prevYear })
        else { return }
        let value = sliderValue(for: targetDate)
        timelineSlider?.value = value
        timelineEndDate = targetDate
        updateDateLabel(for: targetDate)
        mapThePlaces()
    }
    
    @objc func nextYearTapped() {
        stopTimelinePlayback()
        guard let current = timelineEndDate else { return }
        let currentYear = dedicationYear(from: current)
        guard let nextYear = sortedDedicationYears.first(where: { $0 > currentYear }),
              let targetDate = sortedDedicationDates.first(where: { dedicationYear(from: $0) == nextYear })
        else { return }
        let value = sliderValue(for: targetDate)
        timelineSlider?.value = value
        timelineEndDate = targetDate
        updateDateLabel(for: targetDate)
        mapThePlaces()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Transparent navigation bar so the map shows through
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = navAppearance
        navigationController?.navigationBar.compactAppearance = navAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navAppearance

        // Transparent tab bar so the map shows through (when tab bar is visible)
        if !fromPlaceDetail {
            // Save the current appearance so we can restore it exactly when leaving
            savedTabBarStandardAppearance = tabBarController?.tabBar.standardAppearance
            savedTabBarScrollEdgeAppearance = tabBarController?.tabBar.scrollEdgeAppearance

            let tabAppearance = UITabBarAppearance()
            tabAppearance.configureWithTransparentBackground()
            tabBarController?.tabBar.standardAppearance = tabAppearance
            tabBarController?.tabBar.scrollEdgeAppearance = tabAppearance
        }

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
        
        updateTimelineButtonState()
        
        if optionSelected {
            mapThePlaces()
        }
        
        // Only set region when coming from place detail or first time
        if fromPlaceDetail || (navigationController?.viewControllers.first == self && !alreadyVisitedTab) {
            self.configureView()
            alreadyVisitedTab = true  // Set this AFTER configureView is called
        }
        
        // Keep updating marker sizes until MapKit finishes its internal layout
        schedulePostRebuildSizeUpdates()
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
        var filteredPlaces = mapPlaces.filter { place in
            let categoryMatch = (mapVisitedFilter == 0) || (mapVisitedFilter == 1 && visits.contains(place.templeName)) || (mapVisitedFilter == 2 && !(visits.contains(place.templeName)))
            return categoryMatch
        }
        
        // Apply timeline filter: show temples dedicated in cutoff year or earlier
        if isTimelineVisible, let cutoff = timelineEndDate {
            let cutoffYear = dedicationYear(from: cutoff)
            filteredPlaces = filteredPlaces.filter { place in
                guard let d = place.templeDedicationDate else { return false }
                return dedicationYear(from: d) <= cutoffYear
            }
        }
        
        if !fromPlaceDetail {
            if isTimelineVisible {
                // Incremental update: only add/remove the diff so existing pins don't flash
                let currentNames = Set(mapPoints.compactMap { $0.name })
                let desiredNames = Set(filteredPlaces.map { $0.templeName })
                
                let toRemove = mapPoints.filter { !(desiredNames.contains($0.name)) }
                if !toRemove.isEmpty {
                    let removeIds = Set(toRemove.map { ObjectIdentifier($0) })
                    mapPoints.removeAll { removeIds.contains(ObjectIdentifier($0)) }
                    mapView.removeAnnotations(toRemove)
                }
                
                let toAdd = filteredPlaces.filter { !currentNames.contains($0.templeName) }
                if !toAdd.isEmpty {
                    let newPoints = toAdd.map { place in
                        MapPoint(title: place.templeName,
                                 coordinate: CLLocationCoordinate2D(latitude: place.cllocation.coordinate.latitude,
                                                                    longitude: place.cllocation.coordinate.longitude),
                                 type: place.templeType)
                    }
                    mapPoints.append(contentsOf: newPoints)
                    mapView.addAnnotations(newPoints)
                }
                updateCountBadge(count: filteredPlaces.count)
            } else {
                // Full rebuild for non-timeline mode
                mapView.removeAnnotations(mapPoints)
                mapPoints.removeAll()
                for place in filteredPlaces {
                    mapPoints.append(MapPoint(title: place.templeName,
                                             coordinate: CLLocationCoordinate2D(latitude: place.cllocation.coordinate.latitude,
                                                                                longitude: place.cllocation.coordinate.longitude),
                                             type: place.templeType))
                }
                mapView.addAnnotations(mapPoints)
                if let selectedAnnotation = mapView.selectedAnnotations.first {
                    mapView.deselectAnnotation(selectedAnnotation, animated: false)
                }
            }
            
            // Keep updating marker sizes until MapKit finishes its internal layout
            schedulePostRebuildSizeUpdates()
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
            
            // Keep updating marker sizes until MapKit finishes its internal layout
            schedulePostRebuildSizeUpdates()
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
        view.animatesWhenAdded = false  // Prevent drop animation from overriding our transform
        annotation.title = " "
        
        // Set initial size based on current zoom level
        view.updateSize(for: mapView.camera.altitude)
        
        return view
    }

    // MARK: - Navigation
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        // Called synchronously after MapKit renders each batch of annotation views —
        // the right moment to apply correct zoom-based sizing.
        updateAllMarkerSizes()
    }
    
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
    
    func schedulePostRebuildSizeUpdates() {
        postRebuildSizeTimer?.invalidate()
        var ticks = 0
        postRebuildSizeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            self?.updateAllMarkerSizes()
            ticks += 1
            if ticks >= 30 { // 30 × 50ms = 1.5 seconds
                timer.invalidate()
                self?.postRebuildSizeTimer = nil
            }
        }
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

    // MARK: - Timeline playback
    
    @objc func playButtonTapped(_ sender: UIButton) {
        if isTimelinePlaying {
            stopTimelinePlayback()
        } else {
            startTimelinePlayback()
        }
    }
    
    func startTimelinePlayback() {
        guard let slider = timelineSlider, let _ = timelineMinDate, let _ = timelineMaxDate else { return }
        // If at the end, reset to beginning
        if slider.value >= 1.0 {
            slider.value = 0
            timelineEndDate = timelineMinDate
            mapThePlaces()
        }
        isTimelinePlaying = true
        timelinePlayButton?.setImage(UIImage(systemName: "pause.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)), for: .normal)
        // Advance slider over ~20 seconds (50ms ticks = 400 ticks, step = 1/400 per tick)
        let stepPerTick: Float = 1.0 / 400.0
        timelineTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.advanceTimeline(step: stepPerTick)
        }
    }
    
    func stopTimelinePlayback() {
        isTimelinePlaying = false
        timelineTimer?.invalidate()
        timelineTimer = nil
        timelinePlayButton?.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)), for: .normal)
    }
    
    func advanceTimeline(step: Float) {
        guard let slider = timelineSlider else { return }
        let newValue = min(slider.value + step, 1.0)
        slider.value = newValue
        guard let date = dateForSliderValue(newValue) else { return }
        updateDateLabel(for: date)
        
        let previousYear = timelineEndDate.map { dedicationYear(from: $0) }
        let newYear = dedicationYear(from: date)
        timelineEndDate = date
        
        // Only rebuild annotations when entering a new year that has dedications
        if previousYear != newYear && sortedDedicationYears.contains(newYear) {
            mapThePlaces()
        }
        
        if newValue >= 1.0 {
            stopTimelinePlayback()
        }
    }
    
    @objc func options(_ sender: Any) {
        optionSelected = true
        mapZoomLevel = mapView.camera.altitude
        self.performSegue(withIdentifier: "viewMapOptions", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewMapOptions" {
            if let mapOptionsVC = segue.destination as? MapOptionsVC {
                mapOptionsVC.onDismiss = { [weak self] in
                    self?.mapThePlaces()
                }
            }
            if let sheet = segue.destination.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.preferredCornerRadius = 20
            }
        }
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Shadow path must be updated after layout so the bounds are non-zero.
        // Without this the clear-background container casts no shadow.
        if let container = timelineContainerView, !container.bounds.isEmpty {
            container.layer.shadowPath = UIBezierPath(
                roundedRect: container.bounds, cornerRadius: 14
            ).cgPath
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopMarkerSizeUpdates()
        stopTimelinePlayback()
        postRebuildSizeTimer?.invalidate()
        postRebuildSizeTimer = nil
        
        // Restore default navigation bar appearance for other tabs
        let defaultNavAppearance = UINavigationBarAppearance()
        defaultNavAppearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = defaultNavAppearance
        navigationController?.navigationBar.compactAppearance = defaultNavAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = defaultNavAppearance

        // Restore the saved tab bar appearance (preserves Baskerville font set in AppDelegate)
        if let saved = savedTabBarStandardAppearance {
            tabBarController?.tabBar.standardAppearance = saved
        }
        tabBarController?.tabBar.scrollEdgeAppearance = savedTabBarScrollEdgeAppearance

        // Show tab bar when leaving map (in case it was hidden)
        tabBarController?.tabBar.isHidden = false
        
        // Reset the flag for next time
        fromPlaceDetail = false
    }

}
