//
//  VisitsTabView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreData
import StoreKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private let visitScopes = ["All", "B", "C", "I", "E", "S", "⭐️"]

private enum VisitListSelection: Hashable {
    case visit(String)
    case compose
}

struct VisitSection: Identifiable {
    let id: String
    let title: String
    let visits: [Visit]
}

private struct PresentedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ProfileChoice: Identifiable {
    let id: String
    let name: String
    let icon: String
}

struct ExportShare: Identifiable {
    let id = UUID()
    let url: URL
}

private enum VisitsNotice {
    case delete
    case discard
    case backup
    case changes(String, String)
    case copied(Int, String)
}

final class VisitsListModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var searchText = ""
    @Published var scope = "All"
    @Published var sortOption = 0
    @Published var isSelectMode = false
    @Published var selectedIDs = Set<NSManagedObjectID>()
    @Published private(set) var sections: [VisitSection] = []
    @Published private(set) var displayedCount = 0
    @Published private(set) var unfilteredCount = 0
    @Published private(set) var showEmptyState = false
    @Published private(set) var revision = 0

    let sortOptions = ["Latest Date", "Oldest Date", "Place (A-Z)", "Place (Z-A)"]
    let listDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd, yyyy"
        return formatter
    }()

    private var fetchedController: NSFetchedResultsController<Visit>?

    var titleName: String {
        switch visitFilterRow {
        case 1: return "Active Temples"
        case 2: return "Historical Sites"
        case 3: return "Visitors' Centers"
        case 4: return "Construction"
        case 5: return "Other Visits"
        default: return "Visits"
        }
    }

    var titleUIColor: UIColor {
        switch visitFilterRow {
        case 1: return templeColor
        case 2: return historicalColor
        case 3: return visitorCenterColor
        case 4: return constructionColor
        case 5: return announcedColor
        default: return defaultColor
        }
    }

    var sortSubtitle: String {
        guard sortOptions.indices.contains(sortOption) else { return sortOptions[0] }
        return sortOptions[sortOption]
    }

    var isFiltered: Bool {
        scope != "All" || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    override init() {
        super.init()
        reload()
    }

    func reload() {
        fetchedController = nil
        _ = makeController()
        publish()
    }

    func applyFilters() {
        publish()
    }

    func setSort(_ option: Int) {
        sortOption = option
        reload()
    }

    func setFilter(_ option: Int) {
        visitFilterRow = option
        reload()
    }

    func visibleVisits() -> [Visit] {
        sections.flatMap(\.visits)
    }

    func visit(uri: String) -> Visit? {
        guard let objectID = objectID(for: uri) else { return nil }
        return try? ad.persistentContainer.viewContext.existingObject(with: objectID) as? Visit
    }

    func enterSelect() {
        isSelectMode = true
        selectedIDs.removeAll()
    }

    func exitSelect() {
        isSelectMode = false
        selectedIDs.removeAll()
    }

    func toggleURI(_ uri: String) {
        guard let objectID = objectID(for: uri) else { return }
        if selectedIDs.contains(objectID) {
            selectedIDs.remove(objectID)
        } else {
            selectedIDs.insert(objectID)
        }
    }

    func selectAllVisible() {
        let visible = visibleVisits()
        let allSelected = !visible.isEmpty && visible.allSatisfy { selectedIDs.contains($0.objectID) }
        if allSelected {
            visible.forEach { selectedIDs.remove($0.objectID) }
        } else {
            visible.forEach { selectedIDs.insert($0.objectID) }
        }
    }

    func delete(_ objectID: NSManagedObjectID) {
        let context = ad.persistentContainer.viewContext
        guard let visit = try? context.existingObject(with: objectID) as? Visit else { return }
        context.delete(visit)
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        ad.needsVisitRefresh = true
        ad.getVisits()
        selectedIDs.remove(objectID)
    }

    @discardableResult
    func copySelected(to profileId: String) -> Int {
        let context = ad.persistentContainer.viewContext
        let rows = selectedIDs.compactMap { try? context.existingObject(with: $0) as? Visit }
        guard !rows.isEmpty else { return 0 }
        for source in rows {
            let copy = Visit(context: context)
            copy.holyPlace = source.holyPlace
            copy.dateVisited = source.dateVisited
            if let dateVisited = source.dateVisited {
                copy.year = ad.calendarYearString(for: dateVisited)
            } else {
                copy.year = source.year
            }
            copy.type = source.type
            copy.profileId = profileId
            copy.baptisms = source.baptisms
            copy.confirmations = source.confirmations
            copy.initiatories = source.initiatories
            copy.endowments = source.endowments
            copy.sealings = source.sealings
            copy.shiftHrs = source.shiftHrs
            copy.comments = source.comments
            copy.picture = source.picture
            copy.isFavorite = source.isFavorite
        }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            print("Error saving copied visits: \(nserror)")
        }
        ad.needsVisitRefresh = true
        ad.getVisits()
        if #available(iOS 27.0, *) {
            Task { try? await HolyPlacesSpotlightIndexer.reindexVisits() }
        }
        return rows.count
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publish()
    }

    private func objectID(for uri: String) -> NSManagedObjectID? {
        guard let url = URL(string: uri) else { return nil }
        return ad.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
    }

    private func makeController() -> NSFetchedResultsController<Visit> {
        if let fetchedController { return fetchedController }
        let context = ad.persistentContainer.viewContext
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.fetchBatchSize = 20
        switch sortOption {
        case 0:
            request.sortDescriptors = [
                NSSortDescriptor(key: "year", ascending: false),
                NSSortDescriptor(key: "dateVisited", ascending: false)
            ]
        case 1:
            request.sortDescriptors = [
                NSSortDescriptor(key: "year", ascending: true),
                NSSortDescriptor(key: "dateVisited", ascending: true)
            ]
        case 2:
            request.sortDescriptors = [NSSortDescriptor(key: "holyPlace", ascending: true)]
        case 3:
            request.sortDescriptors = [NSSortDescriptor(key: "holyPlace", ascending: false)]
        default:
            request.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        }
        var predicates: [NSPredicate] = []
        if let profile = ProfileManager.shared.visitProfilePredicate() {
            predicates.append(profile)
        }
        switch visitFilterRow {
        case 1: predicates.append(NSPredicate(format: "type == %@", "T"))
        case 2: predicates.append(NSPredicate(format: "type == %@", "H"))
        case 3: predicates.append(NSPredicate(format: "type == %@", "V"))
        case 4: predicates.append(NSPredicate(format: "type == %@", "C"))
        case 5: predicates.append(NSPredicate(format: "type == %@", "O"))
        default: break
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        let sectionKey = (sortOption == 2 || sortOption == 3) ? "holyPlace" : "year"
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: sectionKey,
            cacheName: nil
        )
        controller.delegate = self
        fetchedController = controller
        do {
            try controller.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        return controller
    }

    private func publish() {
        let objects = makeController().fetchedObjects ?? []
        unfilteredCount = objects.count
        showEmptyState = objects.isEmpty
        if isFiltered {
            let filtered = filteredVisits(from: objects)
            sections = groupedSections(filtered)
            displayedCount = filtered.count
        } else {
            sections = frcSections()
            displayedCount = objects.count
        }
        revision += 1
    }

    private func frcSections() -> [VisitSection] {
        guard let infos = fetchedController?.sections else { return [] }
        return infos.map { info in
            let rows = (info.objects as? [Visit]) ?? []
            return VisitSection(id: "frc-\(info.name)", title: info.name, visits: rows)
        }
    }

    private func filteredVisits(from visits: [Visit]) -> [Visit] {
        let searchTerms = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        return visits.filter { visit in
            let categoryMatch = (scope == "All")
                || (scope == "B" && visit.baptisms > 0)
                || (scope == "C" && visit.confirmations > 0)
                || (scope == "I" && visit.initiatories > 0)
                || (scope == "E" && visit.endowments > 0)
                || (scope == "S" && visit.sealings > 0)
                || (scope == "⭐️" && visit.isFavorite)
            guard categoryMatch else { return false }
            guard !searchTerms.isEmpty else { return true }
            let dateString = visit.dateVisited.map { listDateFormatter.string(from: $0) } ?? ""
            let searchableText = "\(visit.holyPlace ?? "") \(visit.comments ?? "") \(dateString)".lowercased()
            return searchTerms.allSatisfy { searchableText.contains($0.lowercased()) }
        }
    }

    private func groupedSections(_ visits: [Visit]) -> [VisitSection] {
        guard !visits.isEmpty else { return [] }
        switch sortOption {
        case 0, 1:
            let grouped = Dictionary(grouping: visits) { visit -> String in
                let year = Calendar.current.component(.year, from: visit.dateVisited ?? Date())
                return "\(year)"
            }
            return grouped.map { (section: $0.key, visits: $0.value) }
                .sorted { lhs, rhs in
                    let left = Int(lhs.section) ?? 0
                    let right = Int(rhs.section) ?? 0
                    return sortOption == 0 ? left > right : left < right
                }
                .map { VisitSection(id: "y-\($0.section)", title: $0.section, visits: $0.visits) }
        case 2, 3:
            let grouped = Dictionary(grouping: visits) { $0.holyPlace ?? "" }
            return grouped.map { (section: $0.key, visits: $0.value) }
                .sorted { lhs, rhs in
                    sortOption == 2 ? lhs.section < rhs.section : lhs.section > rhs.section
                }
                .map { VisitSection(id: "p-\($0.section)", title: $0.section, visits: $0.visits) }
        default:
            return [VisitSection(id: "results", title: "Results", visits: visits)]
        }
    }
}

struct VisitsTabView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = VisitsListModel()

    @State private var selection: VisitListSelection?
    @State private var visibleVisitURIs: Set<String> = []
    @State private var ignoreSelection = false
    @State private var recordModel: RecordVisitModel?
    @State private var showPlacePicker = false
    @State private var anchorURI: String?
    @State private var pending: PendingAction?
    @State private var pendingDelete: NSManagedObjectID?
    @State private var presentedPhoto: PresentedPhoto?
    @State private var showOptions = false
    @State private var showCopyDialog = false
    @State private var copyProfiles: [ProfileChoice] = []
    @State private var copyMessage = ""
    @State private var didSyncYears = false
    @State private var didOfferBackup = false
    @State private var noticeQueue: [VisitsNotice] = []
    @State private var notice: VisitsNotice?
    @State private var noticeShown = false

    private enum PendingAction {
        case selection(VisitListSelection?)
        case record(Temple, Visit?, Visit?, Bool)
        case add
    }

    private var canCopyToProfile: Bool {
        profilesEnabled && ProfileManager.shared.allProfiles().count >= 2
    }

    private var selectedVisitURI: String? {
        if case .visit(let uri) = selection { return uri }
        return nil
    }

    var body: some View {
        AdaptiveSplit(widenSidebar: true) {
            listColumn
        } detail: {
            detailColumn
        }
        .tint(Color("BaptismsBlue"))
        .fullScreenCover(item: $presentedPhoto) { item in
            PhotoViewerView(image: item.image, onDismiss: { presentedPhoto = nil })
        }
        .sheet(isPresented: $showOptions) {
            VisitOptionsSheet {
                model.reload()
            }
        }
        .confirmationDialog("Copy to Profile", isPresented: $showCopyDialog, titleVisibility: .visible) {
            ForEach(copyProfiles) { profile in
                Button(profile.name) {
                    let count = model.copySelected(to: profile.id)
                    let wasSelecting = model.isSelectMode
                    if wasSelecting { model.exitSelect() }
                    if count > 0 {
                        enqueue(.copied(count, profile.name))
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(copyMessage)
        }
        .alert(noticeTitle, isPresented: $noticeShown) {
            noticeButtons
        } message: {
            Text(noticeMessage)
        }
        .onChange(of: noticeShown) { _, shown in
            if !shown { presentQueuedNotice() }
        }
        .onChange(of: selection) { oldValue, newValue in
            guard !ignoreSelection else { return }
            if model.isSelectMode {
                revertSelection(to: oldValue)
                return
            }
            if recordModel?.isDirty == true {
                if case .compose = newValue { return }
                pending = .selection(newValue)
                revertSelection(to: oldValue)
                enqueue(.discard)
                return
            }
            applySelection(newValue)
        }
        .onChange(of: model.searchText) { _, _ in
            model.applyFilters()
        }
        .onChange(of: router.visitsRoute) { _, _ in
            consumeRoute()
        }
        .onAppear {
            customizeSearchFonts()
            if !didSyncYears {
                didSyncYears = true
                ad.syncVisitYears()
            }
            model.reload()
            if !didOfferBackup {
                didOfferBackup = true
                offerBackupIfNeeded()
            }
            offerChangesIfNeeded()
            requestReviewIfNeeded()
            storeParsedPlacesIfNeeded()
            consumeRoute()
            selectFirstVisit()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenVisitFromWidget"))) { note in
            guard let uri = note.object as? String else { return }
            openURI(uri)
        }
    }

    private var listColumn: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                ForEach(model.sections) { section in
                    Section {
                        ForEach(section.visits, id: \.objectID) { visit in
                            let uri = visit.objectID.uriRepresentation().absoluteString
                            listedVisit(visit)
                                .tag(VisitListSelection.visit(uri))
                                .id(uri)
                                .listRowBackground(Color(uiColor: selection == .visit(uri) ? .systemGray4 : .systemBackground))
                                .onAppear { visibleVisitURIs.insert(uri) }
                                .onDisappear { visibleVisitURIs.remove(uri) }
                                .selectionDisabled(model.isSelectMode)
                        }
                    } header: {
                        Text("\(section.title) (\(section.visits.count))")
                            .font(.custom("Baskerville", size: 22))
                            .foregroundStyle(Color("BaptismsBlue"))
                            .textCase(nil)
                    }
                }
            }
            .onChange(of: selection) { _, newValue in
                guard case .visit(let uri) = newValue, !visibleVisitURIs.contains(uri) else { return }
                proxy.scrollTo(uri, anchor: .center)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
        }
        .environment(\.defaultMinListRowHeight, 50)
        .searchable(
            text: $model.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search")
        )
        .background(HolyPlacesSearchFontFix())
        .overlay {
            if model.showEmptyState {
                Text(emptyVisitsMessage)
                    .font(.custom("Baskerville", size: 18))
                    .foregroundStyle(Color("BaptismsBlue"))
                    .multilineTextAlignment(.center)
                    .padding(20)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            scopeBar
        }
        .navigationTitle(model.titleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
        .frame(maxWidth: .infinity)
        .toolbar { listToolbar }
    }

    private var scopeBar: some View {
        VStack(spacing: 0) {
            ScopeChoiceButtons(
                titles: visitScopes,
                selection: visitScopes.firstIndex(of: model.scope) ?? 0,
                accessibilityLabel: scopeAccessibility
            ) { index in
                model.scope = visitScopes[index]
                model.applyFilters()
            }
            .padding(.horizontal, 12)
            .frame(height: 43)
            Divider()
        }
        .background(Color(uiColor: .systemBackground))
    }

    @ToolbarContentBuilder
    private var listToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 0) {
                Text("\(model.titleName) (\(model.displayedCount))")
                    .font(.custom("Baskerville", size: 19))
                    .foregroundStyle(Color(uiColor: model.titleUIColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(model.sortSubtitle)
                    .font(.custom("Baskerville", size: 15))
                    .foregroundStyle(Color.gray)
            }
            .accessibilityElement(children: .combine)
        }
        if model.isSelectMode {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { model.exitSelect() }
                    .font(.custom("Baskerville", size: 17))
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    model.selectAllVisible()
                } label: {
                    Image("select")
                        .renderingMode(.template)
                }
                .accessibilityLabel("Select all")
                Button("Copy to Profile\u{2026}") {
                    beginCopy()
                }
                .font(.custom("Baskerville", size: 17))
                .disabled(model.selectedIDs.isEmpty)
            }
        } else {
            ToolbarItemGroup(placement: .topBarLeading) {
                sortMenu
                Button {
                    request(.add)
                } label: {
                    Image("addVisit")
                        .renderingMode(.template)
                }
                .accessibilityLabel("Add")
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if canCopyToProfile {
                    Button {
                        model.enterSelect()
                    } label: {
                        Image("select")
                            .renderingMode(.template)
                    }
                    .accessibilityLabel("Select visits")
                }
                filterMenu
                Button {
                    showOptions = true
                } label: {
                    Image("export")
                        .renderingMode(.template)
                }
                .accessibilityLabel("Export")
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            sortChoice("Latest Date", option: 0)
            sortChoice("Oldest Date", option: 1)
            sortChoice("Place (A-Z)", option: 2)
            sortChoice("Place (Z-A)", option: 3)
        } label: {
            Image("sort")
                .renderingMode(.template)
        }
        .accessibilityLabel("Sort")
    }

    private var filterMenu: some View {
        Menu {
            filterButton("All Visits", type: nil, tint: nil, option: 0)
            filterButton("Active Temples", type: "T", tint: templeColor, option: 1)
            filterButton("Historical Sites", type: "H", tint: historicalColor, option: 2)
            filterButton("Visitors' Centers", type: "V", tint: visitorCenterColor, option: 3)
            filterButton("Temples Under Construction", type: "C", tint: constructionColor, option: 4)
            filterButton("Other", type: nil, tint: nil, option: 5)
        } label: {
            Image("filter")
                .renderingMode(.template)
        }
        .accessibilityLabel("Filter")
    }

    private func sortChoice(_ title: String, option: Int) -> some View {
        Button {
            model.setSort(option)
        } label: {
            Text(title)
                .font(.custom("Baskerville", size: 17))
        }
    }

    private func filterButton(_ title: String, type: String?, tint: UIColor?, option: Int) -> some View {
        Button {
            model.setFilter(option)
        } label: {
            if let type, let tint, let image = placeTypeSymbolImage(for: type, tint: tint) {
                Label {
                    Text(title)
                        .font(.custom("Baskerville", size: 17))
                } icon: {
                    Image(uiImage: image)
                }
            } else {
                Text(title)
                    .font(.custom("Baskerville", size: 17))
            }
        }
    }

    @ViewBuilder
    private func listedVisit(_ visit: Visit) -> some View {
        let row = visitRow(visit)
        if model.isSelectMode {
            Button {
                model.toggleURI(visit.objectID.uriRepresentation().absoluteString)
            } label: {
                row
            }
            .buttonStyle(.borderless)
        } else {
            row.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("New") { newVisit(from: visit) }
                    .tint(.blue)
                Button("Copy") { copyVisitRow(visit) }
                    .tint(Color(uiColor: .moss()))
                Button("Delete") {
                    pendingDelete = visit.objectID
                    enqueue(.delete)
                }
                .tint(Color(uiColor: .darkRed()))
            }
        }
    }

    @ViewBuilder
    private func visitRow(_ visit: Visit) -> some View {
        let titleColor = visitTitleColor(visit)
        HStack(spacing: 8) {
            if let image = placeTypeSymbolImage(for: visit.type) {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(Color(uiColor: titleColor))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(visit.holyPlace ?? "")
                    .font(.custom("Baskerville", size: 20))
                    .foregroundStyle(Color(uiColor: titleColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(visitSubtitle(visit))
                    .font(.custom("Baskerville", size: 16))
                    .foregroundStyle(Color(uiColor: defaultColor))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if model.isSelectMode {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("BaptismsBlue"))
                    .opacity(model.selectedIDs.contains(visit.objectID) ? 1 : 0)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(minHeight: 50)
        .contentShape(Rectangle())
        .modifier(SiriVisitAnnotation(visit: visit))
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let recordModel {
            RecordVisitForm(
                model: recordModel,
                onCancel: { finishRecord(saved: false) },
                onSaved: { finishRecord(saved: true) }
            )
        } else if showPlacePicker {
            AddVisitPlacePicker(
                onCancel: cancelPicker,
                onNext: { temple in
                    openRecord(place: temple, existing: nil, copying: nil)
                }
            )
        } else if let uri = selectedVisitURI, let visit = model.visit(uri: uri) {
            VisitDetailScreen(
                visit: visit,
                onEdit: {
                    request(.record(temple(for: visit), visit, nil, false))
                },
                onPhoto: { image in
                    presentedPhoto = PresentedPhoto(image: image)
                },
                onSwipe: { delta in
                    swipe(delta)
                }
            )
            .id("\(uri)-\(model.revision)")
        } else {
            Text("Select a Visit")
                .font(.custom("Baskerville", size: 20))
                .foregroundStyle(.secondary)
        }
    }

    private func visitSubtitle(_ visit: Visit) -> String {
        var ordinances = " ~"
        if visit.baptisms > 0 { ordinances.append(" B") }
        if visit.confirmations > 0 { ordinances.append(" C") }
        if visit.initiatories > 0 { ordinances.append(" I") }
        if visit.endowments > 0 { ordinances.append(" E") }
        if visit.sealings > 0 { ordinances.append(" S") }
        if visit.shiftHrs > 0 { ordinances.append(" \(visit.shiftHrs) hrs") }
        if ordinances == " ~" { ordinances = "" }
        if visit.picture != nil { ordinances.append("  📷") }
        if visit.isFavorite { ordinances.append("   ⭐") }
        if let dateVisited = visit.dateVisited {
            return " " + model.listDateFormatter.string(from: dateVisited) + ordinances
        }
        return " (no date)" + ordinances
    }

    private func visitTitleColor(_ visit: Visit) -> UIColor {
        switch visit.type {
        case "T": return templeColor
        case "H": return historicalColor
        case "A": return announcedColor
        case "C": return constructionColor
        case "V": return visitorCenterColor
        default: return defaultColor
        }
    }

    private func scopeAccessibility(_ scope: String) -> String {
        switch scope {
        case "B": return "Baptisms"
        case "C": return "Confirmations"
        case "I": return "Initiatories"
        case "E": return "Endowments"
        case "S": return "Sealings"
        case "⭐️": return "Favorites"
        default: return "All"
        }
    }

    private func temple(for visit: Visit) -> Temple {
        let name = visit.holyPlace ?? ""
        if let found = allPlaces.first(where: { $0.templeName == name }) {
            return found
        }
        if let found = allPlaces.first(where: { $0.nameChanges.contains { $0.oldName == name } }) {
            return found
        }
        return Temple(
            Name: name,
            Address: "",
            Snippet: "",
            CityState: "",
            Country: "",
            Phone: "",
            Latitude: 0,
            Longitude: 0,
            Order: 0,
            AnnouncedDate: nil,
            PictureURL: "",
            SiteURL: "",
            Type: visit.type ?? "O",
            ReaderView: false,
            InfoURL: "",
            SqFt: 0,
            FHCode: ""
        )
    }

    private func request(_ action: PendingAction) {
        if recordModel?.isDirty == true {
            pending = action
            enqueue(.discard)
        } else {
            perform(action)
        }
    }

    private func perform(_ action: PendingAction) {
        switch action {
        case .selection(let value):
            if model.isSelectMode { model.exitSelect() }
            setSelection(value)
            applySelection(value)
        case .record(let place, let existing, let copying, let fromNotification):
            if fromNotification {
                placeFromNotification = place.templeName
                dateFromNotification = notificationData?.value(forKey: "dateVisited") as? Date
            }
            openRecord(place: place, existing: existing, copying: copying)
        case .add:
            if case .visit(let uri) = selection {
                anchorURI = uri
            }
            showPlacePicker = true
            recordModel = nil
            setSelection(.compose)
        }
    }

    private func openRecord(place: Temple, existing: Visit?, copying: Visit?) {
        if let existing {
            anchorURI = existing.objectID.uriRepresentation().absoluteString
        } else if case .visit(let uri) = selection {
            anchorURI = uri
        }
        if let copying {
            copyVisit = copying
        }
        showPlacePicker = false
        recordModel = RecordVisitModel(place: place, existingVisit: existing)
        setSelection(.compose)
    }

    private func finishRecord(saved: Bool) {
        let uri = recordModel?.existingVisit?.objectID.uriRepresentation().absoluteString ?? anchorURI
        recordModel = nil
        showPlacePicker = false
        if saved {
            ad.needsVisitRefresh = true
            ad.getVisits()
            model.reload()
        }
        if let uri, model.visit(uri: uri) != nil {
            setSelection(.visit(uri))
            syncGlobals(uri)
        } else {
            setSelection(nil)
        }
    }

    private func cancelPicker() {
        showPlacePicker = false
        if let anchorURI, model.visit(uri: anchorURI) != nil {
            setSelection(.visit(anchorURI))
            syncGlobals(anchorURI)
        } else {
            setSelection(nil)
        }
    }

    private func applySelection(_ newValue: VisitListSelection?) {
        guard recordModel?.isDirty != true else { return }
        switch newValue {
        case .visit(let uri):
            recordModel = nil
            showPlacePicker = false
            syncGlobals(uri)
        case .compose:
            break
        case nil:
            recordModel = nil
            showPlacePicker = false
        }
    }

    private func setSelection(_ value: VisitListSelection?) {
        ignoreSelection = true
        selection = value
        DispatchQueue.main.async { ignoreSelection = false }
    }

    private func revertSelection(to value: VisitListSelection?) {
        ignoreSelection = true
        selection = value
        DispatchQueue.main.async { ignoreSelection = false }
    }

    private func syncGlobals(_ uri: String) {
        let rows = model.visibleVisits()
        if let index = rows.firstIndex(where: { $0.objectID.uriRepresentation().absoluteString == uri }) {
            visitsInTable = rows
            selectedVisitRow = index
        } else if let visit = model.visit(uri: uri) {
            visitsInTable = [visit]
            selectedVisitRow = 0
        }
    }

    private func swipe(_ delta: Int) {
        guard case .visit(let uri) = selection else { return }
        let rows = model.visibleVisits()
        guard let index = rows.firstIndex(where: { $0.objectID.uriRepresentation().absoluteString == uri }) else { return }
        let next = index + delta
        guard rows.indices.contains(next) else { return }
        request(.selection(.visit(rows[next].objectID.uriRepresentation().absoluteString)))
    }

    private func newVisit(from visit: Visit) {
        guard let name = visit.holyPlace,
              let found = allPlaces.first(where: { $0.templeName == name }) else { return }
        request(.record(found, nil, nil, false))
    }

    private func copyVisitRow(_ visit: Visit) {
        guard let name = visit.holyPlace,
              let found = allPlaces.first(where: { $0.templeName == name }) else { return }
        request(.record(found, nil, visit, false))
    }

    private func beginCopy() {
        let count = model.selectedIDs.count
        guard count > 0 else { return }
        let visitWord = count == 1 ? "this visit" : "\(count) visits"
        copyMessage = "Select a profile to copy \(visitWord) to:"
        copyProfiles = ProfileManager.shared.allProfiles().compactMap { profile in
            guard let profileId = profile.value(forKey: "profileId") as? String,
                  profileId != activeProfileId,
                  let name = profile.value(forKey: "name") as? String else { return nil }
            let icon = profile.value(forKey: "iconName") as? String ?? "person.fill"
            return ProfileChoice(id: profileId, name: name, icon: icon)
        }
        showCopyDialog = true
    }

    private func openURI(_ uri: String) {
        guard model.visit(uri: uri) != nil else { return }
        request(.selection(.visit(uri)))
    }

    private func consumeRoute() {
        guard let route = router.visitsRoute else { return }
        router.visitsRoute = nil
        if model.isSelectMode { model.exitSelect() }
        if let term = route.search {
            model.searchText = term
            model.applyFilters()
        }
        if let uri = route.objectURI {
            openURI(uri)
        } else if let placeId = route.recordPlaceId,
                  let temple = allPlaces.first(where: { stablePlaceID($0) == placeId }) {
            request(.record(temple, nil, nil, false))
        } else if route.compose {
            request(.add)
        } else if route.quickAdd {
            beginQuickAdd()
        } else if route.search != nil {
            selectFirstVisit(replacingSelection: true)
        }
    }

    /// Only on iPad with both columns showing. In a collapsed split, a selection would open
    /// the detail over the list.
    private func selectFirstVisit(replacingSelection: Bool = false) {
        guard UIDevice.current.userInterfaceIdiom == .pad, horizontalSizeClass == .regular,
              replacingSelection || selection == nil, recordModel == nil, !showPlacePicker, !model.isSelectMode,
              let first = model.visibleVisits().first else { return }
        request(.selection(.visit(first.objectID.uriRepresentation().absoluteString)))
    }

    private func beginQuickAdd() {
        if let data = notificationData, data.value(forKey: "place") != nil {
            guard let placeName = data.value(forKey: "place") as? String,
                  let found = allPlaces.first(where: { $0.templeName == placeName }) else { return }
            request(.record(found, nil, nil, true))
        } else if let item = quickLaunchItem {
            request(.record(item, nil, nil, false))
        }
    }

    private func customizeSearchFonts() {
        applyHolyPlacesSearchFont()
    }

    private func offerBackupIfNeeded() {
        let defaults = UserDefaults.standard
        let backupDate = defaults.object(forKey: "backupDate") as? Date
        let backupReminder = defaults.object(forKey: "backupReminder") as? Date
        if backupDate?.daysBetweenDate(toDate: Date()) ?? 91 > 90
            && backupReminder?.daysBetweenDate(toDate: Date()) ?? 91 > 90
            && visits.count > 6 {
            enqueue(.backup)
        }
    }

    private func offerChangesIfNeeded() {
        guard !changesDate.isEmpty, !changesNoticePending else { return }
        var changesMsg = changesMsg1
        if changesMsg2 != "" {
            changesMsg.append("\n\n")
            changesMsg.append(changesMsg2)
        }
        if changesMsg3 != "" {
            changesMsg.append("\n\n")
            changesMsg.append(changesMsg3)
        }
        enqueue(.changes(changesDate + " Update", changesMsg))
    }

    private var changesNoticePending: Bool {
        if noticeShown, case .changes? = notice { return true }
        return noticeQueue.contains { queued in
            if case .changes = queued { return true }
            return false
        }
    }

    private func requestReviewIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "hasRequestedReview"), model.unfilteredCount >= 10 else { return }
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let scene else { return }
        SKStoreReviewController.requestReview(in: scene)
        defaults.set(true, forKey: "hasRequestedReview")
    }

    private func storeParsedPlacesIfNeeded() {
        if ad.newFileParsed {
            ad.storePlaces()
            ad.savePlaceVersion()
            checkedForUpdate = Date()
            ad.newFileParsed = false
        }
    }

    private func enqueue(_ notice: VisitsNotice) {
        noticeQueue.append(notice)
        presentQueuedNotice()
    }

    private func presentQueuedNotice() {
        guard !noticeShown, !noticeQueue.isEmpty else { return }
        notice = noticeQueue.removeFirst()
        noticeShown = true
    }

    private var noticeTitle: String {
        switch notice {
        case .delete: return "Confirm"
        case .discard: return "Discard Changes?"
        case .backup: return "IMPORTANT!"
        case .changes(let title, _): return title
        case .copied: return "Visits Copied"
        case nil: return ""
        }
    }

    private var noticeMessage: String {
        switch notice {
        case .delete:
            return "Are you sure you want to delete this visit?"
        case .discard:
            return "You have unsaved changes for this visit."
        case .backup:
            return "To ensure you don't lose your entered visits due to unforeseen circumstances, back-up your visits to an XML file from time to time.\n\nClick the Export button in the top right corner to access this feature; See the FAQ for more details."
        case .changes(_, let message):
            return message
        case .copied(let count, let name):
            let visitWord = count == 1 ? "visit" : "visits"
            return "\(count) \(visitWord) copied to \(name)."
        case nil:
            return ""
        }
    }

    @ViewBuilder
    private var noticeButtons: some View {
        switch notice {
        case .delete:
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                guard let pendingDelete else { return }
                let uri = pendingDelete.uriRepresentation().absoluteString
                model.delete(pendingDelete)
                if selectedVisitURI == uri {
                    setSelection(nil)
                }
            }
        case .discard:
            Button("Discard", role: .destructive) {
                let action = pending
                pending = nil
                recordModel = nil
                if let action { perform(action) }
            }
            Button("Cancel", role: .cancel) { pending = nil }
        case .backup:
            Button("OK", role: .cancel) {
                UserDefaults.standard.set(Date(), forKey: "backupReminder")
            }
        case .changes:
            Button("OK", role: .cancel) { changesDate = "" }
        case .copied, nil:
            Button("OK", role: .cancel) {}
        }
    }

    private var emptyVisitsMessage: String {
        "Add Visits from the Place Details pages or selecting the Add button above.\n\nIMPORTANT!\n\nTo ensure you don't lose your entered visits due to unforeseen circumstances, back-up your visits to an XML file from time to time.\n\nClick the Export button in the top right corner to access this feature; See the FAQ for more details."
    }
}

private struct AddVisitPlacePicker: View {
    var onCancel: () -> Void
    var onNext: (Temple) -> Void

    @State private var segment = 0
    @State private var search = ""
    @State private var otherName = ""
    @State private var selectedName: String?
    @State private var closest = UserDefaults.standard.bool(forKey: "addVisitClosestPlace")
    @State private var allowClosest = !UserDefaults.standard.bool(forKey: "locationNotAllowed")

    private var sourcePlaces: [Temple] {
        switch segment {
        case 1: return historical
        case 2: return visitors
        default: return allTemples
        }
    }

    private var filteredPlaces: [Temple] {
        var rows = sourcePlaces
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !term.isEmpty {
            rows = rows.filter { $0.templeName.lowercased().contains(term.lowercased()) }
        }
        if closest {
            rows.sort {
                guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
                return Int(distance1) < Int(distance2)
            }
        }
        return rows
    }

    private var canContinue: Bool {
        if segment == 3 {
            return !otherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return selectedName != nil && filteredPlaces.contains { $0.templeName == selectedName }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Add New Visit")
                .font(.custom("Baskerville", size: 22))
            Picker("Place type", selection: $segment) {
                Text("Temple").tag(0)
                Text("Historic").tag(1)
                Text("V. Center").tag(2)
                Text("Other").tag(3)
            }
            .pickerStyle(.segmented)
            .font(.custom("Baskerville", size: 14))
            if segment == 3 {
                TextField("Enter name of place", text: $otherName)
                    .font(.custom("Baskerville", size: 20))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                Spacer()
            } else {
                TextField("Search places...", text: $search)
                    .font(.custom("Baskerville", size: 16))
                    .textFieldStyle(.roundedBorder)
                List(filteredPlaces, id: \.templeName) { place in
                    Button {
                        selectedName = place.templeName
                    } label: {
                        HStack {
                            Text(place.templeName)
                                .font(.custom("Baskerville", size: 20))
                                .foregroundStyle(Color(uiColor: color(for: place)))
                            Spacer()
                            if selectedName == place.templeName {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color("BaptismsBlue"))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
            if allowClosest && segment != 3 {
                Toggle(isOn: $closest) {
                    Text("Closest Place")
                        .font(.custom("Baskerville", size: 20))
                }
                .tint(Color("BaptismsBlue"))
            }
        }
        .padding()
        .navigationTitle("Add New Visit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .hideTabBarWhenCompact()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
                    .font(.custom("Baskerville", size: 17))
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Next", action: confirm)
                    .font(.custom("Baskerville", size: 17))
                    .disabled(!canContinue)
            }
        }
        .onAppear {
            if closest && UserDefaults.standard.bool(forKey: "locationAllowed") {
                ad.DetermineClosest()
            }
            chooseInitial(randomize: !closest)
        }
        .onChange(of: segment) { _, _ in
            search = ""
            chooseInitial(randomize: !closest)
        }
        .onChange(of: search) { _, _ in
            if closest || selectedName == nil || !filteredPlaces.contains(where: { $0.templeName == selectedName }) {
                selectedName = filteredPlaces.first?.templeName
            }
        }
        .onChange(of: closest) { _, isOn in
            if isOn {
                if UserDefaults.standard.bool(forKey: "locationAllowed") {
                    UserDefaults.standard.set(true, forKey: "addVisitClosestPlace")
                    ad.DetermineClosest()
                    selectedName = filteredPlaces.first?.templeName
                } else {
                    ad.locationServiceSetup()
                    closest = false
                }
            } else {
                UserDefaults.standard.set(false, forKey: "addVisitClosestPlace")
                chooseInitial(randomize: true)
            }
        }
    }

    private func chooseInitial(randomize: Bool) {
        let rows = filteredPlaces
        guard !rows.isEmpty else {
            selectedName = nil
            return
        }
        if closest || !randomize {
            selectedName = rows[0].templeName
        } else {
            selectedName = rows[Int.random(in: 0..<rows.count)].templeName
        }
    }

    private func confirm() {
        if segment == 3 {
            let name = otherName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            onNext(Temple(
                Name: name,
                Address: "",
                Snippet: "",
                CityState: "",
                Country: "",
                Phone: "",
                Latitude: 0,
                Longitude: 0,
                Order: 0,
                AnnouncedDate: nil,
                PictureURL: "",
                SiteURL: "",
                Type: "O",
                ReaderView: false,
                InfoURL: "",
                SqFt: 0,
                FHCode: ""
            ))
        } else if let temple = filteredPlaces.first(where: { $0.templeName == selectedName }) {
            onNext(temple)
        }
    }

    private func color(for place: Temple) -> UIColor {
        switch segment {
        case 0:
            switch place.templeType {
            case "T": return templeColor
            case "A": return announcedColor
            default: return constructionColor
            }
        case 1: return historicalColor
        case 2: return visitorCenterColor
        default: return defaultColor
        }
    }
}

private struct VisitOptionsSheet: View {
    var onChanged: () -> Void
    @StateObject private var controller = VisitBackupController()
    @Environment(\.dismiss) private var dismiss
    @State private var showImporter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(controller.statusMessage)
                        .font(.custom("Baskerville", size: 24))
                        .foregroundStyle(controller.statusUsesPlaceColor ? Color(uiColor: templeColor) : Color.primary)
                        .multilineTextAlignment(.center)
                    Text("Export Visits as txt, xml or csv files")
                        .font(.custom("Baskerville", size: 19))
                    HStack(spacing: 50) {
                        exportButton("TXT") { controller.export(type: "txt") }
                        exportButton("XML") { controller.export(type: "xml") }
                        exportButton("CSV") { controller.export(type: "csv") }
                    }
                    Toggle(isOn: $controller.includePhotos) {
                        Text("Include Photos in XML")
                            .font(.custom("Baskerville", size: 18))
                    }
                    .tint(Color("BaptismsBlue"))
                    .onChange(of: controller.includePhotos) { _, _ in
                        controller.updateEstimatedSize()
                    }
                    Text(controller.estimatedSize)
                        .font(.custom("Baskerville", size: 18))
                    Text("(XML file used for back-up/restore)")
                        .font(.custom("Baskerville", size: 17))
                    Button("Import Visits from XML") { showImporter = true }
                        .font(.custom("Baskerville", size: 19))
                        .frame(height: 50)
                    Toggle(isOn: $controller.overwriteComments) {
                        Text("Overwrite comments on existing visits")
                            .font(.custom("Baskerville", size: 18))
                    }
                    .tint(Color("BaptismsBlue"))
                }
                .padding(24)
            }
            .background(Color(uiColor: .tertiarySystemBackground))
            .navigationTitle("Export / Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.custom("Baskerville", size: 17))
                }
            }
            .background(VisitExportPresenter(share: controller.share))
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.xml], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        controller.importFile(url, onChanged: onChanged)
                    }
                case .failure:
                    controller.report(title: "Import Failure", message: "The selected file could not be read.")
                }
            }
            .alert(controller.alertTitle ?? "", isPresented: alertShown) {
                Button("OK", role: .cancel) { controller.alertTitle = nil }
            } message: {
                Text(controller.alertMessage)
            }
            .onAppear {
                controller.prepare()
            }
        }
        .presentationDetents([.large])
    }

    private var alertShown: Binding<Bool> {
        Binding(
            get: { controller.alertTitle != nil },
            set: { if !$0 { controller.alertTitle = nil } }
        )
    }

    private func exportButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.custom("Baskerville", size: 19))
            .frame(height: 50)
    }
}

private struct VisitExportPresenter: UIViewControllerRepresentable {
    var share: ExportShare?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard let share, context.coordinator.presentedID != share.id else { return }
        guard controller.view.window != nil else { return }
        context.coordinator.presentedID = share.id
        let activity = UIActivityViewController(activityItems: [share.url], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = controller.view
            let bounds = controller.view.bounds
            popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        controller.present(activity, animated: true)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var presentedID: UUID?
    }
}

final class VisitBackupController: NSObject, ObservableObject, XMLParserDelegate {
    @Published var includePhotos = true
    @Published var overwriteComments = false
    @Published var estimatedSize = "Estimated size: calculating…"
    @Published var statusMessage = "Export / Import Visits"
    @Published var statusUsesPlaceColor = false
    @Published var share: ExportShare?
    @Published var alertTitle: String?
    @Published var alertMessage = ""

    private var fileName = ""
    private var estimateGeneration = 0
    private var exportText = ""
    private var exportCount = 0
    private var eName = ""
    private var holyPlace = ""
    private var comments = ""
    private var visitDate = Date()
    private var visitDateIsValid = false
    private var hoursWorked = Double()
    private var sealings = Int16()
    private var endowments = Int16()
    private var initiatories = Int16()
    private var confirmations = Int16()
    private var baptisms = Int16()
    private var type = ""
    private var isFavorite = false
    private var pictureData: Data?
    private var pictureBase64String = ""
    private var currentText = ""
    private var importCount = 0
    private var duplicates = 0
    private var photoImportCount = 0
    private var skippedInvalid = 0
    private var commentsUpdated = 0
    private var onChanged: (() -> Void)?

    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    private let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    private let xmlDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let legacyFullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    private let legacyEnglishFullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    func prepare() {
        refreshFileName()
        updateEstimatedSize()
    }

    func updateEstimatedSize() {
        estimateGeneration += 1
        let generation = estimateGeneration
        let includePhotoData = includePhotos
        if includePhotoData {
            estimatedSize = "Estimated size: calculating…"
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let bytes = self?.calculateEstimatedFileSize(includePhotos: includePhotoData) ?? 0
            DispatchQueue.main.async {
                guard let self, generation == self.estimateGeneration else { return }
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
                formatter.countStyle = .file
                self.estimatedSize = "Estimated size: \(formatter.string(fromByteCount: bytes))"
            }
        }
    }

    func export(type: String) {
        refreshFileName()
        exportText = ""
        buildExport(type: type)
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(fileName).\(type)")
        do {
            try exportText.write(toFile: filePath, atomically: true, encoding: .utf8)
            if type == "xml" {
                UserDefaults.standard.set(Date(), forKey: "backupDate")
            }
            share = ExportShare(url: URL(fileURLWithPath: filePath))
        } catch {
            print("Error with export: \(error)")
        }
    }

    func importFile(_ url: URL, onChanged: @escaping () -> Void) {
        self.onChanged = onChanged
        importCount = 0
        duplicates = 0
        photoImportCount = 0
        skippedInvalid = 0
        commentsUpdated = 0
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        guard let parser = XMLParser(contentsOf: url) else {
            report(title: "Import Failure", message: "The selected file could not be read.")
            return
        }
        parser.delegate = self
        if parser.parse() {
            var message = photoImportCount > 0
                ? "Successfully imported \(importCount) visits with \(photoImportCount) photos; \(duplicates) duplicate visits skipped"
                : "Successfully imported \(importCount) visits; \(duplicates) duplicate visits skipped"
            if commentsUpdated > 0 {
                message += "; \(commentsUpdated) comments updated"
            }
            if skippedInvalid > 0 {
                message += "; \(skippedInvalid) visits skipped (missing place or date)"
            }
            report(title: "Import Completed", message: message)
            ad.needsVisitRefresh = true
            ad.getVisits()
            onChanged()
        } else {
            print("Data parsing aborted")
            var detail = "The XML file selected isn't formatted properly."
            if let error = parser.parserError {
                print("Error Description:\(error.localizedDescription)")
                print("Line number: \(parser.lineNumber)")
                detail += " \(error.localizedDescription) (line \(parser.lineNumber))"
            }
            report(title: "Import Failure", message: detail)
        }
    }

    func report(title: String, message: String) {
        alertMessage = message
        alertTitle = title
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        eName = elementName
        currentText = ""
        if elementName == "Visit" {
            holyPlace = ""
            comments = ""
            visitDate = Date()
            visitDateIsValid = false
            hoursWorked = 0
            sealings = 0
            endowments = 0
            initiatories = 0
            confirmations = 0
            baptisms = 0
            type = ""
            isFavorite = false
            pictureData = nil
            pictureBase64String = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
        if eName == "picture" {
            pictureBase64String += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "holyPlace": holyPlace = value
        case "comments": comments = currentText
        case "dateVisited":
            if let date = parseImportedVisitDate(value) {
                visitDate = date
                visitDateIsValid = true
            } else {
                visitDateIsValid = false
                print("Import: could not parse dateVisited '\(value)'")
            }
        case "hoursWorked": hoursWorked = Double(value) ?? 0
        case "sealings": sealings = Int16(value) ?? 0
        case "endowments": endowments = Int16(value) ?? 0
        case "initiatories": initiatories = Int16(value) ?? 0
        case "confirmations": confirmations = Int16(value) ?? 0
        case "baptisms": baptisms = Int16(value) ?? 0
        case "type": type = value
        case "isFavorite": isFavorite = value.lowercased() == "true"
        case "picture":
            let base64 = pictureBase64String.trimmingCharacters(in: .whitespacesAndNewlines)
            if !base64.isEmpty {
                if let data = Data(base64Encoded: base64) {
                    pictureData = VisitPhotoCompression.encodedData(from: data) ?? data
                } else {
                    print("Import: failed to decode Base64 image data for visit: \(holyPlace)")
                }
            }
        default:
            break
        }
        currentText = ""
        eName = ""
        if elementName == "Visit" {
            saveImportedVisit()
        }
    }

    private func refreshFileName() {
        let stamp = fileDateFormatter.string(from: Date())
        if profilesEnabled {
            let profileName = ProfileManager.shared.activeProfileName().replacingOccurrences(of: " ", with: "_")
            fileName = "HolyPlaces_\(profileName)_Visits-\(stamp)"
        } else {
            fileName = "HolyPlacesVisits-\(stamp)"
        }
    }

    private func calculateEstimatedFileSize(includePhotos: Bool) -> Int64 {
        let context = ad.persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
                fetchRequest.predicate = ProfileManager.shared.visitProfilePredicate()
                let searchResults = try context.fetch(fetchRequest)
                var estimated: Int64 = 1000
                for visit in searchResults {
                    estimated += Int64(visit.holyPlace?.count ?? 0) * 2
                    estimated += Int64(visit.comments?.count ?? 0) * 2
                    estimated += 200
                    if includePhotos, let pictureData = visit.picture {
                        let jpegBytes = VisitPhotoCompression.encodedData(from: pictureData)?.count ?? pictureData.count
                        estimated += Int64((jpegBytes + 2) / 3 * 4) + 40
                    }
                }
                return estimated
            } catch {
                print("Error calculating file size: \(error)")
                return 0
            }
        }
    }

    private func buildExport(type: String) {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        fetchRequest.predicate = ProfileManager.shared.visitProfilePredicate()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: true)]
        let profileLabel = profilesEnabled ? " (\(ProfileManager.shared.activeProfileName()))" : ""
        if type == "txt" {
            exportText = "My Holy Places Visits\(profileLabel)\n Exported on \(displayDateFormatter.string(from: Date()))\n"
        } else {
            let exportStamp = ISO8601DateFormatter().string(from: Date())
            exportText = "<?xml version=\"1.0\" encoding=\"utf-8\"?><Document><ExportDate>\(exportStamp)</ExportDate>"
            if profilesEnabled {
                exportText.append("<Profile>\(xmlEscape(ProfileManager.shared.activeProfileName()))</Profile>")
            }
        }
        do {
            let searchResults = try ad.persistentContainer.viewContext.fetch(fetchRequest)
            exportCount = searchResults.count
            switch type {
            case "txt":
                exportText.append(" Total Number of Visits: \(exportCount)\n\n")
            case "csv":
                exportText = "holyPlace,type,dateVisited,comments,hoursWorked,sealings,endowments,initiatories,confirmations,baptisms,isFavorite\n"
            default:
                exportText.append("<TotalVisits>\(searchResults.count)</TotalVisits><Visits>")
            }
            for visit in searchResults {
                guard let placeName = visit.holyPlace, let visited = visit.dateVisited else { continue }
                let commentsText = visit.comments ?? ""
                switch type {
                case "txt":
                    exportText.append("\(placeName)\n")
                    exportText.append("\(displayDateFormatter.string(from: visited))\n")
                    exportText.append(commentsText)
                    if visit.isFavorite {
                        exportText.append("\n⭐️ Favorite Visit")
                    }
                case "csv":
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateStyle = .short
                    let escapedComments = commentsText.replacingOccurrences(of: "\"", with: "\"\"")
                    exportText.append("\(placeName),\(visit.type ?? ""),\(dateFormatter2.string(from: visited)),\"\(escapedComments)\"")
                default:
                    exportText.append("<Visit><holyPlace>\(xmlEscape(placeName))</holyPlace>")
                    exportText.append("<type>\(xmlEscape(visit.type ?? ""))</type>")
                    exportText.append("<dateVisited>\(xmlDateFormatter.string(from: visited))</dateVisited>")
                    exportText.append("<comments>\(xmlCDATA(commentsText))</comments>")
                    exportText.append("<isFavorite>\(visit.isFavorite)</isFavorite>")
                    if includePhotos, let pictureData = visit.picture {
                        if let exportData = VisitPhotoCompression.encodedData(from: pictureData) {
                            print("🔍 Export: Photo \(pictureData.count) → \(exportData.count) bytes for \(visit.holyPlace!)")
                            exportText.append("<picture><![CDATA[\(exportData.base64EncodedString())]]></picture>")
                        } else {
                            print("❌ Export: Picture data is not a valid image - omitting photo for \(visit.holyPlace!)")
                            exportText.append("<picture></picture>")
                        }
                    } else {
                        exportText.append("<picture></picture>")
                    }
                }
                if visit.type == "T" {
                    switch type {
                    case "txt":
                        if visit.shiftHrs > 0 { exportText.append("\n Hours Worked: \(visit.shiftHrs)") }
                        if visit.sealings > 0 { exportText.append("\n Sealings: \(visit.sealings)") }
                        if visit.endowments > 0 { exportText.append("\n Endowments: \(visit.endowments)") }
                        if visit.initiatories > 0 { exportText.append("\n Initiatories: \(visit.initiatories)") }
                        if visit.confirmations > 0 { exportText.append("\n Confirmations: \(visit.confirmations)") }
                        if visit.baptisms > 0 { exportText.append("\n Baptisms: \(visit.baptisms)") }
                    case "csv":
                        exportText.append(",\(visit.shiftHrs),\(visit.sealings),\(visit.endowments),\(visit.initiatories),\(visit.confirmations),\(visit.baptisms)")
                    default:
                        exportText.append("<hoursWorked>\(visit.shiftHrs)</hoursWorked>")
                        exportText.append("<sealings>\(visit.sealings)</sealings>")
                        exportText.append("<endowments>\(visit.endowments)</endowments>")
                        exportText.append("<initiatories>\(visit.initiatories)</initiatories>")
                        exportText.append("<confirmations>\(visit.confirmations)</confirmations>")
                        exportText.append("<baptisms>\(visit.baptisms)</baptisms>")
                    }
                }
                switch type {
                case "txt":
                    exportText.append("\n\n")
                case "csv":
                    exportText.append(",\(visit.isFavorite)\n")
                default:
                    exportText.append("</Visit>")
                }
            }
            if type == "xml" {
                exportText.append("</Visits></Document>")
            }
            if type == "xml" && includePhotos {
                let photoCount = searchResults.filter { $0.picture != nil }.count
                statusMessage = "Exported \(exportCount) visits with \(photoCount) photos to \(type) file."
            } else {
                statusMessage = "Exported \(exportCount) visits to \(type) file."
            }
            statusUsesPlaceColor = true
            ad.needsVisitRefresh = true
            ad.getVisits()
        } catch {
            print("Error with request: \(error)")
        }
    }

    private func saveImportedVisit() {
        if !visitDateIsValid || holyPlace.isEmpty {
            skippedInvalid += 1
            return
        }
        let context = ad.persistentContainer.viewContext
        if !allPlaces.contains(where: { $0.templeName == holyPlace }) {
            for temple in allPlaces {
                if let change = temple.nameChanges.first(where: { $0.oldName == holyPlace }) {
                    if let cutoff = change.changeDate, visitDate < cutoff {
                        print("📅 Imported visit kept as '\(holyPlace)' (visit date predates rename to \(temple.templeName))")
                    } else {
                        print("🛠 Imported visit renamed from \(holyPlace) to \(temple.templeName)")
                        holyPlace = temple.templeName
                    }
                    break
                }
            }
        }
        do {
            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dateVisited == %@ && holyPlace == %@", visitDate as NSDate, holyPlace as String)
            let searchResults = try context.fetch(fetchRequest)
            if searchResults.isEmpty {
                let visit = Visit(context: context)
                visit.holyPlace = holyPlace
                visit.baptisms = baptisms
                visit.confirmations = confirmations
                visit.initiatories = initiatories
                visit.endowments = endowments
                visit.sealings = sealings
                visit.comments = comments
                visit.dateVisited = visitDate
                visit.year = ad.calendarYearString(for: visitDate)
                visit.type = type
                visit.shiftHrs = hoursWorked
                visit.isFavorite = isFavorite
                visit.picture = pictureData
                visit.profileId = ProfileManager.shared.effectiveProfileId()
                if pictureData != nil {
                    photoImportCount += 1
                    print("🔍 Import: Saved photo data, size: \(pictureData!.count) bytes for visit: \(holyPlace)")
                }
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save \(error), \(error.userInfo)")
                }
                importCount += 1
            } else {
                let existingVisit = searchResults[0]
                var commentsChanged = false
                if overwriteComments && (existingVisit.comments ?? "") != comments {
                    existingVisit.comments = comments
                    commentsChanged = true
                    commentsUpdated += 1
                }
                let addedPhoto = existingVisit.picture == nil && pictureData != nil
                if addedPhoto {
                    print("🔍 Import: Updating existing visit with photo for: \(holyPlace)")
                    existingVisit.picture = pictureData
                    photoImportCount += 1
                }
                if commentsChanged || addedPhoto {
                    do {
                        try context.save()
                    } catch let error as NSError {
                        print("Could not save updated visit \(error), \(error.userInfo)")
                    }
                    if addedPhoto {
                        importCount += 1
                    }
                } else {
                    duplicates += 1
                }
            }
        } catch {
            print("Error with request: \(error)")
        }
    }

    private func parseImportedVisitDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let date = xmlDateFormatter.date(from: trimmed) {
            return Calendar.current.startOfDay(for: date)
        }
        if let date = legacyFullDateFormatter.date(from: trimmed) {
            return Calendar.current.startOfDay(for: date)
        }
        if let date = legacyEnglishFullDateFormatter.date(from: trimmed) {
            return Calendar.current.startOfDay(for: date)
        }
        return nil
    }

    private func xmlEscape(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    private func xmlCDATA(_ string: String) -> String {
        let safe = string.replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>")
        return "<![CDATA[\(safe)]]>"
    }
}
