//
//  PlaceDetailVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/10/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import SwiftUI
import SafariServices
import MapKit

class PlaceDetailVC: UIHostingController<PlaceDetailView> {

    var fromMap = false
    private let model: PlaceDetailModel
    private var switchedPlaces = false
    private var originalPlace = ""
    private var lastSwipeAt: TimeInterval = 0
    private var refreshImagesOnAppear = false

    required init?(coder: NSCoder) {
        let model = PlaceDetailModel()
        self.model = model
        super.init(coder: coder, rootView: PlaceDetailView(model: model, actions: PlaceDetailActions()))
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        originalPlace = detailItem?.templeName ?? ""
        rootView = PlaceDetailView(model: model, actions: makeActions())
        configureChrome()
        model.load(place: detailItem)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        padContentBelowIncomingSearchBar()
        hideTabBarForDetailScreen()
        if model.place?.templeName != detailItem?.templeName {
            model.load(place: detailItem)
        } else if refreshImagesOnAppear {
            refreshImagesOnAppear = false
            model.refreshIfNeeded(reloadImages: true)
        }
        let navBarFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let backButton = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
        backButton.setTitleTextAttributes([.font: navBarFont], for: .normal)
        backButton.setTitleTextAttributes([.font: navBarFont], for: .highlighted)
        navigationItem.backBarButtonItem = backButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        forceNavigationBarRefresh()
        configureChrome()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreTabBarIfLeavingDetail()
    }

    private func configureChrome() {
        if !fromMap {
            let navBarFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
            let button = UIBarButtonItem(title: "Map", style: .plain, target: self, action: #selector(goMap(_:)))
            button.setTitleTextAttributes([.font: navBarFont], for: .normal)
            button.setTitleTextAttributes([.font: navBarFont], for: .highlighted)
            navigationItem.rightBarButtonItem = button
        }
    }

    private func makeActions() -> PlaceDetailActions {
        PlaceDetailActions(
            openImage: { [weak self] image in
                self?.presentVisitImage(image)
            },
            openURL: { [weak self] urlString in
                self?.presentSafari(urlString)
            },
            openRecordVisit: { [weak self] in
                self?.presentRecordVisit()
            },
            openNavigationOptions: { [weak self] in
                self?.showNavigationOptions()
            },
            swipePlace: { [weak self] delta in
                self?.swipePlace(by: delta)
            }
        )
    }

    private func presentSafari(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    private func presentRecordVisit() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyBoard.instantiateViewController(withIdentifier: "RecordVisitVC") as? RecordVisitVC else { return }
        controller.detailItem = detailItem
        refreshImagesOnAppear = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func presentVisitImage(_ image: UIImage) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyBoard.instantiateViewController(withIdentifier: "VisitImageVC") as? VisitImageVC else { return }
        controller.img = image
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    @objc func showNavigationOptions() {
        guard let detail = detailItem else { return }
        let coordinate = CLLocationCoordinate2D(latitude: detail.templeLatitude, longitude: detail.templeLongitude)
        let alert = UIAlertController(title: "Navigate to Holy Place", message: "Choose an app", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default) { _ in
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = detail.templeName
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        })

        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
            alert.addAction(UIAlertAction(title: "Google Maps", style: .default) { _ in
                let urlString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            })
        }

        if UIApplication.shared.canOpenURL(URL(string: "waze://")!) {
            alert.addAction(UIAlertAction(title: "Waze", style: .default) { _ in
                let urlString = "waze://?ll=\(coordinate.latitude),\(coordinate.longitude)&navigate=yes"
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private func swipePlace(by delta: Int) {
        guard !fromMap else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSwipeAt > 0.35 else { return }
        lastSwipeAt = now
        let next = selectedPlaceRow + delta
        guard next >= 0, next < places.count else { return }
        selectedPlaceRow = next
        showSwipedPlace()
    }

    private func showSwipedPlace() {
        detailItem = places[selectedPlaceRow]
        if originalPlace != detailItem?.templeName {
            switchedPlaces = true
        }
        model.load(place: detailItem)
    }

    @objc func goMap(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
        let coordinate = CLLocationCoordinate2D(latitude: (detailItem?.cllocation.coordinate.latitude)!, longitude: (detailItem?.cllocation.coordinate.longitude)!)
        mapPoint = MapPoint(title: (detailItem?.templeName)!, coordinate: coordinate, type: (detailItem?.templeType)!)
        mapPoints.removeAll()
        if switchedPlaces {
            for place in places {
                mapPoints.append(MapPoint(
                    title: place.templeName,
                    coordinate: place.cllocation.coordinate,
                    type: place.templeType
                ))
            }
            if !mapPoints.contains(where: { $0.name == mapPoint.name }) {
                mapPoints.append(mapPoint)
            }
        } else {
            mapPoints.append(mapPoint)
        }
        mapZoomLevel = 4000
        mapCenter = coordinate
        controller.fromPlaceDetail = true
        controller.hidesBottomBarWhenPushed = true
        let navBarFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        let backButton = UIBarButtonItem(title: "Back", style: .done, target: nil, action: nil)
        backButton.setTitleTextAttributes([.font: navBarFont], for: .normal)
        backButton.setTitleTextAttributes([.font: navBarFont], for: .highlighted)
        navigationItem.backBarButtonItem = backButton
        navigationController?.pushViewController(controller, animated: true)
    }
}
