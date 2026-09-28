//
//  HomeTabView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

struct HomeTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var revision = 0
    @State private var appearInFlight = false
    @State private var lastAppearUptime = 0.0
    @State private var showShare = false
    @State private var showInfo = false
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showChangesAlert = false
    @State private var changesAlertTitle = ""
    @State private var changesAlertMessage = ""
    @State private var whatsNewVersion: String?
    @State private var whatsNewMessage: String?

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            let regular = horizontalSizeClass == .regular
            let image = homeBackgroundImage(landscape: landscape, regularWidth: regular)
            let crop = cropToFill
            let tint = homeTint
            let light = homeTextIsLight
            let achievementSide: CGFloat = regular ? 100 : max(geo.size.width * 0.20, 1)
            let spacerHeight = geo.size.width * ((landscape && regular) ? 0.04 : 0.09)

            ZStack {
                VStack(spacing: 0) {
                    header(tint: tint, light: light, regular: regular)
                        .padding(.top, 12)
                        .padding(.horizontal, 10)
                    Spacer(minLength: 0)
                    goalBlock(tint: tint, light: light)
                        .padding(.horizontal, 16)
                    ZStack {
                        if let caption = visitDateCaption {
                            Text(caption)
                                .font(.custom("Baskerville", size: 18))
                                .foregroundStyle(tint)
                                .shadow(color: .gray, radius: 5)
                        }
                    }
                    .frame(height: max(spacerHeight, 0))
                    Color.clear.frame(height: 8)
                }

                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        if hasCompletedAchievement {
                            Button {
                                showAchievements = true
                            } label: {
                                Image(uiImage: latestAchievementImage)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(5)
                                    .frame(width: achievementSide, height: achievementSide)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Achievements")
                        }
                        Spacer()
                        shareButton(tint: tint)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                if let version = whatsNewVersion, let message = whatsNewMessage {
                    WhatsNewPopup(version: version, message: message) {
                        whatsNewMessage = nil
                        whatsNewVersion = nil
                    }
                    .frame(maxWidth: geo.size.width * 0.8)
                    .frame(maxHeight: geo.size.height * 0.7)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background {
                ZStack {
                    Color(uiColor: crop ? .black : image.complementaryFillColor())
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: crop ? .fill : .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
                .ignoresSafeArea()
            }
        }
        .simultaneousGesture(tabSwipe)
        .background {
            HomeAppearObserver(
                onWillAppear: { handleAppear() },
                onWillDisappear: { applyThemeColors() }
            )
            .allowsHitTesting(false)
        }
        .onAppear { handleAppear() }
        .onReceive(NotificationCenter.default.publisher(for: .homeAppearanceDidChange)) { _ in
            refreshAfterAppearanceChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: ProfileManager.profileDidChangeNotification)) { _ in
            revision += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            revision += 1
        }
        .sheet(isPresented: $showShare) {
            ShareView(onDismiss: { showShare = false })
        }
        .sheet(isPresented: $showInfo) {
            InfoView(onDismiss: { showInfo = false })
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsScreen(onDismiss: { showAchievements = false })
        }
        .sheet(isPresented: $showSettings) {
            SettingsScreenHost(isPresented: $showSettings)
        }
        .alert(changesAlertTitle, isPresented: $showChangesAlert) {
            Button("OK", role: .cancel) {
                changesDate = ""
            }
        } message: {
            Text(changesAlertMessage)
        }
    }

    private var tabSwipe: some Gesture {
        DragGesture(minimumDistance: 25, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 60 else { return }
                if dx < 0 {
                    AppRouter.shared.select(.places)
                } else {
                    AppRouter.shared.select(.map)
                }
            }
    }

    private func header(tint: Color, light: Bool, regular: Bool) -> some View {
        VStack(spacing: 0) {
            Text("Holy Places of the Lord")
                .font(.custom("Baskerville", size: regular ? 33 : 23))
                .multilineTextAlignment(.center)
                .modifier(HomeLabelStyle(color: tint, lightText: light, scrim: false))
                .padding(.bottom, 6)
            Rectangle()
                .fill(tint)
                .frame(width: 140, height: 1)
            Text("\"Stand ye in holy places, and be not moved...\"")
                .font(.custom("Baskerville-Italic", size: regular ? 30 : 20))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .modifier(HomeLabelStyle(color: tint, lightText: light, scrim: false))
                .padding(.top, 4)
                .padding(.horizontal, 10)
            HStack {
                Spacer()
                Text("D&C 87:8")
                    .font(.custom("Baskerville-Italic", size: regular ? 19 : 13))
                    .modifier(HomeLabelStyle(color: tint, lightText: light, scrim: false))
            }
            .padding(.top, 10)
            .padding(.trailing, 10)

            ZStack(alignment: .topLeading) {
                HStack {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(tint)
                            .shadow(color: .gray, radius: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Info")
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Text("\u{2699}\u{FE0E}")
                            .font(.system(size: 30))
                            .foregroundStyle(tint)
                            .shadow(color: .gray, radius: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }
                .padding(.top, 50)

                if profilesAreOn {
                    profileMenu(tint: tint)
                        .padding(.top, 10)
                        .padding(.leading, 8)
                }
            }
        }
    }

    private func profileMenu(tint: Color) -> some View {
        Menu {
            Section("Switch Profile") {
                ForEach(profileChoices) { choice in
                    Button {
                        guard let profile = ProfileManager.shared.profileById(choice.id) else { return }
                        ProfileManager.shared.setActiveProfile(profile)
                    } label: {
                        Label(
                            choice.id == activeProfileId ? "\(choice.name) ✓" : choice.name,
                            systemImage: choice.icon
                        )
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: activeProfileIcon)
                    .font(.system(size: 16, weight: .medium))
                Text(" \(activeProfileName) ")
                    .font(.custom("Baskerville", size: 14))
            }
            .foregroundStyle(tint)
            .frame(height: 36)
        }
    }

    private func goalBlock(tint: Color, light: Bool) -> some View {
        VStack(spacing: 2) {
            Text(goalTitleText)
                .font(.custom("Baskerville", size: 14))
                .tracking(3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .modifier(HomeLabelStyle(color: tint, lightText: light, scrim: true))
                .background(alignment: .top) {
                    tint.frame(height: 1).offset(y: -3)
                }
                .background(alignment: .bottom) {
                    tint.frame(height: 1).offset(y: 3)
                }
            Text(goalBodyText)
                .font(.custom("Baskerville", size: 22))
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .modifier(HomeLabelStyle(color: tint, lightText: light, scrim: true))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private func shareButton(tint: Color) -> some View {
        Button {
            showShare = true
        } label: {
            VStack(spacing: 0) {
                Image("share")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .shadow(color: .gray, radius: 5)
                Text("Share")
                    .font(.custom("Baskerville", size: 17))
                    .foregroundStyle(tint)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share")
    }

    private func handleAppear() {
        if appearInFlight { return }
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastAppearUptime < 0.35 { return }
        appearInFlight = true
        defer {
            appearInFlight = false
            lastAppearUptime = ProcessInfo.processInfo.systemUptime
        }

        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        if !previouslyLaunched {
            UserDefaults.standard.set(true, forKey: "previouslyLaunched")
            UserDefaults.standard.set("3830", forKey: "themeSelected")
            UserDefaults.standard.set(false, forKey: "addVisitClosestPlace")
            checkedForUpdate = Date()
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        currentYear = formatter.string(from: Date())

        if homeVisitPicture {
            ad.pickRandomHomeVisitPhoto()
        }
        if annualVisitGoal == 0 && ad.needsVisitRefresh {
            UserDefaults(suiteName: "group.net.dacworld.holyplaces")?.setValue("SET GOAL IN APP", forKey: "goalProgress")
        }
        if checkedForUpdate?.daysBetweenDate(toDate: Date()) ?? 1 > 0 {
            ad.refreshTemples()
        }
        if ad.needsVisitRefresh {
            ad.getVisits()
        }
        applyThemeColors()
        revision += 1
        presentStartupMessages()
    }

    private func refreshAfterAppearanceChange() {
        if ad.needsVisitRefresh {
            ad.getVisits()
        }
        revision += 1
    }

    private func presentStartupMessages() {
        if !changesDate.isEmpty {
            changesAlertTitle = changesDate + " Message"
            changesAlertMessage = combinedChangesMessage()
            showChangesAlert = true
        }

        guard whatsNewMessage == nil else { return }
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        if UserDefaults.standard.string(forKey: "lastAppVersionShown") == currentVersion { return }
        guard let message = WhatsNew.notes(for: currentVersion) else { return }
        UserDefaults.standard.set(currentVersion, forKey: "lastAppVersionShown")
        whatsNewVersion = currentVersion
        whatsNewMessage = message
    }

    private func combinedChangesMessage() -> String {
        var message = changesMsg1
        if !changesMsg2.isEmpty {
            message.append("\n\n")
            message.append(changesMsg2)
        }
        if !changesMsg3.isEmpty {
            message.append("\n\n")
            message.append(changesMsg3)
        }
        return message
    }

    private func homeBackgroundImage(landscape: Bool, regularWidth: Bool) -> UIImage {
        _ = revision
        let defaultName: String
        if landscape {
            defaultName = "PCCL"
        } else if regularWidth {
            defaultName = "PCCW"
        } else {
            defaultName = "PCC"
        }
        let fallback = UIImage(named: defaultName) ?? UIImage()
        if homeDefaultPicture {
            return fallback
        }
        if homeVisitPicture {
            if let data = homeVisitPictureData, let image = UIImage(data: data) {
                return image
            }
            return fallback
        }
        if let data = homeAlternatePicture, let image = UIImage(data: data) {
            return image
        }
        return fallback
    }

    private var cropToFill: Bool {
        _ = revision
        return homeImageCropToFill
    }

    private var homeTint: Color {
        _ = revision
        return Color(uiColor: UIColor.home())
    }

    private var homeTextIsLight: Bool {
        _ = revision
        return homeTextColor == 0
    }

    private var profilesAreOn: Bool {
        _ = revision
        return profilesEnabled
    }

    private var goalTitleText: String {
        _ = revision
        if profilesEnabled {
            return "\(ProfileManager.shared.activeProfileName())'s \(currentYear) Goals"
        }
        return "\(currentYear) Goal Progress"
    }

    private var goalBodyText: String {
        _ = revision
        return goalProgress.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var visitDateCaption: String? {
        _ = revision
        guard !homeDefaultPicture, homeVisitPicture, homeVisitPictureData != nil else { return nil }
        return homeVisitDate
    }

    private var hasCompletedAchievement: Bool {
        _ = revision
        return !completed.isEmpty
    }

    private var latestAchievementImage: UIImage {
        _ = revision
        let name = completed.first?.iconName ?? "ach12MT"
        return UIImage(named: name) ?? UIImage(named: "ach12MT") ?? UIImage()
    }

    private var activeProfileName: String {
        _ = revision
        return ProfileManager.shared.activeProfileName()
    }

    private var activeProfileIcon: String {
        _ = revision
        return ProfileManager.shared.activeProfileIconName()
    }

    private var profileChoices: [HomeProfileChoice] {
        _ = revision
        return ProfileManager.shared.allProfiles().enumerated().map { index, profile in
            let storedId = profile.value(forKey: "profileId") as? String ?? ""
            return HomeProfileChoice(
                id: storedId.isEmpty ? "profile-\(index)" : storedId,
                name: profile.value(forKey: "name") as? String ?? "",
                icon: profile.value(forKey: "iconName") as? String ?? "person.fill"
            )
        }
    }
}

private struct HomeProfileChoice: Identifiable {
    let id: String
    let name: String
    let icon: String
}

private struct HomeLabelStyle: ViewModifier {
    var color: Color
    var lightText: Bool
    var scrim: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
            .background {
                if scrim {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.05))
                        .padding(.horizontal, -8)
                        .padding(.vertical, -4)
                }
            }
            .shadow(color: .gray, radius: 5)
            .shadow(color: lightText ? Color.black.opacity(0.7) : Color.white.opacity(0.7), radius: 1, x: 1, y: 1)
    }
}

private struct WhatsNewPopup: View {
    let version: String
    let message: String
    var onDismiss: () -> Void

    @State private var visible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's New in Version \(version)")
                    .font(.custom("Baskerville-Bold", size: 20))
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(message)
                    .font(.custom("Baskerville", size: 16))
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("OK", action: dismiss)
                    .font(.custom("Baskerville", size: 18))
                    .foregroundStyle(Color("BaptismsBlue"))
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BaptismsBlue"), lineWidth: 1)
        )
        .scaleEffect(visible ? 1 : 0.8)
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                visible = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            visible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

private struct HomeAppearObserver: UIViewControllerRepresentable {
    var onWillAppear: () -> Void
    var onWillDisappear: () -> Void

    func makeUIViewController(context: Context) -> HomeAppearController {
        let controller = HomeAppearController()
        controller.onWillAppear = onWillAppear
        controller.onWillDisappear = onWillDisappear
        return controller
    }

    func updateUIViewController(_ controller: HomeAppearController, context: Context) {
        controller.onWillAppear = onWillAppear
        controller.onWillDisappear = onWillDisappear
    }
}

private final class HomeAppearController: UIViewController {
    var onWillAppear: (() -> Void)?
    var onWillDisappear: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        DispatchQueue.main.async { [weak self] in
            self?.onWillAppear?()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onWillDisappear?()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        homeTextColor == 0 ? .lightContent : .default
    }
}

private struct SettingsContainer: View {
    @ObservedObject var model: SettingsModel
    @State private var showProfiles = false

    var body: some View {
        SettingsView(model: model, onManageProfiles: { showProfiles = true })
            .sheet(isPresented: $showProfiles) {
                ProfilesScreen(onDismiss: { showProfiles = false })
            }
    }
}

private struct SettingsScreenHost: UIViewControllerRepresentable {
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let model = SettingsModel()
        context.coordinator.model = model
        let host = UIHostingController(rootView: SettingsContainer(model: model))
        host.navigationItem.title = "Settings"
        host.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        let navigation = UINavigationController(rootViewController: host)
        navigation.navigationBar.prefersLargeTitles = false
        context.coordinator.navigationController = navigation
        return navigation
    }

    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        context.coordinator.onDismiss = { isPresented = false }
    }

    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
        uiViewController.view.endEditing(true)
        coordinator.commit()
    }

    final class Coordinator: NSObject {
        var model: SettingsModel?
        var onDismiss: () -> Void = {}
        weak var navigationController: UINavigationController?
        private var didCommit = false

        @objc func doneTapped() {
            navigationController?.topViewController?.view.endEditing(true)
            commit()
            onDismiss()
        }

        func commit() {
            guard !didCommit, let model else { return }
            didCommit = true
            model.commit()
            ad.needsVisitRefresh = true
            if profilesEnabled {
                ProfileManager.shared.saveGoalsToActiveProfile()
            }
            NotificationCenter.default.post(name: .homeAppearanceDidChange, object: nil)
        }
    }
}
