//
//  MapTabView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreData
import ImageIO
import MapKit
import Network
import SwiftUI
import UIKit

final class CalloutNameButton: UIButton {
    var fittedSize = CGSize(width: 44, height: 30)

    override var intrinsicContentSize: CGSize { fittedSize }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let titleLabel else { return }
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        let inset = bounds.insetBy(dx: 4, dy: 2)
        titleLabel.preferredMaxLayoutWidth = inset.width
        titleLabel.frame = inset
    }
}

final class CalloutThumbnailView: UIImageView {
    var placeName = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = 6
        isUserInteractionEnabled = false
        backgroundColor = .secondarySystemFill
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// A bubble sized to its contents. MapKit's callout keeps a title row and clips a taller photo.
final class PlaceCalloutBubble: UIView {
    private let shape = CAShapeLayer()
    private let tailHeight: CGFloat = 8
    private var restingFrames: [ObjectIdentifier: CGRect] = [:]
    private var tailX: CGFloat = 0
    private var tailPointsUp = false

    init(thumbnail: UIView, name: UIView, directions: UIView, contentSize: CGSize) {
        let padding = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let tail: CGFloat = 8
        let size = CGSize(
            width: contentSize.width + padding.left + padding.right,
            height: contentSize.height + padding.top + padding.bottom + tail
        )
        super.init(frame: CGRect(origin: .zero, size: size))
        tailX = size.width / 2
        backgroundColor = .clear
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.22
        shape.shadowRadius = 5
        shape.shadowOffset = CGSize(width: 0, height: 2)
        layer.addSublayer(shape)

        thumbnail.frame.origin = CGPoint(
            x: padding.left,
            y: padding.top + (contentSize.height - thumbnail.bounds.height) / 2
        )
        name.frame.origin = CGPoint(
            x: thumbnail.frame.maxX + 8,
            y: padding.top + (contentSize.height - name.bounds.height) / 2
        )
        directions.frame.origin = CGPoint(
            x: name.frame.maxX + 8,
            y: padding.top + (contentSize.height - directions.bounds.height) / 2
        )
        for view in [thumbnail, name, directions] {
            restingFrames[ObjectIdentifier(view)] = view.frame
            addSubview(view)
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (bubble: PlaceCalloutBubble, _) in
            bubble.updateFill()
        }
        updateFill()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTail(x: CGFloat, pointsUp: Bool) {
        let clamped = min(max(x, 18), max(18, bounds.width - 18))
        guard abs(tailX - clamped) > 0.5 || tailPointsUp != pointsUp else { return }
        tailX = clamped
        tailPointsUp = pointsUp
        let shift: CGFloat = pointsUp ? tailHeight : 0
        for subview in subviews {
            guard let resting = restingFrames[ObjectIdentifier(subview)] else { continue }
            subview.frame.origin.y = resting.origin.y + shift
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bodyY: CGFloat = tailPointsUp ? tailHeight : 0
        let body = CGRect(x: 0, y: bodyY, width: bounds.width, height: bounds.height - tailHeight)
        let path = UIBezierPath(roundedRect: body, cornerRadius: 10)
        let baseY: CGFloat = tailPointsUp ? body.minY + 0.5 : body.maxY - 0.5
        let tipY: CGFloat = tailPointsUp ? 0 : bounds.maxY
        path.move(to: CGPoint(x: tailX - 7, y: baseY))
        path.addLine(to: CGPoint(x: tailX, y: tipY))
        path.addLine(to: CGPoint(x: tailX + 7, y: baseY))
        path.close()
        shape.frame = bounds
        shape.path = path.cgPath
        shape.shadowPath = path.cgPath
    }

    private func updateFill() {
        shape.fillColor = UIColor.systemBackground.cgColor
    }
}

final class ResizableMarkerAnnotationView: MKMarkerAnnotationView {
    var minScale: CGFloat = 0.2
    var maxScale: CGFloat = 1.0
    var currentScale: CGFloat = 1
    private(set) var placeCallout: PlaceCalloutBubble?
    var isShowingPlaceCallout: Bool { placeCallout != nil }

    func showPlaceCallout(_ bubble: PlaceCalloutBubble) {
        placeCallout?.removeFromSuperview()
        placeCallout = bubble
        clipsToBounds = false
        addSubview(bubble)
        layoutPlaceCallout()
        titleVisibility = .hidden
        superview?.bringSubviewToFront(self)
    }

    /// Shifts the bubble so it stays on screen, and keeps the tail aimed at the pin.
    func layoutPlaceCallout() {
        guard let bubble = placeCallout, let mapView = mapAncestor, mapView.bounds.width > 1 else { return }
        let size = bubble.bounds.size
        let margin: CGFloat = 8
        let pin = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: mapView)
        let minX = mapView.safeAreaInsets.left + margin
        let maxX = mapView.bounds.width - mapView.safeAreaInsets.right - margin - size.width
        let originX = min(max(pin.x - size.width / 2, minX), max(minX, maxX))

        let topLimit = mapView.safeAreaInsets.top + margin
        let bottomLimit = mapView.bounds.height - mapView.safeAreaInsets.bottom - margin - size.height
        let aboveY = pin.y - size.height - 18
        let pointsUp = aboveY < topLimit
        var originY = pointsUp ? pin.y + 20 : aboveY
        originY = min(max(originY, topLimit), max(topLimit, bottomLimit))

        let origin = mapView.convert(CGPoint(x: originX, y: originY), to: self)
        let next = CGRect(origin: origin, size: size)
        if bubble.frame.integral != next.integral {
            bubble.frame = next
        }
        let pinX = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: bubble).x
        bubble.setTail(x: pinX, pointsUp: pointsUp)
    }

    private var mapAncestor: MKMapView? {
        var view: UIView? = self
        while let current = view {
            if let map = current as? MKMapView { return map }
            view = current.superview
        }
        return nil
    }

    func hidePlaceCallout() {
        placeCallout?.removeFromSuperview()
        placeCallout = nil
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        guard let placeCallout else { return false }
        return placeCallout.point(inside: convert(point, to: placeCallout), with: event)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let placeCallout {
            let hit = placeCallout.hitTest(convert(point, to: placeCallout), with: event)
            if hit != nil { return hit }
        }
        return super.hitTest(point, with: event)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if let point = annotation as? MapPoint {
            point.title = (selected && canShowCallout) ? "\u{200b}" : point.name
        }
        super.setSelected(selected, animated: animated)
        if selected {
            transform = .identity
            currentScale = 1
            if canShowCallout {
                titleVisibility = .hidden
            }
        } else {
            hidePlaceCallout()
        }
    }

    func updateSize(for zoomLevel: Double) {
        displayPriority = .required
        guard !isSelected else {
            transform = .identity
            currentScale = 1
            return
        }
        let minAltitude: Double = 1000
        let maxAltitude: Double = 25000000
        let normalizedZoom = max(0, min(1, (zoomLevel - minAltitude) / (maxAltitude - minAltitude)))
        let scale = maxScale - (normalizedZoom * (maxScale - minScale))
        currentScale = scale
        transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hidePlaceCallout()
    }
}

private let mapFilterChoices = [
    "Holy Places",
    "Active Temples",
    "Historical Sites",
    "Visitors' Centers",
    "Temples Under Construction",
    "Announced Temples",
    "All Temples"
]

private let kirtlandDedicationDate: Date = {
    var components = DateComponents()
    components.year = 1836
    components.month = 3
    components.day = 27
    return Calendar.current.date(from: components)!
}()

private let originalNauvooDedicationDate: Date = {
    var components = DateComponents()
    components.year = 1846
    components.month = 5
    components.day = 1
    return Calendar.current.date(from: components)!
}()

private func dedicationYear(from date: Date) -> Int {
    Calendar.current.component(.year, from: date)
}

private func eraName(for year: Int) -> String {
    switch year {
    case ..<1877:
        return "Restoration Era"
    case 1877..<1919:
        return "Pioneer Era"
    case 1919..<1964:
        return "Expansion Era"
    case 1964..<1983:
        return "Strengthening Era"
    case 1983..<1999:
        return "Growth Era"
    case 1999..<2003:
        return "Explosive Era"
    case 2003..<2019:
        return "Hastening Era"
    default:
        return "Unparalleled Era"
    }
}

private func timelineDedicationDates() -> [Date] {
    var dates = activeTemples.compactMap(\.templeDedicationDate)
    dates.append(kirtlandDedicationDate)
    dates.append(originalNauvooDedicationDate)
    dates.sort()
    return dates
}

private func templesForMap(filterRow: Int, visitedFilter: Int, timelineYear: Int?) -> [Temple] {
    let base: [Temple]
    switch filterRow {
    case 0:
        base = allPlaces
    case 1:
        base = activeTemples
    case 2:
        base = historical
    case 3:
        base = visitors
    case 4:
        base = construction
    case 5:
        base = announced
    default:
        base = allTemples
    }

    var filtered = base.filter { place in
        visitedFilter == 0
            || (visitedFilter == 1 && visits.contains(place.templeName))
            || (visitedFilter == 2 && !visits.contains(place.templeName))
    }

    if let timelineYear {
        filtered = filtered.filter { place in
            guard let date = place.templeDedicationDate else { return false }
            return dedicationYear(from: date) <= timelineYear
        }
        if timelineYear >= 1836,
           let kirtland = historical.first(where: { $0.templeName.contains("Kirtland Temple") }),
           !filtered.contains(where: { $0.templeName == kirtland.templeName }) {
            filtered.append(kirtland)
        }
        if timelineYear >= 1846,
           let nauvoo = activeTemples.first(where: { $0.templeName.contains("Nauvoo") }),
           !filtered.contains(where: { $0.templeName == nauvoo.templeName }) {
            filtered.append(nauvoo)
        }
    }
    return filtered
}

private func mapMarkerColor(type: String) -> UIColor {
    let pinTheme = mapPinTheme()
    switch type {
    case "T":
        return UIColor(named: "Temples" + pinTheme) ?? templeColor
    case "H":
        return UIColor(named: "Historical" + pinTheme) ?? historicalColor
    case "A":
        return UIColor(named: "Announced" + pinTheme) ?? announcedColor
    case "C":
        return UIColor(named: "Construction" + pinTheme) ?? constructionColor
    case "V":
        return UIColor(named: "VisitorCenters" + pinTheme) ?? visitorCenterColor
    default:
        return defaultColor
    }
}

private func coordinatesMatch(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> Bool {
    abs(lhs.latitude - rhs.latitude) < 0.000_01 && abs(lhs.longitude - rhs.longitude) < 0.000_01
}

private func mapPoint(for place: Temple, on date: Date?) -> MapPoint {
    let title = date.map { place.effectiveName(for: $0) } ?? place.templeName
    return MapPoint(
        title: title,
        coordinate: CLLocationCoordinate2D(
            latitude: place.cllocation.coordinate.latitude,
            longitude: place.cllocation.coordinate.longitude
        ),
        type: place.templeType
    )
}

struct MapTabView: View {
    @StateObject private var detailModel = PlaceDetailModel()
    @State private var recordModel: RecordVisitModel?
    @State private var pendingPlace: Temple?
    @State private var confirmDiscard = false

    @State private var filterRow = mapFilterRow
    @State private var visitedFilter = mapVisitedFilter
    @State private var mapStyle = 0
    @State private var timelineVisible = false
    @State private var timelineDate: Date?
    @State private var timelineStopToken = 0
    @State private var revision = 0
    @State private var hasAppeared = false
    @State private var basemapUnavailable = false

    @State private var showFilters = false
    @State private var viewerPhoto: MapPhoto?
    @State private var webPage: MapWebPage?
    @State private var showNavigation = false
    @State private var navigationPlace: Temple?
    @State private var googleMapsAvailable = false
    @State private var wazeAvailable = false
    @State private var updateNotice: MapUpdateNotice?

    var body: some View {
        NavigationStack {
            mapColumn
        }
        .confirmationDialog("Navigate to Holy Place", isPresented: mapNavigationPresented, titleVisibility: .visible) {
            Button("Apple Maps", action: openAppleMaps)
            if googleMapsAvailable {
                Button("Google Maps", action: openGoogleMaps)
            }
            if wazeAvailable {
                Button("Waze", action: openWaze)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose an app")
        }
        .sheet(isPresented: placeSheetPresented) {
            NavigationStack {
                secondaryColumn
                    .toolbar {
                        if recordModel == nil {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    dismissPlaceSheet()
                                }
                                .font(.custom("Baskerville", size: 17))
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled(recordModel?.isDirty == true)
            .fullScreenCover(item: $viewerPhoto) { item in
                PhotoViewerView(image: item.image) {
                    viewerPhoto = nil
                }
            }
            .sheet(item: $webPage) { page in
                SafariView(url: page.url)
            }
            .confirmationDialog("Navigate to Holy Place", isPresented: $showNavigation, titleVisibility: .visible) {
                Button("Apple Maps", action: openAppleMaps)
                if googleMapsAvailable {
                    Button("Google Maps", action: openGoogleMaps)
                }
                if wazeAvailable {
                    Button("Waze", action: openWaze)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose an app")
            }
            .alert("Discard changes?", isPresented: $confirmDiscard) {
                Button("Discard", role: .destructive) {
                    if let pendingPlace {
                        show(pendingPlace)
                    }
                    pendingPlace = nil
                }
                Button("Keep Editing", role: .cancel) {
                    pendingPlace = nil
                }
            } message: {
                Text("This visit has unsaved changes.")
            }
        }
        .alert(updateNotice?.title ?? "Update", isPresented: updatePresented) {
            Button("OK", role: .cancel) {
                changesDate = ""
            }
        } message: {
            Text(updateNotice?.message ?? "")
        }
        .onAppear(perform: handleAppear)
        .onDisappear {
            timelineStopToken += 1
        }
    }

    private var mapColumn: some View {
        ZStack(alignment: .topLeading) {
            HolyPlacesMapRepresentable(
                mapStyle: mapStyle,
                filterRow: filterRow,
                visitedFilter: visitedFilter,
                timelineDate: timelineVisible ? timelineDate : nil,
                revision: revision,
                selectedName: detailModel.place?.templeName,
                focusPlaces: nil,
                focusCenter: nil,
                focusZoom: nil,
                onSelect: handleSelect,
                onNavigate: presentNavigation(for:),
                onBasemapFallback: { basemapUnavailable = $0 }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            if timelineVisible, timelineDate != nil {
                timelineChrome
            }

            if basemapUnavailable {
                BasemapFallbackCaption()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Timeline", action: toggleTimeline)
                    .font(.custom("Baskerville", size: 17))
            }
            ToolbarItem(placement: .principal) {
                BaskervilleSegments(titles: ["Standard", "Aerial"], selection: $mapStyle, tint: nil)
                    .frame(width: 200, height: 32)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !timelineVisible {
                    Button("Filters") { showFilters = true }
                        .font(.custom("Baskerville", size: 17))
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFilters) {
            MapFiltersSheet(filterRow: filterRow, visitedFilter: visitedFilter) { row, visited in
                filterRow = row
                visitedFilter = visited
                mapFilterRow = row
                mapVisitedFilter = visited
                revision += 1
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }

    private var timelineChrome: some View {
        let year = dedicationYear(from: timelineDate ?? Date())
        return VStack(alignment: .leading, spacing: 8) {
            TimelineBar(
                date: Binding(
                    get: { timelineDate ?? Date() },
                    set: { timelineDate = $0 }
                ),
                stopToken: timelineStopToken
            )
            .frame(height: 56)
            TimelineCountBadge(
                count: templesForMap(filterRow: filterRow, visitedFilter: visitedFilter, timelineYear: year).count,
                year: year
            )
        }
        .padding(.top, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var secondaryColumn: some View {
        if let recordModel {
            RecordVisitForm(
                model: recordModel,
                onCancel: { cancelRecordVisit() },
                onSaved: { savedRecordVisit() }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if detailModel.place != nil {
            PlaceDetailView(model: detailModel, actions: placeActions)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Select a place")
                .font(.custom("Baskerville", size: 22))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemBackground))
        }
    }

    private var placeActions: PlaceDetailActions {
        PlaceDetailActions(
            openImage: { image in
                viewerPhoto = MapPhoto(image: image)
            },
            openURL: { urlString in
                if let url = URL(string: urlString) {
                    webPage = MapWebPage(url: url)
                }
            },
            openRecordVisit: beginRecordVisit,
            openNavigationOptions: presentNavigation,
            swipePlace: { _ in }
        )
    }

    private var mapNavigationPresented: Binding<Bool> {
        Binding(
            get: { showNavigation && detailModel.place == nil },
            set: { if !$0 { showNavigation = false } }
        )
    }

    private var placeSheetPresented: Binding<Bool> {
        Binding(
            get: { detailModel.place != nil },
            set: { presented in
                if !presented {
                    dismissPlaceSheet()
                }
            }
        )
    }

    private func dismissPlaceSheet() {
        recordModel = nil
        detailModel.load(place: nil)
    }

    private var updatePresented: Binding<Bool> {
        Binding(
            get: { updateNotice != nil },
            set: { if !$0 { updateNotice = nil } }
        )
    }

    private func handleAppear() {
        if hasAppeared {
            revision += 1
        }
        hasAppeared = true
        if ad.newFileParsed {
            ad.storePlaces()
            ad.savePlaceVersion()
            checkedForUpdate = Date()
            ad.newFileParsed = false
        }
        guard updateNotice == nil, !changesDate.isEmpty else { return }
        var message = changesMsg1
        if !changesMsg2.isEmpty {
            message += "\n\n" + changesMsg2
        }
        if !changesMsg3.isEmpty {
            message += "\n\n" + changesMsg3
        }
        updateNotice = MapUpdateNotice(title: changesDate + " Update", message: message)
    }

    private func toggleTimeline() {
        if timelineVisible {
            hideTimeline()
        } else {
            showTimeline()
        }
    }

    private func showTimeline() {
        guard let start = timelineDedicationDates().first else { return }
        filterRow = 1
        visitedFilter = 0
        mapFilterRow = 1
        mapVisitedFilter = 0
        timelineDate = start
        timelineVisible = true
    }

    private func hideTimeline() {
        timelineVisible = false
        timelineDate = nil
        filterRow = 0
        visitedFilter = 0
        mapFilterRow = 0
        mapVisitedFilter = 0
    }

    private func handleSelect(_ place: Temple) {
        let currentName = recordModel?.place.templeName ?? detailModel.place?.templeName
        if place.templeName == currentName {
            return
        }
        if recordModel?.isDirty == true {
            pendingPlace = place
            confirmDiscard = true
            return
        }
        show(place)
    }

    private func show(_ place: Temple) {
        recordModel = nil
        detailModel.load(place: place)
    }

    private func beginRecordVisit() {
        guard let place = detailModel.place else { return }
        recordModel = RecordVisitModel(place: place, existingVisit: nil)
    }

    private func cancelRecordVisit() {
        recordModel = nil
    }

    private func savedRecordVisit() {
        let place = recordModel?.place ?? detailModel.place
        recordModel = nil
        if let place {
            detailModel.load(place: place)
        }
        revision += 1
    }

    private func presentNavigation() {
        guard let place = detailModel.place else { return }
        presentNavigation(for: place)
    }

    private func presentNavigation(for place: Temple) {
        navigationPlace = place
        if let url = URL(string: "comgooglemaps://") {
            googleMapsAvailable = UIApplication.shared.canOpenURL(url)
        }
        if let url = URL(string: "waze://") {
            wazeAvailable = UIApplication.shared.canOpenURL(url)
        }
        showNavigation = true
    }

    private func openAppleMaps() {
        guard let place = navigationPlace else { return }
        let coordinate = CLLocationCoordinate2D(latitude: place.templeLatitude, longitude: place.templeLongitude)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = place.templeName
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func openGoogleMaps() {
        guard let place = navigationPlace else { return }
        let urlString = "comgooglemaps://?daddr=\(place.templeLatitude),\(place.templeLongitude)&directionsmode=driving"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openWaze() {
        guard let place = navigationPlace else { return }
        let urlString = "waze://?ll=\(place.templeLatitude),\(place.templeLongitude)&navigate=yes"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct MapFocusCover: View {
    let places: [Temple]
    let center: CLLocationCoordinate2D
    let zoom: CLLocationDistance
    var onDismiss: () -> Void

    @State private var mapStyle = 0
    @State private var basemapUnavailable = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                HolyPlacesMapRepresentable(
                    mapStyle: mapStyle,
                    filterRow: 0,
                    visitedFilter: 0,
                    timelineDate: nil,
                    revision: 0,
                    selectedName: nil,
                    focusPlaces: places,
                    focusCenter: center,
                    focusZoom: zoom,
                    onSelect: nil,
                    onBasemapFallback: { basemapUnavailable = $0 }
                )
                .ignoresSafeArea()

                if basemapUnavailable {
                    BasemapFallbackCaption()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                        .font(.custom("Baskerville", size: 17))
                }
                ToolbarItem(placement: .principal) {
                    BaskervilleSegments(titles: ["Standard", "Aerial"], selection: $mapStyle, tint: nil)
                        .frame(width: 200, height: 32)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct BasemapFallbackCaption: View {
    var body: some View {
        Text("Map detail isn’t available right now")
            .font(.custom("Baskerville", size: 16))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 10)
    }
}

private struct MapPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct MapWebPage: Identifiable {
    let id = UUID()
    let url: URL
}

private struct MapUpdateNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct TimelineCountBadge: View {
    let count: Int
    let year: Int
    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.05, green: 0.10, blue: 0.30)
        }
        return Color(red: 0.92, green: 0.95, blue: 1)
    }

    var body: some View {
        Text("\(count) - \(eraName(for: year))")
            .font(.custom("Baskerville", size: 18))
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .frame(minWidth: 44, minHeight: 44)
            .background(Color("BaptismsBlue"), in: Capsule())
    }
}

private struct MapFiltersSheet: View {
    var onApply: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var row: Int
    @State private var visited: Int
    @State private var applied = false

    init(filterRow: Int, visitedFilter: Int, onApply: @escaping (Int, Int) -> Void) {
        self.onApply = onApply
        _row = State(initialValue: filterRow)
        _visited = State(initialValue: visitedFilter)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Show On Map")
                .font(.custom("Baskerville", size: 22))
            MapFilterWheel(selection: $row)
                .frame(maxWidth: 320)
                .frame(height: 216)
            BaskervilleSegments(
                titles: ["All", "Visited", "Not Visited"],
                selection: $visited,
                tint: UIColor(named: "BaptismsBlue")
            )
            .frame(maxWidth: 280)
            .frame(height: 32)
            Button(action: finish) {
                Text("Done")
                    .font(.custom("Baskerville", size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 300, height: 40)
                    .background(
                        Color(red: 0, green: 0.250980407, blue: 0.501960814),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .tertiarySystemBackground))
        .onDisappear(perform: applyIfNeeded)
    }

    private func finish() {
        applyIfNeeded()
        dismiss()
    }

    private func applyIfNeeded() {
        guard !applied else { return }
        applied = true
        onApply(row, visited)
    }
}

private struct MapFilterWheel: UIViewRepresentable {
    @Binding var selection: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        let row = min(max(selection, 0), mapFilterChoices.count - 1)
        picker.selectRow(row, inComponent: 0, animated: false)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.selection = $selection
        let row = min(max(selection, 0), mapFilterChoices.count - 1)
        if picker.selectedRow(inComponent: 0) != row {
            picker.selectRow(row, inComponent: 0, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var selection: Binding<Int>

        init(selection: Binding<Int>) {
            self.selection = selection
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            mapFilterChoices.count
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            let title = mapFilterChoices[row]
            let font = UIFont(name: "Baskerville", size: 20) ?? .systemFont(ofSize: 20)
            let color = colorForPlaceTypeCode(placeTypeCode(forFilterTitle: title))
            label.attributedText = attributedPlaceTypeFilterTitle(title, font: font, color: color)
            label.textAlignment = .center
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selection.wrappedValue = row
        }
    }
}

private struct BaskervilleSegments: UIViewRepresentable {
    let titles: [String]
    @Binding var selection: Int
    var tint: UIColor?

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: titles)
        control.selectedSegmentIndex = selection
        let font = UIFont(name: "Baskerville", size: 14) ?? .systemFont(ofSize: 14)
        control.setTitleTextAttributes([.font: font], for: .normal)
        if let tint {
            control.selectedSegmentTintColor = tint
        }
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        context.coordinator.selection = $selection
        if control.selectedSegmentIndex != selection {
            control.selectedSegmentIndex = selection
        }
    }

    final class Coordinator: NSObject {
        var selection: Binding<Int>

        init(selection: Binding<Int>) {
            self.selection = selection
        }

        @objc func changed(_ sender: UISegmentedControl) {
            selection.wrappedValue = sender.selectedSegmentIndex
        }
    }
}

private struct TimelineBar: UIViewRepresentable {
    @Binding var date: Date
    var stopToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date, stopToken: stopToken)
    }

    func makeUIView(context: Context) -> TimelineBarView {
        let bar = TimelineBarView()
        let coordinator = context.coordinator
        bar.onYearBoundary = { newDate in
            coordinator.date.wrappedValue = newDate
        }
        bar.configure(date: date)
        return bar
    }

    func updateUIView(_ bar: TimelineBarView, context: Context) {
        context.coordinator.date = $date
        let coordinator = context.coordinator
        bar.onYearBoundary = { newDate in
            coordinator.date.wrappedValue = newDate
        }
        if context.coordinator.stopToken != stopToken {
            context.coordinator.stopToken = stopToken
            bar.stopPlayback()
        }
    }

    final class Coordinator {
        var date: Binding<Date>
        var stopToken: Int

        init(date: Binding<Date>, stopToken: Int) {
            self.date = date
            self.stopToken = stopToken
        }
    }
}

private final class TimelineBarView: UIView {
    var onYearBoundary: ((Date) -> Void)?

    private let slider = UISlider()
    private let playButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private var timer: Timer?
    private var isPlaying = false
    private var minDate: Date?
    private var maxDate: Date?
    private var sortedDates: [Date] = []
    private var sortedYears: [Int] = []
    private var endDate: Date?
    private var lastYear = -1

    private let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
    private var blue: UIColor { UIColor(named: "BaptismsBlue") ?? .systemBlue }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        timer?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty else { return }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 14).cgPath
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopPlayback()
        }
    }

    func configure(date: Date) {
        let dates = timelineDedicationDates()
        guard let first = dates.first, let last = dates.last else { return }
        sortedDates = dates
        minDate = first
        maxDate = last
        var seen = Set<Int>()
        sortedYears = dates.compactMap { item in
            let year = dedicationYear(from: item)
            return seen.insert(year).inserted ? year : nil
        }
        let clamped = min(max(date, first), last)
        slider.value = sliderValue(for: clamped)
        note(clamped, notify: false)
    }

    func stopPlayback() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: symbolConfig), for: .normal)
    }

    private func setup() {
        backgroundColor = .clear
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.layer.cornerRadius = 14
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        blur.alpha = 0.72
        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)

        playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: symbolConfig), for: .normal)
        prevButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: symbolConfig), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: symbolConfig), for: .normal)
        for button in [playButton, prevButton, nextButton] {
            button.tintColor = blue
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
        }
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.tintColor = blue
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchBegan), for: .touchDown)
        let placeholder = makeThumbImage(year: 1877)
        slider.setThumbImage(placeholder, for: .normal)
        slider.setThumbImage(placeholder, for: .highlighted)
        addSubview(slider)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),

            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),

            prevButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 2),
            prevButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            prevButton.heightAnchor.constraint(equalToConstant: 44),

            slider.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor),
            slider.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),

            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: TimelineBarView, _: UITraitCollection) in
            if let endDate = view.endDate {
                view.applyThumb(year: dedicationYear(from: endDate))
            }
        }
    }

    @objc private func playTapped() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    @objc private func sliderTouchBegan() {
        stopPlayback()
    }

    @objc private func sliderChanged() {
        guard let date = dateForSliderValue(slider.value) else { return }
        note(date, notify: true)
    }

    @objc private func prevTapped() {
        stopPlayback()
        guard let current = endDate else { return }
        let year = dedicationYear(from: current)
        guard let previous = sortedYears.last(where: { $0 < year }),
              let target = sortedDates.first(where: { dedicationYear(from: $0) == previous }) else { return }
        slider.value = sliderValue(for: target)
        note(target, notify: true)
    }

    @objc private func nextTapped() {
        stopPlayback()
        guard let current = endDate else { return }
        let year = dedicationYear(from: current)
        guard let next = sortedYears.first(where: { $0 > year }),
              let target = sortedDates.first(where: { dedicationYear(from: $0) == next }) else { return }
        slider.value = sliderValue(for: target)
        note(target, notify: true)
    }

    private func startPlayback() {
        guard minDate != nil, maxDate != nil else { return }
        if slider.value >= 1 {
            slider.value = 0
            if let minDate {
                note(minDate, notify: true)
            }
        }
        isPlaying = true
        playButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: symbolConfig), for: .normal)
        let step: Float = 1.0 / 400.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.advance(step: step)
        }
    }

    private func advance(step: Float) {
        let newValue = min(slider.value + step, 1)
        slider.value = newValue
        guard let date = dateForSliderValue(newValue) else { return }
        let year = dedicationYear(from: date)
        let crossedDedication = year != lastYear && sortedYears.contains(year)
        note(date, notify: crossedDedication)
        if newValue >= 1 {
            stopPlayback()
        }
    }

    private func note(_ date: Date, notify: Bool) {
        endDate = date
        let year = dedicationYear(from: date)
        guard year != lastYear else { return }
        lastYear = year
        applyThumb(year: year)
        if notify {
            onYearBoundary?(date)
        }
    }

    private func dateForSliderValue(_ value: Float) -> Date? {
        guard let minDate, let maxDate else { return nil }
        let minT = minDate.timeIntervalSince1970
        let maxT = maxDate.timeIntervalSince1970
        return Date(timeIntervalSince1970: minT + Double(value) * (maxT - minT))
    }

    private func sliderValue(for date: Date) -> Float {
        guard let minDate, let maxDate else { return 0 }
        let minT = minDate.timeIntervalSince1970
        let maxT = maxDate.timeIntervalSince1970
        guard maxT > minT else { return 0 }
        return Float((date.timeIntervalSince1970 - minT) / (maxT - minT))
    }

    private func applyThumb(year: Int) {
        let image = makeThumbImage(year: year)
        slider.setThumbImage(image, for: .normal)
        slider.setThumbImage(image, for: .highlighted)
    }

    private func makeThumbImage(year: Int) -> UIImage {
        let text = "\(year)"
        let font = UIFont(name: "Baskerville", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
        let isDark = traitCollection.userInterfaceStyle == .dark
        let textColor = isDark
            ? UIColor(red: 0.05, green: 0.10, blue: 0.30, alpha: 1)
            : UIColor(red: 0.92, green: 0.95, blue: 1, alpha: 1)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let horizontalPad: CGFloat = 12
        let verticalPad: CGFloat = 7
        let size = CGSize(width: textSize.width + horizontalPad * 2, height: textSize.height + verticalPad * 2)
        let fill = blue
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            fill.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.height / 2).fill()
            (text as NSString).draw(
                in: CGRect(x: horizontalPad, y: verticalPad, width: textSize.width, height: textSize.height),
                withAttributes: attributes
            )
        }
    }
}

private struct HolyPlacesMapRepresentable: UIViewControllerRepresentable {
    var mapStyle: Int
    var filterRow: Int
    var visitedFilter: Int
    var timelineDate: Date?
    var revision: Int
    var selectedName: String?
    var focusPlaces: [Temple]?
    var focusCenter: CLLocationCoordinate2D?
    var focusZoom: CLLocationDistance?
    var onSelect: ((Temple) -> Void)?
    var onNavigate: ((Temple) -> Void)? = nil
    var onBasemapFallback: (Bool) -> Void

    func makeUIViewController(context: Context) -> HolyPlacesMapController {
        HolyPlacesMapController()
    }

    func updateUIViewController(_ controller: HolyPlacesMapController, context: Context) {
        controller.onSelectPlace = onSelect
        controller.onNavigate = onNavigate
        controller.onBasemapFallback = onBasemapFallback
        controller.mapStyle = mapStyle
        controller.filterRow = filterRow
        controller.visitedFilter = visitedFilter
        controller.timelineDate = timelineDate
        controller.revision = revision
        controller.selectedName = selectedName
        controller.focusPlaces = focusPlaces
        controller.focusCenter = focusCenter
        controller.focusZoom = focusZoom
        controller.apply()
        if controller.isShowingBasemapFallback {
            DispatchQueue.main.async {
                guard controller.isShowingBasemapFallback else { return }
                onBasemapFallback(true)
            }
        }
    }
}

private final class HolyPlacesMapController: UIViewController, MKMapViewDelegate {
    let mapView = MKMapView()
    var onSelectPlace: ((Temple) -> Void)?
    var onNavigate: ((Temple) -> Void)?
    private var keptCalloutName: String?
    var mapStyle = 0
    var filterRow = 0
    var visitedFilter = 0
    var timelineDate: Date?
    var revision = 0
    var selectedName: String?
    var focusPlaces: [Temple]?
    var focusCenter: CLLocationCoordinate2D?
    var focusZoom: CLLocationDistance?

    private var annotations: [MapPoint] = []
    private var displayedPlaces: [Temple] = []
    private var thumbnailCache: [String: UIImage] = [:]
    private var thumbnailLoads = Set<String>()
    private static let calloutNameMaxWidth: CGFloat = 160
    private static let calloutThumbnailSize = CGSize(width: 72, height: 54)
    private static let calloutThumbnailSpacing: CGFloat = 8
    private var adjustingSelection = false
    private var didSetBrowseRegion = false
    private var didSetFocusRegion = false
    private var timelineMode = false
    private var initialTimelineReady = false
    private var appliedTimelineYear: Int?
    private var appliedFilter = (-1, -1)
    private var appliedRevision = -1
    private var appliedFocusKey = ""
    private var timelineWork: DispatchWorkItem?
    private var postRebuildTimer: Timer?
    private var markerLink: CADisplayLink?
    private let markerProxy = MarkerProxy()
    var onBasemapFallback: ((Bool) -> Void)?

    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "holyplaces.map-path")
    private var pathUsable = true
    private var fallbackOverlay: CoastlineTileOverlay?
    private var fallbackVisible = false
    private var watchGeneration = 0
    private var loadWatchTimer: Timer?
    private var retryTimer: Timer?
    private var hasFinishedRegion = false
    private var finishedRegion = MKCoordinateRegion()
    private var finishedMapType: MKMapType = .standard

    var isShowingBasemapFallback: Bool { fallbackVisible }

    deinit {
        markerLink?.invalidate()
        postRebuildTimer?.invalidate()
        timelineWork?.cancel()
        pathMonitor.cancel()
        loadWatchTimer?.invalidate()
        retryTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        markerProxy.owner = self
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let usable = path.status == .satisfied
            DispatchQueue.main.async {
                self?.applyPathUsable(usable)
            }
        }
        pathMonitor.start(queue: pathQueue)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (controller: HolyPlacesMapController, previous: UITraitCollection) in
            guard previous.userInterfaceStyle != controller.traitCollection.userInterfaceStyle else { return }
            guard controller.fallbackVisible else { return }
            if let overlay = controller.fallbackOverlay {
                controller.mapView.removeOverlay(overlay)
                controller.fallbackOverlay = nil
            }
            controller.showFallback()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installBrowseRegionIfNeeded()
        installFocusRegionIfNeeded()
        for annotation in mapView.annotations {
            (mapView.view(for: annotation) as? ResizableMarkerAnnotationView)?.layoutPlaceCallout()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAllMarkerSizes()
        restoreKeptCallout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopMarkerSizeUpdates()
        postRebuildTimer?.invalidate()
        postRebuildTimer = nil
    }

    func apply() {
        let type: MKMapType = mapStyle == 1 ? .satellite : .standard
        if mapView.mapType != type {
            mapView.mapType = type
            hasFinishedRegion = false
            if fallbackVisible && pathUsable {
                retryAppleBasemap()
            } else {
                scheduleBasemapWatch()
            }
        }
        if let focusPlaces, let focusCenter, let focusZoom {
            applyFocus(places: focusPlaces, center: focusCenter, zoom: focusZoom)
            return
        }
        applyBrowse()
    }

    private func applyBrowse() {
        installBrowseRegionIfNeeded()

        let wantsTimeline = timelineDate != nil
        if wantsTimeline && !timelineMode {
            timelineMode = true
            appliedFilter = (filterRow, visitedFilter)
            appliedRevision = revision
            beginTimeline()
        } else if !wantsTimeline && timelineMode {
            timelineMode = false
            initialTimelineReady = false
            appliedTimelineYear = nil
            timelineWork?.cancel()
            appliedFilter = (filterRow, visitedFilter)
            appliedRevision = revision
            rebuild(incremental: false)
        } else if wantsTimeline {
            let year = timelineDate.map(dedicationYear(from:))
            let previous = appliedTimelineYear
            appliedTimelineYear = year
            if initialTimelineReady && year != previous {
                rebuild(incremental: true)
            }
        } else if filterRow != appliedFilter.0 || visitedFilter != appliedFilter.1 || revision != appliedRevision {
            appliedFilter = (filterRow, visitedFilter)
            appliedRevision = revision
            rebuild(incremental: false)
        }
        syncSelection()
    }

    private func beginTimeline() {
        appliedTimelineYear = timelineDate.map(dedicationYear(from:))
        mapView.removeAnnotations(annotations)
        annotations.removeAll()
        initialTimelineReady = false
        timelineWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.timelineMode else { return }
            self.initialTimelineReady = true
            self.rebuild(incremental: true)
            self.syncSelection()
        }
        timelineWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func applyFocus(places: [Temple], center: CLLocationCoordinate2D, zoom: CLLocationDistance) {
        let key = places.map(stablePlaceID).joined(separator: "\u{1}")
            + "|\(center.latitude)|\(center.longitude)|\(zoom)"
        guard key != appliedFocusKey else { return }
        appliedFocusKey = key
        didSetFocusRegion = false
        displayedPlaces = places
        replaceAll(places.map { mapPoint(for: $0, on: nil) })
        installFocusRegionIfNeeded()
        selectFocusPlace(center: center)
        schedulePostRebuildSizeUpdates()
    }

    private func installBrowseRegionIfNeeded() {
        guard focusPlaces == nil, !didSetBrowseRegion, mapView.bounds.width > 1, mapView.bounds.height > 1 else { return }
        didSetBrowseRegion = true
        let region = MKCoordinateRegion(
            center: initialBrowseCenter(),
            latitudinalMeters: 3_000_000,
            longitudinalMeters: 3_000_000
        )
        mapView.setRegion(region, animated: false)
        schedulePostRebuildSizeUpdates()
    }

    private func installFocusRegionIfNeeded() {
        guard focusPlaces != nil, !didSetFocusRegion, let center = focusCenter, let zoom = focusZoom,
              mapView.bounds.width > 1, mapView.bounds.height > 1 else { return }
        didSetFocusRegion = true
        let region = MKCoordinateRegion(center: center, latitudinalMeters: zoom, longitudinalMeters: zoom)
        mapView.setRegion(region, animated: false)
        mapView.setCenter(center, animated: false)
        selectFocusPlace(center: center)
        schedulePostRebuildSizeUpdates()
    }

    private func initialBrowseCenter() -> CLLocationCoordinate2D {
        if let location = ad.coordinateOfUser {
            return location.coordinate
        }
        return CLLocationCoordinate2D(latitude: 40.7707425, longitude: -111.8932596)
    }

    private func rebuild(incremental: Bool) {
        let year = timelineMode ? timelineDate.map(dedicationYear(from:)) : nil
        let places = templesForMap(filterRow: filterRow, visitedFilter: visitedFilter, timelineYear: year)
        displayedPlaces = places
        let keptName = (mapView.selectedAnnotations.first as? MapPoint).flatMap { temple(for: $0)?.templeName } ?? keptCalloutName
        if incremental, timelineMode, let date = timelineDate {
            applyIncremental(places: places, date: date)
        } else {
            adjustingSelection = true
            replaceAll(places.map { mapPoint(for: $0, on: nil) })
            adjustingSelection = false
            selectKeptCallout(named: keptName)
        }
        schedulePostRebuildSizeUpdates()
    }

    private func applyIncremental(places: [Temple], date: Date) {
        let currentNames = Set(annotations.map(\.name))
        let desiredNames = Set(places.map { $0.effectiveName(for: date) })
        let toRemove = annotations.filter { !desiredNames.contains($0.name) }
        if !toRemove.isEmpty {
            let removeIDs = Set(toRemove.map { ObjectIdentifier($0) })
            annotations.removeAll { removeIDs.contains(ObjectIdentifier($0)) }
            mapView.removeAnnotations(toRemove)
        }
        let toAdd = places.filter { !currentNames.contains($0.effectiveName(for: date)) }
        if !toAdd.isEmpty {
            let points = toAdd.map { mapPoint(for: $0, on: date) }
            annotations.append(contentsOf: points)
            mapView.addAnnotations(points)
        }
    }

    private func replaceAll(_ points: [MapPoint]) {
        mapView.removeAnnotations(annotations)
        annotations = points
        mapView.addAnnotations(points)
    }

    private func selectFocusPlace(center: CLLocationCoordinate2D) {
        let exact = annotations.first { coordinatesMatch($0.coordinate, center) }
        let match = exact ?? annotations.min { lhs, rhs in
            hypot(lhs.coordinate.latitude - center.latitude, lhs.coordinate.longitude - center.longitude)
                < hypot(rhs.coordinate.latitude - center.latitude, rhs.coordinate.longitude - center.longitude)
        }
        guard let match else { return }
        adjustingSelection = true
        mapView.selectAnnotation(match, animated: true)
        adjustingSelection = false
    }

    private func syncSelection() {
        if selectedName == nil {
            restoreKeptCallout()
            return
        }
        let current = mapView.selectedAnnotations.first as? MapPoint
        let currentName = current.flatMap { temple(for: $0)?.templeName }
        if currentName == selectedName { return }
        adjustingSelection = true
        if let current {
            mapView.deselectAnnotation(current, animated: false)
        }
        if let temple = (displayedPlaces + allPlaces).first(where: { $0.templeName == selectedName }),
           let point = annotations.first(where: { coordinatesMatch($0.coordinate, temple.cllocation.coordinate) }) {
            mapView.selectAnnotation(point, animated: false)
        }
        adjustingSelection = false
    }

    private func selectKeptCallout(named name: String?) {
        guard let name,
              let temple = (displayedPlaces + allPlaces).first(where: { $0.templeName == name }),
              let point = annotations.first(where: { coordinatesMatch($0.coordinate, temple.cllocation.coordinate) })
        else { return }
        keptCalloutName = name
        let selected = mapView.selectedAnnotations.first as? MapPoint
        let alreadySelected = selected.map { coordinatesMatch($0.coordinate, point.coordinate) } ?? false
        if !alreadySelected {
            adjustingSelection = true
            mapView.selectAnnotation(point, animated: false)
            adjustingSelection = false
        }
        showKeptCallout(for: point, temple: temple)
    }

    private func restoreKeptCallout() {
        guard focusPlaces == nil else { return }
        selectKeptCallout(named: keptCalloutName)
    }

    private func showKeptCallout(for point: MapPoint, temple: Temple) {
        guard shouldShowThumbnail(for: temple),
              let marker = mapView.view(for: point) as? ResizableMarkerAnnotationView,
              !marker.isShowingPlaceCallout else { return }
        marker.showPlaceCallout(placeCallout(for: point, temple: temple, color: mapMarkerColor(type: point.type)))
    }

    private func temple(for point: MapPoint) -> Temple? {
        if let match = displayedPlaces.first(where: { coordinatesMatch(point.coordinate, $0.cllocation.coordinate) }) {
            return match
        }
        return allPlaces.first(where: { coordinatesMatch(point.coordinate, $0.cllocation.coordinate) })
    }

    private func calloutNameButton(title: String, color: UIColor) -> CalloutNameButton {
        let font = UIFont(name: "Baskerville", size: 20) ?? .systemFont(ofSize: 20)
        let button = CalloutNameButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = font
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        let measured = (title as NSString).boundingRect(
            with: CGSize(width: Self.calloutNameMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let textWidth = min(Self.calloutNameMaxWidth, ceil(measured.width))
        let twoLineHeight = ceil(font.lineHeight * 2)
        let textHeight = min(ceil(measured.height), twoLineHeight)
        button.fittedSize = CGSize(width: textWidth + 8, height: max(30, textHeight + 4))
        button.frame = CGRect(origin: .zero, size: button.fittedSize)
        return button
    }

    private func directionsButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("⤴️", for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 30)
        return button
    }

    private func placeCallout(for point: MapPoint, temple: Temple, color: UIColor) -> PlaceCalloutBubble {
        let nameButton = calloutNameButton(title: point.name, color: color)
        nameButton.addTarget(self, action: #selector(calloutNameTapped), for: .touchUpInside)

        let thumb = CalloutThumbnailView(frame: CGRect(origin: .zero, size: Self.calloutThumbnailSize))
        thumb.placeName = temple.templeName
        thumb.image = thumbnailCache[temple.templeName]
        thumb.isUserInteractionEnabled = true
        thumb.isAccessibilityElement = true
        thumb.accessibilityLabel = point.name
        thumb.accessibilityTraits = .button
        thumb.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(calloutNameTapped)))

        let directions = directionsButton()
        directions.addTarget(self, action: #selector(calloutDirectionsTapped), for: .touchUpInside)

        let contentSize = CGSize(
            width: Self.calloutThumbnailSize.width
                + Self.calloutThumbnailSpacing
                + nameButton.fittedSize.width
                + Self.calloutThumbnailSpacing
                + directions.bounds.width,
            height: max(nameButton.fittedSize.height, Self.calloutThumbnailSize.height, directions.bounds.height)
        )
        let bubble = PlaceCalloutBubble(
            thumbnail: thumb,
            name: nameButton,
            directions: directions,
            contentSize: contentSize
        )
        if thumb.image == nil {
            beginThumbnailLoad(for: temple)
        }
        return bubble
    }

    @objc private func calloutDirectionsTapped() {
        guard let point = mapView.selectedAnnotations.first as? MapPoint else { return }
        presentNavigate(for: point)
    }

    @objc private func calloutNameTapped() {
        guard let point = mapView.selectedAnnotations.first as? MapPoint,
              let temple = temple(for: point) else { return }
        onSelectPlace?(temple)
    }

    private func shouldShowThumbnail(for temple: Temple) -> Bool {
        if thumbnailCache[temple.templeName] != nil { return true }
        if !temple.templePictureURL.isEmpty, URL(string: temple.templePictureURL) != nil {
            return true
        }
        return storedPictureExists(named: temple.templeName)
    }

    private func storedPictureExists(named name: String) -> Bool {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND pictureData != nil", name)
        request.fetchLimit = 1
        let context = ad.persistentContainer.viewContext
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    private func beginThumbnailLoad(for temple: Temple) {
        let name = temple.templeName
        let urlString = temple.templePictureURL
        guard thumbnailCache[name] == nil, !thumbnailLoads.contains(name) else { return }
        thumbnailLoads.insert(name)
        ad.persistentContainer.performBackgroundTask { [weak self] context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "name == %@", name)
            let data = (try? context.fetch(request))?.first?.pictureData
            if let data, let image = Self.thumbnailImage(from: data) {
                DispatchQueue.main.async {
                    self?.finishThumbnailLoad(image, named: name)
                }
                return
            }
            DispatchQueue.main.async {
                self?.downloadThumbnail(named: name, urlString: urlString)
            }
        }
    }

    private func downloadThumbnail(named name: String, urlString: String) {
        guard thumbnailCache[name] == nil,
              let url = URL(string: urlString), !urlString.isEmpty else {
            thumbnailLoads.remove(name)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard
                let http = response as? HTTPURLResponse, http.statusCode == 200,
                let mime = response?.mimeType, mime.hasPrefix("image"),
                let data, error == nil,
                let image = Self.thumbnailImage(from: data)
            else {
                DispatchQueue.main.async { self?.thumbnailLoads.remove(name) }
                return
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.savePictureData(data, named: name)
                self.finishThumbnailLoad(image, named: name)
            }
        }.resume()
    }

    private func savePictureData(_ data: Data, named name: String) {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        let context = ad.persistentContainer.viewContext
        guard let stored = (try? context.fetch(request))?.first else { return }
        stored.pictureData = data
        try? context.save()
    }

    private func finishThumbnailLoad(_ image: UIImage, named name: String) {
        thumbnailLoads.remove(name)
        thumbnailCache[name] = image
        for annotation in mapView.annotations {
            guard let marker = mapView.view(for: annotation) else { continue }
            let containers = [
                marker.leftCalloutAccessoryView,
                marker.detailCalloutAccessoryView,
                (marker as? ResizableMarkerAnnotationView)?.placeCallout
            ].compactMap { $0 }
            for container in containers {
                for subview in container.subviews {
                    guard let thumb = subview as? CalloutThumbnailView, thumb.placeName == name else { continue }
                    thumb.image = image
                }
            }
        }
    }

    private static func thumbnailImage(from data: Data) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 160,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let point = annotation as? MapPoint else { return nil }
        let identifier = "marker"
        let marker: ResizableMarkerAnnotationView
        if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ResizableMarkerAnnotationView {
            dequeued.annotation = point
            marker = dequeued
        } else {
            marker = ResizableMarkerAnnotationView(annotation: point, reuseIdentifier: identifier)
        }

        let nameColor = mapMarkerColor(type: point.type)
        marker.leftCalloutAccessoryView = nil
        marker.detailCalloutAccessoryView = nil
        marker.rightCalloutAccessoryView = nil

        let showsCallout = focusPlaces == nil
        let showsThumbnail = showsCallout && temple(for: point).map(shouldShowThumbnail) == true
        marker.canShowCallout = showsCallout && !showsThumbnail
        point.title = (marker.isSelected && marker.canShowCallout) ? "\u{200b}" : point.name
        marker.titleVisibility = .hidden
        if showsThumbnail, let temple = temple(for: point) {
            if marker.isSelected {
                marker.showPlaceCallout(placeCallout(for: point, temple: temple, color: nameColor))
            } else {
                marker.hidePlaceCallout()
            }
        } else if showsCallout {
            marker.hidePlaceCallout()
            marker.leftCalloutAccessoryView = calloutNameButton(title: point.name, color: nameColor)
            marker.rightCalloutAccessoryView = directionsButton()
        } else {
            marker.hidePlaceCallout()
        }

        marker.isEnabled = true
        marker.markerTintColor = mapMarkerColor(type: point.type)
        marker.glyphImage = nil
        marker.animatesWhenAdded = false
        marker.updateSize(for: mapView.camera.altitude)
        return marker
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        updateAllMarkerSizes()
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if !adjustingSelection, mapView.selectedAnnotations.isEmpty, selectedName == nil {
            keptCalloutName = nil
        }
        if let point = view.annotation as? MapPoint, !view.canShowCallout {
            point.title = point.name
        }
        updateAllMarkerSizes()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let marker = view as? ResizableMarkerAnnotationView,
           let point = view.annotation as? MapPoint,
           focusPlaces == nil,
           let temple = temple(for: point),
           shouldShowThumbnail(for: temple) {
            keptCalloutName = temple.templeName
            marker.showPlaceCallout(placeCallout(for: point, temple: temple, color: mapMarkerColor(type: point.type)))
            return
        }
        collapsePlainCalloutTitle(in: mapView)
        DispatchQueue.main.async { [weak self] in
            self?.collapsePlainCalloutTitle(in: mapView)
        }
    }

    private func collapsePlainCalloutTitle(in view: UIView) {
        let typeName = String(describing: type(of: view))
        if typeName.localizedCaseInsensitiveContains("callout") || typeName.contains("Popover") {
            collapseTitleLabels(in: view)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            return
        }
        for subview in view.subviews {
            collapsePlainCalloutTitle(in: subview)
        }
    }

    private func collapseTitleLabels(in view: UIView) {
        if let label = view as? UILabel, !(label.superview is UIButton) {
            label.text = nil
            label.isHidden = true
            label.frame.size = .zero
        }
        for subview in view.subviews where !(subview is UIButton) {
            collapseTitleLabels(in: subview)
        }
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let point = view.annotation as? MapPoint else { return }
        if control == view.rightCalloutAccessoryView {
            presentNavigate(for: point)
        } else if let temple = temple(for: point) {
            onSelectPlace?(temple)
        }
    }

    private func presentNavigate(for point: MapPoint) {
        guard let temple = temple(for: point) else { return }
        onNavigate?(temple)
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        startMarkerSizeUpdates()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        stopMarkerSizeUpdates()
        updateAllMarkerSizes()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.updateAllMarkerSizes()
        }
        scheduleBasemapWatch()
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        hasFinishedRegion = true
        finishedRegion = mapView.region
        finishedMapType = mapView.mapType
        loadWatchTimer?.invalidate()
        loadWatchTimer = nil
        hideFallback()
    }

    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        // A later tile request can fail while an earlier one is still pending.
        // The load watch, not this callback, decides when the coastline appears.
        _ = error
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tiles = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tiles)
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    private func applyPathUsable(_ usable: Bool) {
        let becameUsable = usable && !pathUsable
        pathUsable = usable
        if !usable {
            retryTimer?.invalidate()
            retryTimer = nil
            scheduleBasemapWatch()
            return
        }
        if becameUsable, fallbackVisible {
            retryAppleBasemap()
        }
    }

    private func scheduleBasemapWatch() {
        loadWatchTimer?.invalidate()
        loadWatchTimer = nil
        if regionMatchesLoadedMap() {
            hideFallback()
            return
        }
        if !pathUsable {
            showFallback()
            return
        }
        if fallbackVisible {
            return
        }
        watchGeneration += 1
        let generation = watchGeneration
        let timer = Timer(timeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self, self.watchGeneration == generation else { return }
            guard !self.regionMatchesLoadedMap() else { return }
            self.showFallback()
        }
        loadWatchTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func regionMatchesLoadedMap() -> Bool {
        guard hasFinishedRegion, finishedMapType == mapView.mapType else { return false }
        let current = mapView.region
        let span = max(finishedRegion.span.latitudeDelta, finishedRegion.span.longitudeDelta, 0.000_1)
        let centerLimit = max(span * 0.02, 0.000_1)
        let spanLimit = max(span * 0.05, 0.000_1)
        let latitudeDelta = abs(current.center.latitude - finishedRegion.center.latitude)
        let longitudeDelta = abs(current.center.longitude - finishedRegion.center.longitude)
        let latitudeSpanDelta = abs(current.span.latitudeDelta - finishedRegion.span.latitudeDelta)
        let longitudeSpanDelta = abs(current.span.longitudeDelta - finishedRegion.span.longitudeDelta)
        return latitudeDelta < centerLimit
            && longitudeDelta < centerLimit
            && latitudeSpanDelta < spanLimit
            && longitudeSpanDelta < spanLimit
    }

    private func showFallback() {
        loadWatchTimer?.invalidate()
        loadWatchTimer = nil
        let dark = traitCollection.userInterfaceStyle == .dark
        if fallbackOverlay?.isDark != dark {
            if let overlay = fallbackOverlay {
                mapView.removeOverlay(overlay)
            }
            let overlay = CoastlineTileOverlay(isDark: dark)
            fallbackOverlay = overlay
            mapView.addOverlay(overlay)
        }
        if !fallbackVisible {
            fallbackVisible = true
            onBasemapFallback?(true)
        }
        scheduleBasemapRetryIfNeeded()
    }

    private func hideFallback() {
        retryTimer?.invalidate()
        retryTimer = nil
        if let overlay = fallbackOverlay {
            mapView.removeOverlay(overlay)
            fallbackOverlay = nil
        }
        guard fallbackVisible else { return }
        fallbackVisible = false
        onBasemapFallback?(false)
    }

    private func scheduleBasemapRetryIfNeeded() {
        guard pathUsable, fallbackVisible, retryTimer == nil else { return }
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            self?.retryAppleBasemap()
        }
        retryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func retryAppleBasemap() {
        guard pathUsable else { return }
        let generation = watchGeneration
        hideFallback()
        let region = mapView.region
        if region.span.latitudeDelta > 0, region.span.longitudeDelta > 0 {
            mapView.setRegion(region, animated: false)
        }
        if watchGeneration == generation {
            scheduleBasemapWatch()
        }
    }

    private func startMarkerSizeUpdates() {
        guard markerLink == nil else { return }
        let link = CADisplayLink(target: markerProxy, selector: #selector(MarkerProxy.tick))
        link.add(to: .main, forMode: .common)
        markerLink = link
    }

    private func stopMarkerSizeUpdates() {
        markerLink?.invalidate()
        markerLink = nil
    }

    private func schedulePostRebuildSizeUpdates() {
        postRebuildTimer?.invalidate()
        var ticks = 0
        postRebuildTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            self?.updateAllMarkerSizes()
            ticks += 1
            if ticks >= 30 {
                timer.invalidate()
                self?.postRebuildTimer = nil
            }
        }
    }

    @objc func updateAllMarkerSizes() {
        let altitude = mapView.camera.altitude
        for annotation in mapView.annotations.compactMap({ $0 as? MapPoint }) {
            if let marker = mapView.view(for: annotation) as? ResizableMarkerAnnotationView {
                marker.updateSize(for: altitude)
                marker.layoutPlaceCallout()
            }
        }
        updateLabelVisibility()
    }

    /// About the width of a country on screen. Wider views are country level or above.
    private func isCountryLevelOrWider() -> Bool {
        let rect = mapView.visibleMapRect
        guard rect.width > 0 else { return true }
        let west = MKMapPoint(x: rect.minX, y: rect.midY)
        let east = MKMapPoint(x: rect.maxX, y: rect.midY)
        return west.distance(to: east) >= 1_500_000
    }

    private func hideAllPlaceLabels() {
        for annotation in mapView.annotations {
            guard let marker = mapView.view(for: annotation) as? ResizableMarkerAnnotationView else { continue }
            if marker.titleVisibility != .hidden {
                marker.titleVisibility = .hidden
            }
        }
    }

    /// Shows each standard map title when its screen rectangle does not cross another title or pin.
    /// Country-sized views and anything wider keep every label hidden.
    private func updateLabelVisibility() {
        let bounds = mapView.bounds
        guard bounds.width > 1, bounds.height > 1 else { return }
        if isCountryLevelOrWider() {
            hideAllPlaceLabels()
            return
        }
        let visible = bounds.insetBy(dx: -180, dy: -80)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        struct Candidate {
            let marker: ResizableMarkerAnnotationView
            let name: String
            let anchor: CGPoint
            let label: CGRect
            let balloon: CGRect
        }

        var candidates: [Candidate] = []
        var balloons: [(id: ObjectIdentifier, rect: CGRect)] = []

        for annotation in mapView.annotations {
            guard let point = annotation as? MapPoint,
                  let marker = mapView.view(for: point) as? ResizableMarkerAnnotationView else { continue }
            let anchor = mapView.convert(point.coordinate, toPointTo: mapView)
            let scale = max(marker.currentScale, 0.2)
            let balloon = CGRect(
                x: anchor.x - 14 * scale,
                y: anchor.y - 36 * scale,
                width: 28 * scale,
                height: 36 * scale
            )
            let onScreen = balloon.intersects(visible)
            if marker.isSelected && (marker.canShowCallout || marker.isShowingPlaceCallout) {
                if onScreen {
                    balloons.append((ObjectIdentifier(marker), balloon))
                }
                if marker.titleVisibility != .hidden {
                    marker.titleVisibility = .hidden
                }
                continue
            }
            if point.title != point.name {
                point.title = point.name
            }
            let font = UIFont.systemFont(ofSize: 13 * scale, weight: .medium)
            let textSize = (point.name as NSString).size(withAttributes: [.font: font])
            let width = ceil(textSize.width) + 8
            let height = ceil(textSize.height) + 2
            let label = CGRect(
                x: anchor.x - width / 2,
                y: anchor.y + 2 * scale,
                width: width,
                height: height
            )
            guard label.intersects(visible) else {
                if marker.titleVisibility != .hidden {
                    marker.titleVisibility = .hidden
                }
                continue
            }
            if onScreen {
                balloons.append((ObjectIdentifier(marker), balloon))
            }
            candidates.append(Candidate(
                marker: marker,
                name: point.name,
                anchor: anchor,
                label: label,
                balloon: balloon
            ))
        }

        candidates.sort { lhs, rhs in
            let left = hypot(lhs.anchor.x - center.x, lhs.anchor.y - center.y)
            let right = hypot(rhs.anchor.x - center.x, rhs.anchor.y - center.y)
            if left != right { return left < right }
            return lhs.name < rhs.name
        }

        var placed: [CGRect] = []
        for candidate in candidates {
            let padded = candidate.label.insetBy(dx: -4, dy: -3)
            let markerID = ObjectIdentifier(candidate.marker)
            let overlapsLabel = placed.contains { $0.intersects(padded) }
            let overlapsPin = balloons.contains { obstacle in
                obstacle.id != markerID && obstacle.rect.intersects(padded)
            }
            let show = !overlapsLabel && !overlapsPin
            let desired: MKFeatureVisibility = show ? .visible : .hidden
            if candidate.marker.titleVisibility != desired {
                candidate.marker.titleVisibility = desired
            }
            if show {
                placed.append(padded)
            }
        }
    }

    private final class MarkerProxy: NSObject {
        weak var owner: HolyPlacesMapController?
        @objc func tick() {
            owner?.updateAllMarkerSizes()
        }
    }
}

/// Natural Earth 1:110m coastline, public domain. Drawn locally when Apple’s tiles do not arrive.
private final class CoastlineTileOverlay: MKTileOverlay {
    let isDark: Bool
    private let cache = NSCache<NSString, NSData>()

    init(isDark: Bool) {
        self.isDark = isDark
        super.init(urlTemplate: nil)
        canReplaceMapContent = true
        tileSize = CGSize(width: 256, height: 256)
        minimumZ = 0
        maximumZ = 22
        cache.countLimit = 180
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let key = "\(path.z)/\(path.x)/\(path.y)/\(isDark ? 1 : 0)/\(path.contentScaleFactor)" as NSString
        if let cached = cache.object(forKey: key) {
            result(cached as Data, nil)
            return
        }
        let data = renderTile(at: path)
        if let data {
            cache.setObject(data as NSData, forKey: key)
        }
        result(data, nil)
    }

    private func renderTile(at path: MKTileOverlayPath) -> Data? {
        let tileRect = mapRect(for: path)
        guard tileRect.size.width > 0, tileRect.size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(path.contentScaleFactor, 1)
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format)
        let fill = isDark
            ? UIColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1)
            : UIColor(red: 0.89, green: 0.93, blue: 0.95, alpha: 1)
        let stroke = isDark
            ? UIColor(red: 0.78, green: 0.82, blue: 0.86, alpha: 1)
            : UIColor(red: 0.28, green: 0.36, blue: 0.42, alpha: 1)
        let image = renderer.image { _ in
            fill.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 256, height: 256)).fill()
            let line = UIBezierPath()
            line.lineWidth = 1.25
            line.lineJoinStyle = .round
            line.lineCapStyle = .round
            for segment in CoastlineChart.shared.segments(intersecting: tileRect) {
                line.move(to: point(segment.a, in: tileRect))
                line.addLine(to: point(segment.b, in: tileRect))
            }
            stroke.setStroke()
            line.stroke()
        }
        return image.pngData()
    }

    private func point(_ mapPoint: MKMapPoint, in tileRect: MKMapRect) -> CGPoint {
        CGPoint(
            x: (mapPoint.x - tileRect.origin.x) / tileRect.size.width * 256,
            y: (mapPoint.y - tileRect.origin.y) / tileRect.size.height * 256
        )
    }

    /// Web Mercator tile rect. Tile y grows south, matching `MKMapRect`.
    private func mapRect(for path: MKTileOverlayPath) -> MKMapRect {
        let world = MKMapRect.world
        let span = min(max(path.z, 0), 29)
        let tiles = Double(1 << span)
        let width = world.size.width / tiles
        let height = world.size.height / tiles
        return MKMapRect(
            x: world.origin.x + Double(path.x) * width,
            y: world.origin.y + Double(path.y) * height,
            width: width,
            height: height
        )
    }
}

private struct CoastSegment {
    let id: Int
    let a: MKMapPoint
    let b: MKMapPoint
}

private final class CoastlineChart {
    static let shared = CoastlineChart()

    private let bucketCount = 32
    private var buckets: [[CoastSegment]]

    private init() {
        buckets = Array(repeating: [], count: bucketCount * bucketCount)
        load()
    }

    func segments(intersecting rect: MKMapRect) -> [CoastSegment] {
        let world = MKMapRect.world
        guard world.size.width > 0, world.size.height > 0 else { return [] }
        let minColumn = column(forX: rect.minX, world: world)
        let maxColumn = column(forX: rect.maxX, world: world)
        let minRow = row(forY: rect.minY, world: world)
        let maxRow = row(forY: rect.maxY, world: world)
        var seen = Set<Int>()
        var result: [CoastSegment] = []
        for rowIndex in minRow...maxRow {
            for columnIndex in minColumn...maxColumn {
                for segment in buckets[rowIndex * bucketCount + columnIndex] {
                    guard seen.insert(segment.id).inserted, intersects(segment, rect) else { continue }
                    result.append(segment)
                }
            }
        }
        return result
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "ne_110m_coastline", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = object["features"] as? [[String: Any]] else { return }
        var nextID = 0
        for feature in features {
            guard let geometry = feature["geometry"] as? [String: Any] else { continue }
            for line in lines(from: geometry) where line.count >= 2 {
                for index in 1..<line.count {
                    append(from: line[index - 1], to: line[index], nextID: &nextID)
                }
            }
        }
    }

    private func lines(from geometry: [String: Any]) -> [[[Double]]] {
        guard let type = geometry["type"] as? String else { return [] }
        switch type {
        case "LineString":
            return [coordinateLine(geometry["coordinates"])]
        case "MultiLineString":
            guard let parts = geometry["coordinates"] as? [Any] else { return [] }
            return parts.map { coordinateLine($0) }
        default:
            return []
        }
    }

    private func coordinateLine(_ value: Any?) -> [[Double]] {
        guard let pairs = value as? [Any] else { return [] }
        return pairs.compactMap { pair in
            guard let pair = pair as? [Any], pair.count >= 2,
                  let longitude = doubleValue(pair[0]),
                  let latitude = doubleValue(pair[1]) else { return nil }
            return [longitude, latitude]
        }
    }

    private func doubleValue(_ value: Any) -> Double? {
        (value as? NSNumber)?.doubleValue
    }

    private func append(from start: [Double], to end: [Double], nextID: inout Int) {
        let startLongitude = normalize(start[0])
        let endLongitude = normalize(end[0])
        let startLatitude = start[1]
        let endLatitude = end[1]
        if abs(startLongitude - endLongitude) <= 180 {
            add(startLongitude, startLatitude, endLongitude, endLatitude, nextID: &nextID)
            return
        }
        let startEdge: Double = startLongitude >= 0 ? 180 : -180
        let endEdge: Double = endLongitude >= 0 ? 180 : -180
        let startDistance = abs(startEdge - startLongitude)
        let endDistance = abs(endEdge - endLongitude)
        let total = startDistance + endDistance
        let fraction = total > 0 ? startDistance / total : 0
        let latitude = startLatitude + (endLatitude - startLatitude) * fraction
        add(startLongitude, startLatitude, startEdge, latitude, nextID: &nextID)
        add(endEdge, latitude, endLongitude, endLatitude, nextID: &nextID)
    }

    private func add(
        _ startLongitude: Double,
        _ startLatitude: Double,
        _ endLongitude: Double,
        _ endLatitude: Double,
        nextID: inout Int
    ) {
        let start = mapPoint(latitude: startLatitude, longitude: startLongitude)
        let end = mapPoint(latitude: endLatitude, longitude: endLongitude)
        guard start.x != end.x || start.y != end.y else { return }
        let segment = CoastSegment(id: nextID, a: start, b: end)
        nextID += 1
        insert(segment)
    }

    private func mapPoint(latitude: Double, longitude: Double) -> MKMapPoint {
        let limit = 85.05112878
        let clamped = min(limit, max(-limit, latitude))
        return MKMapPoint(CLLocationCoordinate2D(latitude: clamped, longitude: longitude))
    }

    private func normalize(_ longitude: Double) -> Double {
        guard longitude.isFinite else { return 0 }
        var value = longitude
        while value > 180 { value -= 360 }
        while value < -180 { value += 360 }
        return value
    }

    private func insert(_ segment: CoastSegment) {
        let world = MKMapRect.world
        guard world.size.width > 0, world.size.height > 0 else { return }
        let minColumn = column(forX: min(segment.a.x, segment.b.x), world: world)
        let maxColumn = column(forX: max(segment.a.x, segment.b.x), world: world)
        let minRow = row(forY: min(segment.a.y, segment.b.y), world: world)
        let maxRow = row(forY: max(segment.a.y, segment.b.y), world: world)
        for rowIndex in minRow...maxRow {
            for columnIndex in minColumn...maxColumn {
                buckets[rowIndex * bucketCount + columnIndex].append(segment)
            }
        }
    }

    private func intersects(_ segment: CoastSegment, _ rect: MKMapRect) -> Bool {
        let minX = min(segment.a.x, segment.b.x)
        let maxX = max(segment.a.x, segment.b.x)
        let minY = min(segment.a.y, segment.b.y)
        let maxY = max(segment.a.y, segment.b.y)
        let bounds = MKMapRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 1),
            height: max(maxY - minY, 1)
        )
        return rect.intersects(bounds)
    }

    private func column(forX x: Double, world: MKMapRect) -> Int {
        let ratio = (x - world.origin.x) / world.size.width
        return min(bucketCount - 1, max(0, Int(ratio * Double(bucketCount))))
    }

    private func row(forY y: Double, world: MKMapRect) -> Int {
        let ratio = (y - world.origin.y) / world.size.height
        return min(bucketCount - 1, max(0, Int(ratio * Double(bucketCount))))
    }
}
