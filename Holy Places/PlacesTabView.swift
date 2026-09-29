//
//  PlacesTabView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreLocation
import MapKit
import SafariServices
import SwiftUI
import UIKit

extension Temple {
    var listID: String { stablePlaceID(self) }
}

struct PlaceListSection: Identifiable {
    let id: String
    let title: String
    let places: [Temple]
}

@MainActor
final class PlacesListModel: ObservableObject {
    @Published var sections: [PlaceListSection] = []
    @Published var title = "All Holy Places"
    @Published var subtitle = "Alphabetical Order"
    @Published var titleColor = Color(uiColor: defaultColor)
    @Published var searchText = ""
    @Published var scope = "All"
    @Published var nearestEnabled = false
    @Published var displayedPlaces: [Temple] = []

    private var sortByCountry = false
    private var sortByDedicationDate = false
    private var sortBySize = false
    private var sortByAnnouncedDate = false

    init() {
        applySortRow(placeSortRow)
        reload()
    }

    func apply(_ route: PlacesRoute) {
        if route.nearest {
            placeSortRow = 1
            placeFilterRow = 0
            locationSpecific = false
            applySortRow(1)
        }
        if let search = route.search {
            searchText = search
        }
        reload()
    }

    func place(named name: String) -> Temple? {
        allPlaces.first { $0.templeName == name }
    }

    func place(id: String) -> Temple? {
        allPlaces.first { $0.listID == id }
    }

    func randomPlace() -> Temple? {
        allPlaces.randomElement()
    }

    func applyOptions(filter: Int, sort: Int) {
        placeFilterRow = filter
        placeSortRow = sort
        applySortRow(sort)
        if sort == 1 {
            ad.locationServiceSetup()
        }
        optionsChanged = true
        reload()
        optionsChanged = false
    }

    func reload() {
        applySortRow(placeSortRow)
        var list = placesForFilter(placeFilterRow)
        if scope == "Visited" {
            list = list.filter { visits.contains($0.templeName) }
        } else if scope == "Not Visited" {
            list = list.filter { !visits.contains($0.templeName) }
        }
        let terms = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        if !terms.isEmpty {
            list = list.filter { place in
                let searchable = place.listSearchText.lowercased()
                return terms.allSatisfy { searchable.contains($0.lowercased()) }
            }
        }
        places = list
        displayedPlaces = list
        sections = makeSections(from: list)
        updateTitle(count: list.count)
        nearestEnabled = sortByCurrentLocation
    }

    private var sortByCurrentLocation: Bool { placeSortRow == 1 }

    private func applySortRow(_ row: Int) {
        nearestEnabled = false
        sortByCountry = false
        sortByDedicationDate = false
        sortBySize = false
        sortByAnnouncedDate = false
        if row == 1 {
            nearestEnabled = true
        } else if row == 2 {
            sortByCountry = true
        } else if row == 3 {
            if placeFilterRow == 1 { sortByDedicationDate = true }
            if [4, 5, 6].contains(placeFilterRow) { sortByAnnouncedDate = true }
        } else if row == 4 {
            sortBySize = true
        } else if row == 5, placeFilterRow == 1 {
            sortByAnnouncedDate = true
        }
    }

    private func placesForFilter(_ row: Int) -> [Temple] {
        switch row {
        case 0: return allPlaces
        case 1: return activeTemples
        case 2: return historical
        case 3: return visitors
        case 4: return construction
        case 5: return announced
        default: return allTemples
        }
    }

    private func updateTitle(count: Int) {
        let name: String
        switch placeFilterRow {
        case 0: name = "All Holy Places"
        case 1: name = "Active Temples"
        case 2: name = "Historical Sites"
        case 3: name = "Visitors' Centers"
        case 4: name = "Construction"
        case 5: name = "Announced"
        default: name = "All Temples"
        }
        title = "\(name) (\(count))"
        if nearestEnabled {
            if locationSpecific {
                if altLocState != "" || altLocCity != "" {
                    subtitle = "Nearest to \(altLocCity) \(altLocState)"
                } else if altLocPostalCode != "" {
                    subtitle = "Nearest to \(altLocPostalCode)"
                } else {
                    subtitle = "Nearest to \(altLocStreet)"
                }
            } else {
                subtitle = "Nearest to Current Location"
            }
        } else if sortByDedicationDate {
            subtitle = "by Dedication Date"
        } else if sortByAnnouncedDate {
            subtitle = "by Announced Date"
        } else if sortBySize {
            subtitle = "by Size"
        } else if sortByCountry {
            subtitle = "by Country"
        } else {
            subtitle = "Alphabetical Order"
        }
        let uiColor: UIColor
        switch placeFilterRow {
        case 1: uiColor = templeColor
        case 2: uiColor = historicalColor
        case 3: uiColor = visitorCenterColor
        case 4: uiColor = constructionColor
        case 5: uiColor = announcedColor
        default: uiColor = defaultColor
        }
        titleColor = Color(uiColor: uiColor)
    }

    private func makeSections(from source: [Temple]) -> [PlaceListSection] {
        var list = source
        guard !list.isEmpty else { return [] }
        if nearestEnabled {
            ad.updateDistance(placesToUpdate: list, true)
            list.sort { Int($0.distance ?? 0) < Int($1.distance ?? 0) }
            places = list
            displayedPlaces = list
            return [PlaceListSection(id: "nearest", title: "", places: list)]
        }
        if sortByDedicationDate {
            list.sort { $0.templeOrder < $1.templeOrder }
            return grouped(list) { place in
                switch place.templeOrder {
                case 1...4: return "Pioneer Era ~ 1877-1893"
                case 5...12: return "Expansion Era ~ 1919-1958"
                case 13...20: return "Strengthening Era ~ 1964-1981"
                case 21...53: return "Growth Era ~ 1983-1998"
                case 54...114: return "Explosive Era ~ 1999-2002"
                case 115...161: return "Hastening Era ~ 2003-2018"
                default:
                    let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year ?? 2023
                    return "Unparalleled Era ~ 2019-\(year)"
                }
            }
        }
        if sortByAnnouncedDate {
            list.sort {
                switch ($0.templeAnnouncedDate, $1.templeAnnouncedDate) {
                case let (d1?, d2?): return d1 > d2
                case (_?, nil): return true
                case (nil, _?): return false
                default: return false
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            return grouped(list) { place in
                guard let date = place.templeAnnouncedDate else { return "" }
                return formatter.string(from: date)
            }
        }
        if sortBySize {
            list.sort {
                let left = Double($0.templeSqFt ?? 0)
                let right = Double($1.templeSqFt ?? 0)
                if left == right { return $0.templeName < $1.templeName }
                return left > right
            }
            return grouped(list) { place in
                switch place.templeSqFt ?? 0 {
                case 100000...: return "Over 100K sqft"
                case 60000...99999: return "60K - 100K sqft"
                case 30000...59999: return "30K - 60K sqft"
                case 12000...29999: return "12K - 30K sqft"
                default: return "Under 12K sqft"
                }
            }
        }
        if sortByCountry {
            list.sort {
                let country = $0.templeCountry.compare($1.templeCountry)
                if country == .orderedSame { return $0.templeName < $1.templeName }
                return country == .orderedAscending
            }
            return grouped(list) { $0.templeCountry }
        }
        list.sort { $0.templeName < $1.templeName }
        places = list
        displayedPlaces = list
        return [PlaceListSection(id: "alphabetical", title: "", places: list)]
    }

    private func grouped(_ list: [Temple], key: (Temple) -> String) -> [PlaceListSection] {
        places = list
        displayedPlaces = list
        var sections: [PlaceListSection] = []
        var currentKey = ""
        var bucket: [Temple] = []
        func flush() {
            guard !bucket.isEmpty else { return }
            let title = currentKey.isEmpty ? "" : "\(currentKey) (\(bucket.count))"
            let id = "\(sections.count)-\(currentKey)"
            sections.append(PlaceListSection(id: id, title: title, places: bucket))
        }
        for place in list {
            let next = key(place)
            if bucket.isEmpty {
                currentKey = next
            } else if next.caseInsensitiveCompare(currentKey) != .orderedSame {
                flush()
                bucket = []
                currentKey = next
            }
            bucket.append(place)
        }
        flush()
        return sections
    }
}

struct PlacesTabView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var model = PlacesListModel()
    @StateObject private var detailModel = PlaceDetailModel()
    @State private var selectedID: String?
    @State private var visiblePlaceIDs: Set<String> = []
    @State private var recordModel: RecordVisitModel?
    @State private var pendingID: String?
    @State private var showDiscard = false
    @State private var showOptions = false
    @State private var showAltLocation = false
    @State private var photo: IdentifiedImage?
    @State private var safariURL: URL?
    @State private var showNavigation = false
    @State private var mapFocus: MapFocusItem?

    var body: some View {
        AdaptiveSplit(widenSidebar: true) {
            list
        } detail: {
            detail
        }
        .fullScreenCover(item: $photo) { item in
            PhotoViewerView(image: item.image) { photo = nil }
        }
        .fullScreenCover(item: $mapFocus) { focus in
            MapFocusCover(places: focus.places, center: focus.center, zoom: focus.zoom) {
                mapFocus = nil
            }
        }
        .sheet(isPresented: $showOptions) {
            PlaceOptionsSheet { filter, sort in
                model.applyOptions(filter: filter, sort: sort)
            }
        }
        .sheet(isPresented: $showAltLocation) {
            AltLocationSheet {
                model.reload()
            }
        }
        .sheet(item: $safariURL) { url in
            SafariSheet(url: url)
        }
        .confirmationDialog("Navigate to Holy Place", isPresented: $showNavigation, titleVisibility: .visible) {
            navigationButtons
        }
        .alert("Discard this visit?", isPresented: $showDiscard) {
            Button("Discard", role: .destructive) {
                recordModel = nil
                applySelection(pendingID)
                pendingID = nil
            }
            Button("Keep Editing", role: .cancel) {
                pendingID = nil
            }
        } message: {
            Text("You have unsaved changes.")
        }
        .onChange(of: router.placesRoute) { _, route in
            guard let route else { return }
            model.apply(route)
            if route.random, let place = model.randomPlace() {
                select(place.listID, force: true)
            } else if let id = route.templeId {
                select(id, force: true)
            } else if let name = route.placeName, let place = model.place(named: name) {
                select(place.listID, force: true)
            }
            router.placesRoute = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .reload)) { _ in
            if model.nearestEnabled { model.reload() }
        }
        .onAppear {
            applyHolyPlacesSearchFont()
            if optionsChanged || themeChanged {
                model.reload()
                optionsChanged = false
                themeChanged = false
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List(selection: selection) {
                ForEach(model.sections) { section in
                    if section.title.isEmpty {
                        placeRows(section.places)
                    } else {
                        Section {
                            placeRows(section.places)
                        } header: {
                            Text(section.title)
                                .font(.custom("Baskerville", size: 22))
                                .foregroundStyle(Color("BaptismsBlue"))
                                .textCase(nil)
                        }
                    }
                }
            }
            .onChange(of: selectedID) { _, id in
                guard let id, !visiblePlaceIDs.contains(id) else { return }
                proxy.scrollTo(id, anchor: .center)
            }
            .listStyle(.plain)
            .environment(\.defaultMinListHeaderHeight, 0)
            .contentMargins(.top, 0, for: .scrollContent)
        }
        .environment(\.defaultMinListRowHeight, 50)
        .searchable(
            text: $model.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search")
        )
        .background(HolyPlacesSearchFontFix())
        .onChange(of: model.searchText) { _, _ in model.reload() }
        .safeAreaInset(edge: .top, spacing: 0) {
            PlaceScopeSegments(scope: $model.scope)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(uiColor: .systemBackground))
                .onChange(of: model.scope) { _, _ in model.reload() }
        }
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(model.title)
                        .font(.custom("Baskerville", size: 19))
                        .foregroundStyle(model.titleColor)
                    Text(model.subtitle)
                        .font(.custom("Baskerville", size: 15))
                        .foregroundStyle(.gray)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                if model.nearestEnabled {
                    Button("Location") { showAltLocation = true }
                        .font(.custom("Baskerville", size: 17))
                        .foregroundStyle(Color("BaptismsBlue"))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Options") { showOptions = true }
                    .font(.custom("Baskerville", size: 17))
                    .foregroundStyle(Color("BaptismsBlue"))
            }
        }
    }

    private var selection: Binding<String?> {
        Binding(
            get: { selectedID },
            set: { select($0, force: false) }
        )
    }

    @ViewBuilder
    private var detail: some View {
        if let recordModel {
            RecordVisitForm(model: recordModel, onCancel: {
                self.recordModel = nil
                refreshDetail()
            }, onSaved: {
                self.recordModel = nil
                model.reload()
                refreshDetail()
            })
        } else if selectedID != nil {
            PlaceDetailView(model: detailModel, actions: detailActions)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Map") { openMap() }
                            .font(.custom("Baskerville", size: 17))
                    }
                }
        } else {
            ContentUnavailableView("Select a place", systemImage: "building.columns", description: Text("Choose a place from the list."))
        }
    }

    private var detailActions: PlaceDetailActions {
        PlaceDetailActions(
            openImage: { photo = IdentifiedImage(image: $0) },
            openURL: { string in
                if let url = URL(string: string) { safariURL = url }
            },
            openRecordVisit: { startRecording() },
            openNavigationOptions: { showNavigation = true },
            swipePlace: { swipe(by: $0) }
        )
    }

    @ViewBuilder
    private var navigationButtons: some View {
        if let place = detailModel.place {
            let coordinate = CLLocationCoordinate2D(latitude: place.templeLatitude, longitude: place.templeLongitude)
            Button("Apple Maps") {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                item.name = place.templeName
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            }
            if let google = URL(string: "comgooglemaps://"), UIApplication.shared.canOpenURL(google) {
                Button("Google Maps") {
                    let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")!
                    UIApplication.shared.open(url)
                }
            }
            if let waze = URL(string: "waze://"), UIApplication.shared.canOpenURL(waze) {
                Button("Waze") {
                    let url = URL(string: "waze://?ll=\(coordinate.latitude),\(coordinate.longitude)&navigate=yes")!
                    UIApplication.shared.open(url)
                }
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    private func placeRows(_ places: [Temple]) -> some View {
        ForEach(places, id: \.listID) { place in
            placeRow(place)
                .tag(place.listID)
                .id(place.listID)
                .onAppear { visiblePlaceIDs.insert(place.listID) }
                .onDisappear { visiblePlaceIDs.remove(place.listID) }
        }
    }

    private func placeRow(_ place: Temple) -> some View {
        let subtitle = rowSubtitle(place)
        let color = Color(uiColor: rowColor(place.templeType))
        return HStack(spacing: 8) {
            if let symbol = placeTypeSymbolImage(for: place.templeType) {
                Image(uiImage: symbol)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(place.templeName)
                    .font(.custom("Baskerville", size: 18))
                    .foregroundStyle(color)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.custom("Baskerville", size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(minHeight: 44)
    }

    private func rowSubtitle(_ place: Temple) -> String {
        if model.nearestEnabled {
            let meters = place.distance ?? 0
            let miles = Int(meters * 0.000621371)
            let distance = miles == 0 ? "\(Int(meters * 3.28084)) ft - " : "\(miles) mi. - "
            return " " + distance + place.templeSnippet
        }
        if placeSortRow == 4 || model.subtitle == "by Size" {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formatted = formatter.string(from: NSNumber(value: place.templeSqFt ?? 0)) ?? ""
            return " \(formatted) sq ft - \(place.templeSnippet)"
        }
        return " " + place.templeSnippet
    }

    private func rowColor(_ type: String) -> UIColor {
        switch type {
        case "T": return templeColor
        case "H": return historicalColor
        case "A": return announcedColor
        case "C": return constructionColor
        case "V": return visitorCenterColor
        default: return defaultColor
        }
    }

    private func select(_ id: String?, force: Bool) {
        if !force, let recordModel, recordModel.isDirty, id != selectedID {
            pendingID = id
            showDiscard = true
            return
        }
        applySelection(id)
    }

    private func applySelection(_ id: String?) {
        selectedID = id
        guard let id, let place = model.place(id: id) ?? model.displayedPlaces.first(where: { $0.listID == id }) else {
            detailItem = nil
            return
        }
        detailItem = place
        if let index = model.displayedPlaces.firstIndex(where: { $0.listID == id }) {
            selectedPlaceRow = index
        }
        detailModel.load(place: place)
    }

    private func refreshDetail() {
        detailModel.refreshIfNeeded(reloadImages: true)
    }

    private func startRecording() {
        guard let place = detailModel.place else { return }
        recordModel = RecordVisitModel(place: place)
    }

    private func swipe(by delta: Int) {
        let list = model.displayedPlaces
        guard let current = selectedID, let index = list.firstIndex(where: { $0.listID == current }) else { return }
        let next = index + delta
        guard list.indices.contains(next) else { return }
        select(list[next].listID, force: false)
    }

    private func openMap() {
        guard let place = detailModel.place else { return }
        let coordinate = CLLocationCoordinate2D(latitude: place.templeLatitude, longitude: place.templeLongitude)
        var focus = model.displayedPlaces
        if focus.isEmpty { focus = [place] }
        if !focus.contains(where: { $0.listID == place.listID }) {
            focus.append(place)
        }
        mapFocus = MapFocusItem(places: focus, center: coordinate, zoom: 4000)
    }
}

private struct MapFocusItem: Identifiable {
    let id = UUID()
    let places: [Temple]
    let center: CLLocationCoordinate2D
    let zoom: CLLocationDistance
}

private struct IdentifiedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

private struct ColoredFilterPicker: UIViewRepresentable {
    var titles: [String]
    @Binding var selection: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.appliedTitles != titles {
            context.coordinator.appliedTitles = titles
            picker.reloadAllComponents()
        }
        let row = min(max(selection, 0), max(titles.count - 1, 0))
        if !titles.isEmpty, picker.selectedRow(inComponent: 0) != row {
            picker.selectRow(row, inComponent: 0, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: ColoredFilterPicker
        var appliedTitles: [String] = []

        init(_ parent: ColoredFilterPicker) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.titles.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 36 }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.textAlignment = .center
            let title = parent.titles[row]
            let font = UIFont(name: "Baskerville", size: 20) ?? .systemFont(ofSize: 20)
            let color = colorForPlaceTypeCode(placeTypeCode(forFilterTitle: title))
            label.attributedText = attributedPlaceTypeFilterTitle(title, font: font, color: color)
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selection = row
        }
    }
}

private struct PlaceOptionsSheet: View {
    var onDone: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var filter: Int
    @State private var sort: Int

    private let filters = ["All Holy Places", "Active Temples", "Historical Sites", "Visitors' Centers", "Temples Under Construction", "Announced Temples", "All Temples"]

    init(onDone: @escaping (Int, Int) -> Void) {
        self.onDone = onDone
        _filter = State(initialValue: placeFilterRow)
        _sort = State(initialValue: placeSortRow)
    }

    private var sorts: [String] {
        if filter == 1 {
            return ["Alphabetical", "Nearest", "Country", "Dedication Date", "Size", "Announced Date"]
        }
        if [4, 5, 6].contains(filter) {
            return ["Alphabetical", "Nearest", "Country", "Announced Date"]
        }
        return ["Alphabetical", "Nearest", "Country"]
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("Filter")
                    .font(.custom("Baskerville", size: 17))
                ColoredFilterPicker(titles: filters, selection: $filter)
                    .frame(height: 180)
                    .onChange(of: filter) { _, _ in
                        if sort >= sorts.count { sort = 0 }
                    }
                Text("Sort")
                    .font(.custom("Baskerville", size: 17))
                Picker("Sort", selection: $sort) {
                    ForEach(sorts.indices, id: \.self) { index in
                        Text(sorts[index]).tag(index)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(filter, sort)
                        dismiss()
                    }
                    .font(.custom("Baskerville", size: 17))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct PlaceScopeSegments: UIViewRepresentable {
    @Binding var scope: String
    private static let titles = ["All", "Visited", "Not Visited"]

    func makeCoordinator() -> Coordinator {
        Coordinator(scope: $scope)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: Self.titles)
        control.selectedSegmentIndex = Self.titles.firstIndex(of: scope) ?? 0
        let font = UIFont(name: "Baskerville", size: 16) ?? .systemFont(ofSize: 16)
        control.setTitleTextAttributes([.font: font], for: .normal)
        control.setTitleTextAttributes([.font: font], for: .selected)
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        context.coordinator.scope = $scope
        let index = Self.titles.firstIndex(of: scope) ?? 0
        if control.selectedSegmentIndex != index {
            control.selectedSegmentIndex = index
        }
    }

    final class Coordinator: NSObject {
        var scope: Binding<String>
        init(scope: Binding<String>) { self.scope = scope }

        @objc func changed(_ sender: UISegmentedControl) {
            guard PlaceScopeSegments.titles.indices.contains(sender.selectedSegmentIndex) else { return }
            scope.wrappedValue = PlaceScopeSegments.titles[sender.selectedSegmentIndex]
        }
    }
}

private struct PlaceBoolSegments: UIViewRepresentable {
    var titles: [String]
    @Binding var isOn: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isOn: $isOn)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: titles)
        control.selectedSegmentIndex = isOn ? 1 : 0
        let font = UIFont(name: "Baskerville", size: 17) ?? .systemFont(ofSize: 17)
        control.setTitleTextAttributes([.font: font], for: .normal)
        control.setTitleTextAttributes([.font: font], for: .selected)
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        context.coordinator.isOn = $isOn
        let index = isOn ? 1 : 0
        if control.selectedSegmentIndex != index {
            control.selectedSegmentIndex = index
        }
    }

    final class Coordinator: NSObject {
        var isOn: Binding<Bool>
        init(isOn: Binding<Bool>) { self.isOn = isOn }

        @objc func changed(_ sender: UISegmentedControl) {
            isOn.wrappedValue = sender.selectedSegmentIndex == 1
        }
    }
}

private struct AltLocationSheet: View {
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var street = altLocStreet
    @State private var city = altLocCity
    @State private var state = altLocState
    @State private var postal = altLocPostalCode
    @State private var result = ""
    @State private var useAlternate = locationSpecific

    var body: some View {
        NavigationStack {
            Form {
                PlaceBoolSegments(
                    titles: ["Current", "Alternate"],
                    isOn: $useAlternate
                )
                .disabled(coordAltLocation == nil && !useAlternate)
                TextField("Street", text: $street)
                    .font(.custom("Baskerville", size: 17))
                TextField("City", text: $city)
                    .font(.custom("Baskerville", size: 17))
                TextField("State", text: $state)
                    .font(.custom("Baskerville", size: 17))
                TextField("Postal code", text: $postal)
                    .font(.custom("Baskerville", size: 17))
                Button("Validate") { validate() }
                    .font(.custom("Baskerville", size: 17))
                Text(result)
                    .font(.custom("Baskerville", size: 15))
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        locationSpecific = useAlternate
                        optionsChanged = true
                        onDone()
                        dismiss()
                    }
                    .font(.custom("Baskerville", size: 17))
                }
            }
        }
        .onAppear {
            if let coordinate = coordAltLocation?.coordinate {
                result = "latitude: \(coordinate.latitude)\nlongitude: \(coordinate.longitude)"
            }
        }
    }

    private func validate() {
        let address = "\(street) \(city) \(state) \(postal)".trimmingCharacters(in: .whitespaces)
        guard !address.isEmpty else {
            result = "Enter city, state or postal code"
            return
        }
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let error {
                result = "Location not found...\n\n\(error.localizedDescription)"
                return
            }
            guard let location = placemarks?.first?.location else { return }
            coordAltLocation = location
            altLocStreet = street
            altLocCity = city
            altLocState = state
            altLocPostalCode = postal
            useAlternate = true
            locationSpecific = true
            let coordinate = location.coordinate
            result = "Coordinates found! Press Done to see what is nearest.\n\nlatitude: \(coordinate.latitude)\nlongitude: \(coordinate.longitude)"
        }
    }
}
