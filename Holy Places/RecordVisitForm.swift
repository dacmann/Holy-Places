//
//  RecordVisitForm.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreData
import SwiftUI
import UIKit

final class RecordVisitModel: ObservableObject {
    @Published var place: Temple
    @Published var isDirty = false
    var existingVisit: Visit?
    init(place: Temple, existingVisit: Visit? = nil) {
        self.place = place
        self.existingVisit = existingVisit
    }
}

struct RecordVisitForm: View {
    @ObservedObject var model: RecordVisitModel
    var onCancel: () -> Void
    var onSaved: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var placeName: String
    @State private var placeType: String
    @State private var resolvedPlace: Temple
    @State private var visitDate: Date
    @State private var comments: String
    @State private var hoursText: String
    @State private var hoursValue: Double
    @State private var sealingsText: String
    @State private var sealingsValue: Double
    @State private var endowmentsText: String
    @State private var endowmentsValue: Double
    @State private var initiatoriesText: String
    @State private var initiatoriesValue: Double
    @State private var confirmationsText: String
    @State private var confirmationsValue: Double
    @State private var baptismsText: String
    @State private var baptismsValue: Double
    @State private var isFavorite: Bool
    @State private var photo: UIImage?
    @State private var profiles: [RecordVisitProfileChip]
    @State private var selectedProfileIds: Set<String>
    @State private var showProfileChips: Bool
    @State private var consumedNotification: Bool
    @State private var consumedCopy: Bool

    @State private var allowDirty = false
    @State private var didFinishAppearSetup = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showDateSheet = false
    @State private var draftDate = Date()
    @State private var showPlacePicker = false
    @State private var showPhotoPicker = false
    @State private var showPhotoViewer = false
    @State private var showAchievements = false
    @State private var unlockedAchievements: [Achievement] = []
    @State private var savedAwaitingAchievements = false
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var popoverSource: UIView?

    @FocusState private var focusedField: VisitField?

    init(model: RecordVisitModel, onCancel: @escaping () -> Void, onSaved: @escaping () -> Void) {
        self.model = model
        self.onCancel = onCancel
        self.onSaved = onSaved
        let seed = VisitFormSeed.make(model: model)
        _placeName = State(initialValue: seed.placeName)
        _placeType = State(initialValue: seed.placeType)
        _resolvedPlace = State(initialValue: seed.resolvedPlace)
        _visitDate = State(initialValue: seed.visitDate)
        _comments = State(initialValue: seed.comments)
        _hoursText = State(initialValue: seed.hoursText)
        _hoursValue = State(initialValue: seed.hoursValue)
        _sealingsText = State(initialValue: seed.sealingsText)
        _sealingsValue = State(initialValue: seed.sealingsValue)
        _endowmentsText = State(initialValue: seed.endowmentsText)
        _endowmentsValue = State(initialValue: seed.endowmentsValue)
        _initiatoriesText = State(initialValue: seed.initiatoriesText)
        _initiatoriesValue = State(initialValue: seed.initiatoriesValue)
        _confirmationsText = State(initialValue: seed.confirmationsText)
        _confirmationsValue = State(initialValue: seed.confirmationsValue)
        _baptismsText = State(initialValue: seed.baptismsText)
        _baptismsValue = State(initialValue: seed.baptismsValue)
        _isFavorite = State(initialValue: seed.isFavorite)
        _photo = State(initialValue: seed.photo)
        _profiles = State(initialValue: seed.profiles)
        _selectedProfileIds = State(initialValue: seed.selectedProfileIds)
        _showProfileChips = State(initialValue: seed.showProfileChips)
        _consumedNotification = State(initialValue: seed.consumedNotification)
        _consumedCopy = State(initialValue: seed.consumedCopy)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                nameRow
                dateButton
                Rectangle()
                    .fill(Color(white: 0.33))
                    .frame(height: 1)
                    .padding(.vertical, 4)
                notesSection
                if showProfileChips {
                    profileSection
                        .padding(.top, 8)
                }
                if placeType == "T" {
                    ordinanceSection
                        .padding(.top, 16)
                }
                if let photo {
                    Button {
                        showPhotoViewer = true
                    } label: {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                Button(photo == nil ? "Add Picture" : "Remove Picture", action: addOrRemovePhoto)
                    .font(fieldFont)
                    .foregroundStyle(Color("BaptismsBlue"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(model.existingVisit == nil ? "Record Visit" : "Edit Visit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
                    .font(.custom("Baskerville", size: 17))
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .font(.custom("Baskerville", size: 17))
                    .disabled(isSaving)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(.custom("Baskerville", size: 17))
                    .foregroundStyle(Color("BaptismsBlue"))
            }
        }
        .onAppear(perform: finishAppearSetup)
        .onChange(of: focusedField) { old, new in
            if let old {
                commit(old)
            }
            guard new != nil, new != .comments else { return }
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
            }
        }
        .onChange(of: comments) { _, _ in markDirty() }
        .onChange(of: hoursText) { _, _ in markDirty() }
        .onChange(of: sealingsText) { _, _ in markDirty() }
        .onChange(of: endowmentsText) { _, _ in markDirty() }
        .onChange(of: initiatoriesText) { _, _ in markDirty() }
        .onChange(of: confirmationsText) { _, _ in markDirty() }
        .onChange(of: baptismsText) { _, _ in markDirty() }
        .sheet(isPresented: $showDateSheet) {
            VisitDateSheet(date: $draftDate) {
                applyDate(draftDate)
                showDateSheet = false
            }
        }
        .sheet(isPresented: $showPlacePicker) {
            PlacePickerSheet(
                currentPlaceName: placeName,
                currentPlaceType: placeType,
                onCancel: { showPlacePicker = false },
                onSelect: { temple in
                    applyPlace(temple)
                    showPlacePicker = false
                }
            )
        }
        .sheet(isPresented: $showPhotoPicker) {
            VisitPhotoPicker { image in
                showPhotoPicker = false
                if let image {
                    photo = image
                    markDirty()
                }
            }
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            if let photo {
                PhotoViewerView(image: photo) {
                    showPhotoViewer = false
                }
            }
        }
        .sheet(isPresented: $showAchievements, onDismiss: {
            guard savedAwaitingAchievements else { return }
            savedAwaitingAchievements = false
            onSaved()
        }) {
            if !unlockedAchievements.isEmpty {
                AchievementUnlockedView(
                    achievements: unlockedAchievements,
                    onDismiss: { showAchievements = false },
                    onShare: { achievement in
                        shareItems = AchievementShareImageRenderer.shareItems(for: achievement)
                        showShare = true
                    }
                )
                .background(PopoverSourceReader { popoverSource = $0 })
                .sheet(isPresented: $showShare) {
                    ShareActivityView(activityItems: shareItems, popoverSource: popoverSource)
                }
            }
        }
        .alert("Save Error", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var isRegular: Bool { horizontalSizeClass == .regular }

    private var nameFont: Font { .custom("Baskerville", size: isRegular ? 30 : 26) }
    private var dateFont: Font { .custom("Baskerville", size: isRegular ? 28 : 24) }
    private var notesLabelFont: Font { .custom("Baskerville", size: isRegular ? 24 : 20) }
    private var notesFont: Font { .custom("Baskerville", size: isRegular ? 22 : 18) }
    private var fieldFont: Font { .custom("Baskerville", size: isRegular ? 24 : 20) }

    private var nameRow: some View {
        Button {
            showPlacePicker = true
        } label: {
            Text(placeName)
                .font(nameFont)
                .foregroundStyle(placeNameColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Changes the place for this visit")
        .overlay(alignment: .trailing) {
            Button {
                isFavorite.toggle()
                markDirty()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 22))
                    .foregroundStyle(isFavorite ? Color(uiColor: UIColor.darkTangerine()) : Color.gray)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Favorite" : "Mark as Favorite")
        }
    }

    private var placeNameColor: Color {
        switch placeType {
        case "T": return Color(uiColor: templeColor)
        case "H": return Color(uiColor: historicalColor)
        case "C": return Color(uiColor: constructionColor)
        case "V": return Color(uiColor: visitorCenterColor)
        default: return Color(uiColor: defaultColor)
        }
    }

    private var dateButton: some View {
        Button {
            draftDate = visitDate
            showDateSheet = true
        } label: {
            Text(formattedVisitDate(visitDate))
                .font(dateFont)
                .foregroundStyle(Color("BaptismsBlue"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Notes")
                .font(notesLabelFont)
            TextEditor(text: $comments)
                .font(notesFont)
                .focused($focusedField, equals: .comments)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Record for:")
                .font(.custom("Baskerville", size: 15))
                .foregroundStyle(.secondary)
            ChipFlowLayout(spacing: 6, rowSpacing: 6) {
                ForEach(profiles) { profile in
                    profileChip(profile)
                }
            }
        }
    }

    private func profileChip(_ profile: RecordVisitProfileChip) -> some View {
        let selected = selectedProfileIds.contains(profile.id)
        return Button {
            toggleProfile(profile.id)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: profile.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16, height: 16)
                Text(profile.name)
                    .font(.custom("Baskerville", size: 13))
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .frame(height: 32)
            .foregroundStyle(selected ? Color.white : Color.secondary)
            .background(selected ? Color("BaptismsBlue") : Color(uiColor: .systemGray5))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var ordinanceSection: some View {
        VStack(spacing: 20) {
            if ordinanceWorker {
                countRow(
                    "Hours Worked",
                    text: $hoursText,
                    value: hoursStepper,
                    range: 0...24,
                    step: 0.5,
                    color: hoursWorkedColor,
                    field: .hours
                )
            }
            countRow("Sealings", text: $sealingsText, value: sealingsStepper, range: 0...999, step: 1, color: sealingsColor, field: .sealings)
            countRow("Endowments", text: $endowmentsText, value: endowmentsStepper, range: 0...99, step: 1, color: endowmentsColor, field: .endowments)
            countRow("Initiatories", text: $initiatoriesText, value: initiatoriesStepper, range: 0...999, step: 1, color: initiatoriesColor, field: .initiatories)
            countRow("Confirmations", text: $confirmationsText, value: confirmationsStepper, range: 0...999, step: 1, color: confirmationsColor, field: .confirmations)
            countRow("Baptisms", text: $baptismsText, value: baptismsStepper, range: 0...999, step: 1, color: baptismsColor, field: .baptisms)
        }
    }

    private func countRow(
        _ title: String,
        text: Binding<String>,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        color: UIColor,
        field: VisitField
    ) -> some View {
        let tint = Color(uiColor: color)
        return HStack(spacing: 8) {
            Text(title)
                .font(fieldFont)
                .foregroundStyle(tint)
            Spacer(minLength: 8)
            TextField("0", text: text)
                .keyboardType(step < 1 ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .font(fieldFont)
                .foregroundStyle(tint)
                .frame(width: isRegular ? 72 : 52)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: field)
            Stepper(value: value, in: range, step: step) {
                Text(title)
            }
            .labelsHidden()
            .tint(tint)
        }
    }

    private var hoursStepper: Binding<Double> {
        Binding(
            get: { hoursValue },
            set: { newValue in
                guard newValue != hoursValue else { return }
                hoursValue = newValue
                hoursText = newValue.description
                markDirty()
            }
        )
    }

    private var sealingsStepper: Binding<Double> {
        integerStepper($sealingsValue, text: $sealingsText)
    }

    private var endowmentsStepper: Binding<Double> {
        integerStepper($endowmentsValue, text: $endowmentsText)
    }

    private var initiatoriesStepper: Binding<Double> {
        integerStepper($initiatoriesValue, text: $initiatoriesText)
    }

    private var confirmationsStepper: Binding<Double> {
        integerStepper($confirmationsValue, text: $confirmationsText)
    }

    private var baptismsStepper: Binding<Double> {
        integerStepper($baptismsValue, text: $baptismsText)
    }

    private func integerStepper(_ value: Binding<Double>, text: Binding<String>) -> Binding<Double> {
        Binding(
            get: { value.wrappedValue },
            set: { newValue in
                guard newValue != value.wrappedValue else { return }
                value.wrappedValue = newValue
                text.wrappedValue = Int(newValue).description
                markDirty()
            }
        )
    }

    private func finishAppearSetup() {
        guard !didFinishAppearSetup else { return }
        didFinishAppearSetup = true
        if consumedNotification {
            dateFromNotification = nil
            placeFromNotification = nil
        }
        if consumedCopy {
            copyVisit = nil
        }
        DispatchQueue.main.async {
            allowDirty = true
        }
    }

    private func markDirty() {
        guard allowDirty, !model.isDirty else { return }
        model.isDirty = true
    }

    private func formattedVisitDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd yyyy"
        return formatter.string(from: date)
    }

    private func applyDate(_ date: Date) {
        visitDate = date
        placeName = resolvedPlace.effectiveName(for: date)
        markDirty()
    }

    private func applyPlace(_ temple: Temple) {
        let previous = placeType
        resolvedPlace = temple
        model.place = temple
        placeType = temple.templeType
        placeName = temple.effectiveName(for: visitDate)
        if temple.templeType != "T", previous == "T" {
            zeroOrdinances()
        }
        markDirty()
    }

    private func zeroOrdinances() {
        hoursText = "0"
        sealingsText = "0"
        endowmentsText = "0"
        initiatoriesText = "0"
        confirmationsText = "0"
        baptismsText = "0"
        hoursValue = 0
        sealingsValue = 0
        endowmentsValue = 0
        initiatoriesValue = 0
        confirmationsValue = 0
        baptismsValue = 0
    }

    private func toggleProfile(_ profileId: String) {
        if selectedProfileIds.contains(profileId) {
            guard selectedProfileIds.count > 1 else { return }
            selectedProfileIds.remove(profileId)
        } else {
            selectedProfileIds.insert(profileId)
        }
        markDirty()
    }

    private func addOrRemovePhoto() {
        if photo != nil {
            photo = nil
            markDirty()
        } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            showPhotoPicker = true
        }
    }

    private func commit(_ field: VisitField) {
        switch field {
        case .hours:
            if hoursText.isEmpty { hoursText = "0" }
            hoursValue = min(24, max(0, Double(hoursText) ?? 0))
        case .sealings:
            if sealingsText.isEmpty { sealingsText = "0" }
            sealingsValue = min(999, max(0, Double(sealingsText) ?? 0))
        case .endowments:
            if endowmentsText.isEmpty { endowmentsText = "0" }
            endowmentsValue = min(99, max(0, Double(endowmentsText) ?? 0))
        case .initiatories:
            if initiatoriesText.isEmpty { initiatoriesText = "0" }
            initiatoriesValue = min(999, max(0, Double(initiatoriesText) ?? 0))
        case .confirmations:
            if confirmationsText.isEmpty { confirmationsText = "0" }
            confirmationsValue = min(999, max(0, Double(confirmationsText) ?? 0))
        case .baptisms:
            if baptismsText.isEmpty { baptismsText = "0" }
            baptismsValue = min(999, max(0, Double(baptismsText) ?? 0))
        case .comments:
            break
        }
    }

    private func save() {
        guard !isSaving else { return }
        focusedField = nil
        isSaving = true
        let previousIcons = snapshotCompletedAchievementIcons()
        if model.existingVisit == nil {
            saveNewVisit(previousIcons: previousIcons)
        } else {
            saveEditedVisit(previousIcons: previousIcons)
        }
    }

    private func saveNewVisit(previousIcons: Set<String>) {
        let baptismsVal = int16(baptismsText)
        let confirmationsVal = int16(confirmationsText)
        let initiatoriesVal = int16(initiatoriesText)
        let endowmentsVal = int16(endowmentsText)
        let sealingsVal = int16(sealingsText)
        let shiftHrsVal = doubleValue(hoursText)

        let imageData: Data?
        if let photo {
            guard let data = photo.jpegDataForVisitStorage() else {
                print("jpg error")
                isSaving = false
                return
            }
            imageData = data
        } else {
            imageData = nil
        }

        let profileIds: Set<String>
        if profilesEnabled && !selectedProfileIds.isEmpty {
            profileIds = selectedProfileIds
        } else {
            profileIds = [ProfileManager.shared.effectiveProfileId() ?? ""]
        }
        let commentsVal = commentsForSave(userNotes: comments, profileIds: profileIds)
        let record = VisitRecord(
            holyPlace: placeName,
            placeType: placeType,
            date: visitDate,
            baptisms: baptismsVal,
            confirmations: confirmationsVal,
            initiatories: initiatoriesVal,
            endowments: endowmentsVal,
            sealings: sealingsVal,
            comments: commentsVal,
            shiftHours: shiftHrsVal,
            isFavorite: isFavorite,
            imageData: imageData,
            profileIds: profileIds
        )

        do {
            try VisitStore.record(record)
            print("Saving Visit(s) completed successfully for \(profileIds.count) profile(s)")
        } catch {
            print("Could not save visit: \(error)")
            saveError = "Failed to save visit. Please try again."
            isSaving = false
            return
        }

        VisitDonation.donateRecordedVisit(
            holyPlace: placeName,
            date: visitDate,
            profileId: profileIds.first,
            baptisms: Int(baptismsVal),
            confirmations: Int(confirmationsVal),
            initiatories: Int(initiatoriesVal),
            endowments: Int(endowmentsVal),
            sealings: Int(sealingsVal),
            notes: commentsVal
        )
        finishSave(previousIcons: previousIcons)
    }

    private func saveEditedVisit(previousIcons: Set<String>) {
        guard let visit = model.existingVisit else {
            isSaving = false
            return
        }
        let context = ad.persistentContainer.viewContext
        visit.holyPlace = placeName
        visit.type = placeType
        if placeType == "T" {
            visit.sealings = int16(sealingsText)
            visit.endowments = int16(endowmentsText)
            visit.initiatories = int16(initiatoriesText)
            visit.confirmations = int16(confirmationsText)
            visit.baptisms = int16(baptismsText)
            visit.shiftHrs = doubleValue(hoursText)
        } else {
            visit.sealings = 0
            visit.endowments = 0
            visit.initiatories = 0
            visit.confirmations = 0
            visit.baptisms = 0
            visit.shiftHrs = 0
        }
        visit.dateVisited = visitDate
        if let dateVisited = visit.dateVisited {
            visit.year = ad.calendarYearString(for: dateVisited)
        } else {
            visit.year = ad.calendarYearString(for: Date())
        }
        visit.comments = comments
        visit.isFavorite = isFavorite
        if let photo {
            guard let imageData = photo.jpegDataForVisitStorage() else {
                print("jpg error")
                isSaving = false
                return
            }
            visit.picture = imageData
        } else {
            visit.picture = nil
        }

        do {
            try context.save()
            print("Saving edited Visit completed successfully")
        } catch {
            let nsError = error as NSError
            print("Could not save edited visit: \(nsError), \(nsError.userInfo)")
            saveError = "Failed to save visit changes. Please try again."
            isSaving = false
            return
        }

        ad.needsVisitRefresh = true
        ad.getVisits()
        if #available(iOS 27.0, *) {
            Task { try? await HolyPlacesSpotlightIndexer.reindexVisits() }
        }
        finishSave(previousIcons: previousIcons)
    }

    private func finishSave(previousIcons: Set<String>) {
        let unlocked = newlyUnlockedAchievements(since: previousIcons)
        if unlocked.isEmpty {
            onSaved()
        } else {
            unlockedAchievements = unlocked
            savedAwaitingAchievements = true
            showAchievements = true
        }
    }

    private func snapshotCompletedAchievementIcons() -> Set<String> {
        if ad.needsVisitRefresh {
            ad.getVisits()
        }
        return Set(completed.map { $0.iconName })
    }

    private func newlyUnlockedAchievements(since previousIcons: Set<String>) -> [Achievement] {
        completed.filter { $0.achieved != nil && !previousIcons.contains($0.iconName) }
    }

    private func commentsForSave(userNotes: String, profileIds: Set<String>) -> String {
        guard profilesEnabled else { return userNotes }
        if profileIds.count == 1, let onlyId = profileIds.first, onlyId == activeProfileId {
            return userNotes
        }
        let names = ProfileManager.shared.allProfiles().compactMap { profile -> String? in
            guard let pid = profile.value(forKey: "profileId") as? String, profileIds.contains(pid) else { return nil }
            return profile.value(forKey: "name") as? String
        }
        let suffix = "Visit Recorded for: \(names.joined(separator: ", "))"
        let trimmed = userNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return suffix
        }
        return trimmed + "\n\n" + suffix
    }

    private func int16(_ text: String) -> Int16 {
        Int16(text) ?? 0
    }

    private func doubleValue(_ text: String) -> Double {
        Double(text) ?? 0
    }
}

private enum VisitField: Hashable {
    case comments, hours, sealings, endowments, initiatories, confirmations, baptisms
}

private struct RecordVisitProfileChip: Identifiable {
    let id: String
    let name: String
    let iconName: String
}

private struct VisitFormSeed {
    var placeName: String
    var placeType: String
    var resolvedPlace: Temple
    var visitDate: Date
    var comments: String
    var hoursText: String
    var hoursValue: Double
    var sealingsText: String
    var sealingsValue: Double
    var endowmentsText: String
    var endowmentsValue: Double
    var initiatoriesText: String
    var initiatoriesValue: Double
    var confirmationsText: String
    var confirmationsValue: Double
    var baptismsText: String
    var baptismsValue: Double
    var isFavorite: Bool
    var photo: UIImage?
    var profiles: [RecordVisitProfileChip]
    var selectedProfileIds: Set<String>
    var showProfileChips: Bool
    var consumedNotification: Bool
    var consumedCopy: Bool

    static func make(model: RecordVisitModel) -> VisitFormSeed {
        if let visit = model.existingVisit {
            return editSeed(visit: visit, fallback: model.place)
        }
        return newSeed(place: model.place)
    }

    private static func newSeed(place: Temple) -> VisitFormSeed {
        var visitDate = Date()
        var comments = defaultCommentsText
        var hoursText = "0"
        var hoursValue = 0.0
        var sealingsText = "0"
        var sealingsValue = 0.0
        var endowmentsText = "0"
        var endowmentsValue = 0.0
        var initiatoriesText = "0"
        var initiatoriesValue = 0.0
        var confirmationsText = "0"
        var confirmationsValue = 0.0
        var baptismsText = "0"
        var baptismsValue = 0.0
        var consumedNotification = false
        var consumedCopy = false

        if place.templeName == placeFromNotification {
            visitDate = dateFromNotification ?? Date()
            comments = defaultCommentsText
            consumedNotification = true
        } else if let visitToCopy = copyVisit {
            if let dateVisited = visitToCopy.dateVisited as Date?,
               let modifiedDate = Calendar.current.date(byAdding: .day, value: Int(copyAddDays), to: dateVisited) {
                visitDate = modifiedDate
            } else {
                visitDate = Date()
            }
            hoursText = visitToCopy.shiftHrs.description
            hoursValue = visitToCopy.shiftHrs
            sealingsText = visitToCopy.sealings.description
            sealingsValue = Double(visitToCopy.sealings)
            endowmentsText = visitToCopy.endowments.description
            endowmentsValue = Double(visitToCopy.endowments)
            initiatoriesText = visitToCopy.initiatories.description
            initiatoriesValue = Double(visitToCopy.initiatories)
            confirmationsText = visitToCopy.confirmations.description
            confirmationsValue = Double(visitToCopy.confirmations)
            baptismsText = visitToCopy.baptisms.description
            baptismsValue = Double(visitToCopy.baptisms)
            comments = visitToCopy.comments ?? ""
            consumedCopy = true
        }

        var selectedProfileIds = Set<String>()
        var profiles: [RecordVisitProfileChip] = []
        var showProfileChips = false
        if profilesEnabled {
            if let activeId = activeProfileId {
                selectedProfileIds.insert(activeId)
            }
            let allProfiles = ProfileManager.shared.allProfiles()
            if allProfiles.count > 1 {
                profiles = allProfiles.map { profile in
                    RecordVisitProfileChip(
                        id: profile.value(forKey: "profileId") as? String ?? "",
                        name: profile.value(forKey: "name") as? String ?? "",
                        iconName: profile.value(forKey: "iconName") as? String ?? "person.fill"
                    )
                }
                showProfileChips = true
            }
        }

        return VisitFormSeed(
            placeName: place.templeName,
            placeType: place.templeType,
            resolvedPlace: place,
            visitDate: visitDate,
            comments: comments,
            hoursText: hoursText,
            hoursValue: min(24, max(0, hoursValue)),
            sealingsText: sealingsText,
            sealingsValue: min(999, max(0, sealingsValue)),
            endowmentsText: endowmentsText,
            endowmentsValue: min(99, max(0, endowmentsValue)),
            initiatoriesText: initiatoriesText,
            initiatoriesValue: min(999, max(0, initiatoriesValue)),
            confirmationsText: confirmationsText,
            confirmationsValue: min(999, max(0, confirmationsValue)),
            baptismsText: baptismsText,
            baptismsValue: min(999, max(0, baptismsValue)),
            isFavorite: false,
            photo: nil,
            profiles: profiles,
            selectedProfileIds: selectedProfileIds,
            showProfileChips: showProfileChips,
            consumedNotification: consumedNotification,
            consumedCopy: consumedCopy
        )
    }

    private static func editSeed(visit: Visit, fallback: Temple) -> VisitFormSeed {
        let currentName = visit.holyPlace ?? ""
        let resolved = allPlaces.first { $0.templeName == currentName }
            ?? allPlaces.first { $0.nameChanges.contains { $0.oldName == currentName } }
            ?? fallback
        let type = visit.type ?? ""
        let hours = visit.shiftHrs
        let sealings = Double(visit.sealings)
        let endowments = Double(visit.endowments)
        let initiatories = Double(visit.initiatories)
        let confirmations = Double(visit.confirmations)
        let baptisms = Double(visit.baptisms)
        var photo: UIImage?
        if let imageData = visit.picture {
            photo = UIImage(data: imageData as Data)
        }
        return VisitFormSeed(
            placeName: currentName,
            placeType: type,
            resolvedPlace: resolved,
            visitDate: (visit.dateVisited as Date?) ?? Date(),
            comments: visit.comments ?? "",
            hoursText: hours.description,
            hoursValue: min(24, max(0, hours)),
            sealingsText: visit.sealings.description,
            sealingsValue: min(999, max(0, sealings)),
            endowmentsText: visit.endowments.description,
            endowmentsValue: min(99, max(0, endowments)),
            initiatoriesText: visit.initiatories.description,
            initiatoriesValue: min(999, max(0, initiatories)),
            confirmationsText: visit.confirmations.description,
            confirmationsValue: min(999, max(0, confirmations)),
            baptismsText: visit.baptisms.description,
            baptismsValue: min(999, max(0, baptisms)),
            isFavorite: visit.isFavorite,
            photo: photo,
            profiles: [],
            selectedProfileIds: [],
            showProfileChips: false,
            consumedNotification: false,
            consumedCopy: false
        )
    }
}

private struct VisitDateSheet: View {
    @Binding var date: Date
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            DatePicker("Visit Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Color("BaptismsBlue"))
            Button(action: onDone) {
                Text("Done")
                    .font(.custom("Baskerville", size: 24))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 300)
                    .frame(height: 40)
                    .background(Color(red: 0, green: 0.250980407, blue: 0.501960814))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .tertiarySystemBackground))
        .presentationDetents([.medium, .large])
    }
}

private struct PlacePickerSheet: View {
    var currentPlaceName: String
    var currentPlaceType: String
    var onCancel: () -> Void
    var onSelect: (Temple) -> Void

    @State private var segment: Int
    @State private var searchText = ""
    @State private var closest: Bool
    @State private var pickerData: [Temple]
    @State private var filtered: [Temple]
    @State private var selectedName: String
    @State private var otherName: String
    @State private var didConfigure = false
    @State private var acceptSegmentChanges = false
    @State private var ignoreSearchChange = false
    @State private var suppressClosestOff = false
    @FocusState private var otherFocused: Bool
    @FocusState private var searchFocused: Bool

    init(currentPlaceName: String, currentPlaceType: String, onCancel: @escaping () -> Void, onSelect: @escaping (Temple) -> Void) {
        self.currentPlaceName = currentPlaceName
        self.currentPlaceType = currentPlaceType
        self.onCancel = onCancel
        self.onSelect = onSelect
        let match = Self.matchPlace(named: currentPlaceName)
        let type = match?.templeType ?? (currentPlaceType.isEmpty ? "O" : currentPlaceType)
        let initialSegment: Int
        switch type {
        case "H": initialSegment = 1
        case "V": initialSegment = 2
        case "O": initialSegment = 3
        default: initialSegment = 0
        }
        _segment = State(initialValue: initialSegment)
        _otherName = State(initialValue: initialSegment == 3 ? currentPlaceName : "")
        _closest = State(initialValue: UserDefaults.standard.bool(forKey: "addVisitClosestPlace"))
        let source = Self.sourcePlaces(for: initialSegment)
        _pickerData = State(initialValue: source)
        _filtered = State(initialValue: source)
        _selectedName = State(initialValue: source.first?.templeName ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Change Place")
                    .font(.custom("Baskerville", size: 22))
                TypeSegmentedControl(selection: $segment)
                if segment == 3 {
                    TextField("Enter name of place", text: $otherName)
                        .font(.custom("Baskerville", size: 20))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .focused($otherFocused)
                        .padding(.horizontal, 8)
                } else {
                    searchRow
                    PlaceWheel(places: filtered, segment: segment, selection: selectedName) { name in
                        selectedName = name
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    if !UserDefaults.standard.bool(forKey: "locationNotAllowed") {
                        HStack(spacing: 21) {
                            Toggle("Closest Place", isOn: $closest)
                                .labelsHidden()
                                .tint(Color("BaptismsBlue"))
                            Text("Closest Place")
                                .font(.custom("Baskerville", size: 20))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Change Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .font(.custom("Baskerville", size: 17))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: confirm)
                        .font(.custom("Baskerville", size: 17))
                        .disabled(!canConfirm)
                }
            }
            .onAppear {
                guard !didConfigure else { return }
                didConfigure = true
                reloadList(selectingCurrent: true)
                if segment == 3 {
                    otherFocused = true
                }
                DispatchQueue.main.async {
                    acceptSegmentChanges = true
                }
            }
            .onChange(of: segment) { _, newValue in
                guard acceptSegmentChanges else { return }
                reloadList(selectingCurrent: false)
                if newValue == 3 {
                    otherFocused = true
                }
            }
            .onChange(of: searchText) { _, _ in
                if ignoreSearchChange {
                    ignoreSearchChange = false
                    return
                }
                applySearch(preferRandom: false)
            }
            .onChange(of: closest) { _, isOn in
                if suppressClosestOff, !isOn {
                    suppressClosestOff = false
                    return
                }
                if isOn {
                    if UserDefaults.standard.bool(forKey: "locationAllowed") {
                        UserDefaults.standard.set(true, forKey: "addVisitClosestPlace")
                        sortByDistance()
                    } else {
                        ad.locationServiceSetup()
                        suppressClosestOff = true
                        closest = false
                    }
                } else {
                    UserDefaults.standard.set(false, forKey: "addVisitClosestPlace")
                    sortByNameAndSelectRandom()
                }
            }
        }
    }

    private var searchRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search places...", text: $searchText)
                .font(.custom("Baskerville", size: 17))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit { searchFocused = false }
            Button("Cancel") {
                searchFocused = false
                let randomize = !closest
                if searchText.isEmpty {
                    applySearch(preferRandom: randomize)
                } else {
                    ignoreSearchChange = true
                    searchText = ""
                    applySearch(preferRandom: randomize)
                }
            }
            .font(.custom("Baskerville", size: 17))
        }
    }

    private var canConfirm: Bool {
        if segment == 3 {
            return !otherName.isEmpty
        }
        return filtered.contains { $0.templeName == selectedName }
    }

    private func confirm() {
        if segment == 3 {
            let name = otherName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            onSelect(Temple(
                Name: name,
                Address: "",
                Snippet: "",
                CityState: "",
                Country: "",
                Phone: "",
                Latitude: 0.0,
                Longitude: 0.0,
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
        } else if let temple = filtered.first(where: { $0.templeName == selectedName }) {
            onSelect(temple)
        }
    }

    private func reloadList(selectingCurrent: Bool) {
        clearSearchWithoutFiltering()
        guard segment != 3 else { return }
        pickerData = Self.sourcePlaces(for: segment)
        filtered = pickerData
        if closest {
            sortByDistance()
        } else {
            selectRandom()
        }
        if selectingCurrent {
            selectCurrentPlace()
        }
    }

    private func clearSearchWithoutFiltering() {
        guard !searchText.isEmpty else { return }
        ignoreSearchChange = true
        searchText = ""
    }

    private func applySearch(preferRandom: Bool) {
        if searchText.isEmpty {
            filtered = pickerData
        } else {
            let query = searchText.lowercased()
            filtered = pickerData.filter { $0.templeName.lowercased().contains(query) }
        }
        if closest {
            sortByDistance()
        } else if preferRandom {
            selectRandom()
        } else if let first = filtered.first {
            selectedName = first.templeName
        }
    }

    private func sortByDistance() {
        ad.updateDistance(placesToUpdate: filtered)
        filtered.sort {
            guard let distance1 = $0.distance, let distance2 = $1.distance else { return false }
            return Int(distance1) < Int(distance2)
        }
        if let first = filtered.first {
            selectedName = first.templeName
        }
    }

    private func sortByNameAndSelectRandom() {
        filtered.sort { $0.templeName < $1.templeName }
        selectRandom()
    }

    private func selectRandom() {
        guard !filtered.isEmpty else { return }
        let index = Int(arc4random_uniform(UInt32(filtered.count)))
        selectedName = filtered[index].templeName
    }

    private func selectCurrentPlace() {
        guard let match = Self.matchPlace(named: currentPlaceName),
              filtered.contains(where: { $0.templeName == match.templeName }) else { return }
        selectedName = match.templeName
    }

    private static func matchPlace(named name: String) -> Temple? {
        allPlaces.first { $0.templeName == name }
            ?? allPlaces.first { $0.nameChanges.contains { $0.oldName == name } }
    }

    private static func sourcePlaces(for segment: Int) -> [Temple] {
        switch segment {
        case 1: return historical
        case 2: return visitors
        default: return allTemples
        }
    }
}

private struct TypeSegmentedControl: UIViewRepresentable {
    @Binding var selection: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: ["Temple", "Historic", "V. Center", "Other"])
        control.selectedSegmentIndex = selection
        let font = UIFont(name: "Baskerville", size: 14) ?? .systemFont(ofSize: 14)
        control.setTitleTextAttributes([.font: font], for: .normal)
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
        init(selection: Binding<Int>) { self.selection = selection }
        @objc func changed(_ sender: UISegmentedControl) {
            selection.wrappedValue = sender.selectedSegmentIndex
        }
    }
}

private struct PlaceWheel: UIViewRepresentable {
    var places: [Temple]
    var segment: Int
    var selection: String
    var onSelect: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        let names = places.map(\.templeName)
        context.coordinator.onSelect = onSelect
        if context.coordinator.names != names || context.coordinator.segment != segment {
            context.coordinator.places = places
            context.coordinator.segment = segment
            context.coordinator.names = names
            picker.reloadAllComponents()
        }
        if let index = places.firstIndex(where: { $0.templeName == selection }),
           picker.numberOfRows(inComponent: 0) > index,
           picker.selectedRow(inComponent: 0) != index {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var places: [Temple] = []
        var names: [String] = []
        var segment = 0
        var onSelect: (String) -> Void

        init(onSelect: @escaping (String) -> Void) {
            self.onSelect = onSelect
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            places.count
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            guard row < places.count else { return label }
            let place = places[row]
            label.attributedText = NSAttributedString(
                string: place.templeName,
                attributes: [.font: UIFont(name: "Baskerville", size: 20) ?? .systemFont(ofSize: 20)]
            )
            label.textAlignment = .center
            label.textColor = rowColor(for: place)
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard row < places.count else { return }
            onSelect(places[row].templeName)
        }

        private func rowColor(for place: Temple) -> UIColor {
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
}

private struct VisitPhotoPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        context.coordinator.onImagePicked = onImagePicked
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImagePicked: (UIImage?) -> Void

        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let original = info[.originalImage] as? UIImage,
               let compressed = original.jpegDataForVisitStorage(),
               let displayImage = UIImage(data: compressed) {
                print("Visit photo compressed to \(compressed.count) bytes, size \(displayImage.size)")
                onImagePicked(displayImage)
            } else if let original = info[.originalImage] as? UIImage {
                onImagePicked(original)
            } else {
                onImagePicked(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
        }
    }
}

private struct PopoverSourceReader: UIViewRepresentable {
    var onResolve: (UIView) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard !context.coordinator.resolved else { return }
        context.coordinator.resolved = true
        DispatchQueue.main.async { onResolve(uiView) }
    }

    final class Coordinator {
        var resolved = false
    }
}

private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 6
    var rowSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
