//
//  MapTabView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import MapKit
import SwiftUI
import UIKit

final class CalloutNameButton: UIButton {
    var fittedSize = CGSize(width: 44, height: 30)

    override var intrinsicContentSize: CGSize { fittedSize }
}

final class ResizableMarkerAnnotationView: MKMarkerAnnotationView {
    var minScale: CGFloat = 0.2
    var maxScale: CGFloat = 1.0
    var currentScale: CGFloat = 1

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
                onSelect: handleSelect
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            if timelineVisible, timelineDate != nil {
                timelineChrome
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

    var body: some View {
        NavigationStack {
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
                onSelect: nil
            )
            .ignoresSafeArea()
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

    func makeUIViewController(context: Context) -> HolyPlacesMapController {
        HolyPlacesMapController()
    }

    func updateUIViewController(_ controller: HolyPlacesMapController, context: Context) {
        controller.onSelectPlace = onSelect
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
    }
}

private final class HolyPlacesMapController: UIViewController, MKMapViewDelegate {
    let mapView = MKMapView()
    var onSelectPlace: ((Temple) -> Void)?
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

    deinit {
        markerLink?.invalidate()
        postRebuildTimer?.invalidate()
        timelineWork?.cancel()
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installBrowseRegionIfNeeded()
        installFocusRegionIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAllMarkerSizes()
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
        if incremental, timelineMode, let date = timelineDate {
            applyIncremental(places: places, date: date)
        } else {
            replaceAll(places.map { mapPoint(for: $0, on: nil) })
            if let selected = mapView.selectedAnnotations.first {
                adjustingSelection = true
                mapView.deselectAnnotation(selected, animated: false)
                adjustingSelection = false
            }
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
        let current = mapView.selectedAnnotations.first as? MapPoint
        let currentName = current.flatMap { temple(for: $0)?.templeName }
        if currentName == selectedName { return }
        adjustingSelection = true
        if let current {
            mapView.deselectAnnotation(current, animated: false)
        }
        if let selectedName,
           let temple = (displayedPlaces + allPlaces).first(where: { $0.templeName == selectedName }),
           let point = annotations.first(where: { coordinatesMatch($0.coordinate, temple.cllocation.coordinate) }) {
            mapView.selectAnnotation(point, animated: false)
        }
        adjustingSelection = false
    }

    private func temple(for point: MapPoint) -> Temple? {
        if let match = displayedPlaces.first(where: { coordinatesMatch(point.coordinate, $0.cllocation.coordinate) }) {
            return match
        }
        return allPlaces.first(where: { coordinatesMatch(point.coordinate, $0.cllocation.coordinate) })
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
        marker.canShowCallout = showsCallout
        point.title = (marker.isSelected && showsCallout) ? "\u{200b}" : point.name
        marker.titleVisibility = .hidden
        if showsCallout {
            let nameFont = UIFont(name: "Baskerville", size: 20) ?? .systemFont(ofSize: 20)
            let maxNameWidth = min(280, max(200, mapView.bounds.width - 80))
            let nameButton = CalloutNameButton(type: .custom)
            nameButton.setTitle(point.name, for: .normal)
            nameButton.setTitleColor(nameColor, for: .normal)
            nameButton.titleLabel?.font = nameFont
            nameButton.titleLabel?.numberOfLines = 2
            nameButton.titleLabel?.lineBreakMode = .byWordWrapping
            nameButton.titleLabel?.textAlignment = .center
            nameButton.isUserInteractionEnabled = true
            let fitted = (point.name as NSString).boundingRect(
                with: CGSize(width: maxNameWidth, height: 64),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: nameFont],
                context: nil
            )
            nameButton.fittedSize = CGSize(
                width: min(maxNameWidth, ceil(fitted.width) + 8),
                height: max(30, ceil(fitted.height) + 4)
            )
            nameButton.frame = CGRect(origin: .zero, size: nameButton.fittedSize)
            marker.leftCalloutAccessoryView = nameButton

            let right = UIButton(type: .custom)
            right.setTitle("⤴️", for: .normal)
            right.frame = CGRect(x: 0, y: 0, width: 24, height: 30)
            marker.rightCalloutAccessoryView = right
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
        if let point = view.annotation as? MapPoint, !view.canShowCallout {
            point.title = point.name
        }
        updateAllMarkerSizes()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
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
            let placemark = MKPlacemark(coordinate: point.coordinate)
            let item = MKMapItem(placemark: placemark)
            item.name = temple(for: point)?.templeName ?? point.name
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else if let temple = temple(for: point) {
            onSelectPlace?(temple)
        }
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
            if marker.isSelected && marker.canShowCallout {
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
