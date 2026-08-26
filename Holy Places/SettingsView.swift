//
//  SettingsView.swift
//  Holy Places
//
//  Created by Derek Cordon on 8/26/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

final class SettingsModel: ObservableObject {
    @Published var visitGoalText: String
    @Published var baptismGoalText: String
    @Published var initiatoryGoalText: String
    @Published var endowmentGoalText: String
    @Published var sealingGoalText: String
    @Published var excludeNonOrdinance: Bool
    @Published var colorTheme: ColorThemeOption
    @Published var showTypeSymbols: Bool
    @Published var notificationsEnabled: Bool
    @Published var notifyTemplesOnly: Bool
    @Published var minutesDelayText: String
    @Published var imageOption: HomeImageOption
    @Published var homeTextColorIndex: Int
    @Published var commentsText: String
    @Published var addDaysText: String
    @Published var hoursWorkedEnabled: Bool
    @Published var profilesOn: Bool
    @Published var alternateImageData: Data?
    @Published var alertMessage: String?

    init() {
        visitGoalText = String(annualVisitGoal)
        baptismGoalText = String(annualBaptismGoal)
        initiatoryGoalText = String(annualInitiatoryGoal)
        endowmentGoalText = String(annualEndowmentGoal)
        sealingGoalText = String(annualSealingGoal)
        excludeNonOrdinance = excludeNonOrdinanceVisits
        colorTheme = ColorThemeOption.from(theme: UserDefaults.standard.string(forKey: "themeSelected") ?? theme)
        showTypeSymbols = UserDefaults.standard.bool(forKey: "showPlaceTypeSymbols")
        notificationsEnabled = notificationEnabled
        notifyTemplesOnly = notificationFilter
        if notificationDelayInMinutes == 0 {
            notificationDelayInMinutes = 30
        }
        minutesDelayText = String(notificationDelayInMinutes)
        if homeDefaultPicture {
            imageOption = .defaultImage
        } else if homeVisitPicture {
            imageOption = .randomImage
        } else {
            imageOption = .specificImage
        }
        homeTextColorIndex = Int(homeTextColor)
        commentsText = defaultCommentsText
        addDaysText = String(copyAddDays)
        hoursWorkedEnabled = ordinanceWorker
        profilesOn = profilesEnabled
        alternateImageData = homeAlternatePicture
    }

    func commit() {
        annualVisitGoal = Int(visitGoalText) ?? 0
        annualBaptismGoal = Int(baptismGoalText) ?? 0
        annualInitiatoryGoal = Int(initiatoryGoalText) ?? 0
        annualEndowmentGoal = Int(endowmentGoalText) ?? 0
        annualSealingGoal = Int(sealingGoalText) ?? 0
        excludeNonOrdinanceVisits = excludeNonOrdinance
        notificationEnabled = notificationsEnabled
        notificationFilter = notifyTemplesOnly
        notificationDelayInMinutes = Int16(minutesDelayText) ?? 30
        homeTextColor = Int16(homeTextColorIndex)
        defaultCommentsText = commentsText
        copyAddDays = Int16(addDaysText) ?? 7
        ordinanceWorker = hoursWorkedEnabled
    }

    func reloadGoalsFromGlobals() {
        visitGoalText = String(annualVisitGoal)
        baptismGoalText = String(annualBaptismGoal)
        initiatoryGoalText = String(annualInitiatoryGoal)
        endowmentGoalText = String(annualEndowmentGoal)
        sealingGoalText = String(annualSealingGoal)
    }

    func applyColorTheme(_ option: ColorThemeOption) {
        theme = option.storedValue
        UserDefaults.standard.set(theme, forKey: "themeSelected")
        themeChanged = true
        applyThemeColors()
    }

    func applyTypeSymbols(_ enabled: Bool) {
        showPlaceTypeSymbols = enabled
        UserDefaults.standard.set(enabled, forKey: "showPlaceTypeSymbols")
        themeChanged = true
    }

    func applyNotifications(_ enabled: Bool) {
        notificationEnabled = enabled
        if enabled {
            ad.locationServiceSetup()
        }
    }

    func selectImageOption(_ option: HomeImageOption) -> Bool {
        switch option {
        case .defaultImage:
            homeDefaultPicture = true
            homeVisitPicture = false
            homeTextColor = 0
            homeTextColorIndex = 0
            imageOption = .defaultImage
            notifyHomeAppearanceChanged()
            return true
        case .randomImage:
            if !ad.hasVisitPictures() {
                alertMessage = "You haven't added any Visit images yet."
                return false
            }
            homeVisitPicture = true
            homeDefaultPicture = false
            imageOption = .randomImage
            ad.pickRandomHomeVisitPhoto()
            ad.needsVisitRefresh = true
            notifyHomeAppearanceChanged()
            return true
        case .specificImage:
            if homeAlternatePicture == nil {
                alertMessage = "You haven't imported an image below."
                return false
            }
            homeVisitPicture = false
            homeDefaultPicture = false
            imageOption = .specificImage
            notifyHomeAppearanceChanged()
            return true
        }
    }

    func applyImportedImage(_ data: Data) {
        homeAlternatePicture = data
        alternateImageData = data
        homeVisitPicture = false
        homeDefaultPicture = false
        imageOption = .specificImage
        notifyHomeAppearanceChanged()
    }

    func applyHomeTextColor(_ index: Int) {
        homeTextColorIndex = index
        homeTextColor = Int16(index)
        notifyHomeAppearanceChanged()
    }

    func notifyHomeAppearanceChanged() {
        NotificationCenter.default.post(name: .homeAppearanceDidChange, object: nil)
    }

    func applyProfilesEnabled(_ enabled: Bool) {
        profilesEnabled = enabled
        if enabled {
            ad.migrateToProfiles()
            ad.loadGoalsFromActiveProfile()
        } else {
            if let defaultId = ProfileManager.shared.defaultProfile()?.value(forKey: "profileId") as? String {
                activeProfileId = defaultId
                UserDefaults.standard.set(defaultId, forKey: "activeProfileId")
            }
            ad.loadGoalsFromSettings()
        }
        reloadGoalsFromGlobals()
        ad.needsVisitRefresh = true
        ad.getVisits()
        NotificationCenter.default.post(name: ProfileManager.profileDidChangeNotification, object: nil)
    }
}

enum ColorThemeOption: Int, CaseIterable, Identifiable {
    case redGreen = 0
    case purpleOrange = 1
    case mono = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .redGreen: return "Red / Green"
        case .purpleOrange: return "Purple / Orange"
        case .mono: return "Mono"
        }
    }

    var storedValue: String {
        switch self {
        case .redGreen: return "4414"
        case .purpleOrange: return "3830"
        case .mono: return "mono"
        }
    }

    static func from(theme: String) -> ColorThemeOption {
        switch theme {
        case "4414": return .redGreen
        case "mono": return .mono
        default: return .purpleOrange
        }
    }
}

enum HomeImageOption: Int, CaseIterable, Identifiable {
    case defaultImage = 0
    case randomImage = 1
    case specificImage = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .defaultImage: return "Default Image"
        case .randomImage: return "Random Image"
        case .specificImage: return "Specific Image"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsModel
    var onManageProfiles: () -> Void

    @State private var showImagePicker = false
    @FocusState private var focusedField: SettingsField?

    private let rowFont = Font.custom("Baskerville", size: 18)
    private let nelsonQuote = """
"I urge you to find a way to make an appointment regularly with the Lord--to be in His holy house--then keep that appointment with exactness and joy.  I promise you that the Lord will bring the miracles He knows you need as you make sacrifices to serve and worship in His temples."
           - President Russell M. Nelson (Oct 2018)
"""

    var body: some View {
        Form {
            goalsSection
            colorThemeSection
            reminderSection
            homeScreenSection
            commentsSection
            copyVisitSection
            ordinanceWorkerSection
            profilesSection
        }
        .tint(Color("BaptismsBlue"))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.custom("Baskerville", size: 17))
                .foregroundColor(Color("BaptismsBlue"))
            }
        }
        .alert("Not Available", isPresented: Binding(
            get: { model.alertMessage != nil },
            set: { if !$0 { model.alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.alertMessage = nil }
        } message: {
            Text(model.alertMessage ?? "")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { data in
                if let data = data {
                    model.applyImportedImage(data)
                }
            }
        }
    }

    private var goalsSection: some View {
        Section {
            numberRow("Temple Visits", text: $model.visitGoalText, field: .visitGoal)
            Toggle("Exclude Visits with No Ordinances", isOn: $model.excludeNonOrdinance)
                .font(rowFont)
                .listRowInsets(EdgeInsets(top: 8, leading: 36, bottom: 8, trailing: 16))
                .onChange(of: model.excludeNonOrdinance) { newValue in
                    excludeNonOrdinanceVisits = newValue
                }
            numberRow("Baptisms and/or Confirmations", text: $model.baptismGoalText, field: .baptismGoal)
            numberRow("Initiatories", text: $model.initiatoryGoalText, field: .initiatoryGoal)
            numberRow("Endowments", text: $model.endowmentGoalText, field: .endowmentGoal)
            numberRow("Sealings", text: $model.sealingGoalText, field: .sealingGoal)
        } header: {
            Text("Annual Temple Goals")
        } footer: {
            Text(nelsonQuote)
                .italic()
        }
    }

    private var colorThemeSection: some View {
        Section {
            Picker("Color Theme", selection: $model.colorTheme) {
                ForEach(ColorThemeOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: model.colorTheme) { newValue in
                model.applyColorTheme(newValue)
            }
            Toggle("Show Type Symbols", isOn: $model.showTypeSymbols)
                .font(rowFont)
                .onChange(of: model.showTypeSymbols) { newValue in
                    model.applyTypeSymbols(newValue)
                }
        } header: {
            Text("Color Theme")
        } footer: {
            Text("Choose which color theme to use for the different types of places. Original color scheme was red for temples and green for historic sites. Mono uses black (light mode) or white (dark mode) for place names and ordinances; map pins keep the Purple / Orange colors. Turn on Show Type Symbols to mark each place type on the Places and Visits lists and in filter menus.")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Enable Visit Notifications", isOn: $model.notificationsEnabled)
                .font(rowFont)
                .onChange(of: model.notificationsEnabled) { newValue in
                    model.applyNotifications(newValue)
                }
            Toggle("Only Notify for Temples", isOn: $model.notifyTemplesOnly)
                .font(rowFont)
                .disabled(!model.notificationsEnabled)
                .onChange(of: model.notifyTemplesOnly) { newValue in
                    notificationFilter = newValue
                }
            numberRow("Reminder Delay (in minutes)", text: $model.minutesDelayText, field: .minutesDelay)
                .disabled(!model.notificationsEnabled)
        } header: {
            Text("Track Visit Reminder")
        } footer: {
            Text("Enabling this notification feature will remind you to record your visit to a Holy Place a configurable number of minutes after your visit.\n\nNOTE: You must allow both Location \"Always\" and Notifications for this feature.")
        }
    }

    private var homeScreenSection: some View {
        Section {
            Picker("Background Image", selection: $model.imageOption) {
                ForEach(HomeImageOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: model.imageOption) { newValue in
                if !model.selectImageOption(newValue) {
                    if homeDefaultPicture {
                        model.imageOption = .defaultImage
                    } else if homeVisitPicture {
                        model.imageOption = .randomImage
                    } else {
                        model.imageOption = .specificImage
                    }
                }
            }

            ZStack {
                Group {
                    if let data = model.alternateImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(UIColor.secondarySystemFill)
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
                .opacity(0.75)

                Button(model.alternateImageData == nil ? "Import Image" : "Change Image") {
                    showImagePicker = true
                }
                .font(.custom("Baskerville", size: 20))
                .foregroundColor(model.homeTextColorIndex == 0 ? .white : .black)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
            }
            .listRowInsets(EdgeInsets())

            HStack {
                Text("Text Color")
                    .font(rowFont)
                Spacer()
                Picker("Text Color", selection: $model.homeTextColorIndex) {
                    Text("White").tag(0)
                    Text("Black").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
            }
            .onChange(of: model.homeTextColorIndex) { newValue in
                model.applyHomeTextColor(newValue)
            }
        } header: {
            Text("Customize Home Screen")
        } footer: {
            Text("Select from the available background image options.  The Random Image option will select from the images you have attached to the visits.  To use a specific image, import the image using the above button.")
        }
    }

    private var commentsSection: some View {
        Section {
            TextField("Enter default comments text", text: $model.commentsText)
                .font(rowFont)
                .focused($focusedField, equals: .comments)
        } header: {
            Text("Visit Comments")
        } footer: {
            Text("Configure the default text shown in the comments when recording a new visit.")
        }
    }

    private var copyVisitSection: some View {
        Section {
            numberRow("Days to add for Copy Action", text: $model.addDaysText, field: .addDays)
        } header: {
            Text("Copy Visit")
        } footer: {
            Text("Configure how many days will be automatically added when the Copy swipe action is selected for an existing Visit.")
        }
    }

    private var ordinanceWorkerSection: some View {
        Section {
            Toggle("Enable Hours Worked Entry", isOn: $model.hoursWorkedEnabled)
                .font(rowFont)
                .onChange(of: model.hoursWorkedEnabled) { newValue in
                    ordinanceWorker = newValue
                }
        } header: {
            Text("Ordinance Worker")
        } footer: {
            Text("Enabling this option will allow you to enter the number of hours you worked on a given day when recording a temple visit.")
        }
    }

    private var profilesSection: some View {
        Section {
            Toggle("Enable Profiles", isOn: $model.profilesOn)
                .font(rowFont)
                .onChange(of: model.profilesOn) { newValue in
                    model.applyProfilesEnabled(newValue)
                }
            if model.profilesOn {
                Button(action: onManageProfiles) {
                    HStack {
                        Text("Manage Profiles")
                            .font(rowFont)
                            .foregroundColor(Color("BaptismsBlue"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                }
            }
        } header: {
            Text("Profiles")
        } footer: {
            Text("Track visits separately for family members.")
        }
    }

    private func numberRow(_ title: String, text: Binding<String>, field: SettingsField) -> some View {
        HStack {
            Text(title)
                .font(rowFont)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(rowFont)
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: field)
                .onChange(of: focusedField) { newValue in
                    if newValue == field {
                        DispatchQueue.main.async {
                            UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                        }
                    }
                }
        }
    }
}

private enum SettingsField: Hashable {
    case visitGoal, baptismGoal, initiatoryGoal, endowmentGoal, sealingGoal
    case minutesDelay, comments, addDays
}

struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (Data?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (Data?) -> Void

        init(onImagePicked: @escaping (Data?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image?.jpegData(compressionQuality: 1))
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onImagePicked(nil)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView(model: SettingsModel(), onManageProfiles: {})
    }
}
