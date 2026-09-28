//
//  AchievementsScreen.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

struct AchievementsScreen: View {
    var onDismiss: () -> Void

    @State private var showCompleted = true
    @State private var rows: [Achievement] = completed
    @State private var hasAnyCompleted = !completed.isEmpty
    @State private var showCelebrationBoard = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showCelebrationBoard = true
                    } label: {
                        Label("View \(CelebrationBoardConfig.displayName)", systemImage: "globe")
                            .font(.custom("Baskerville", size: 17))
                            .foregroundStyle(Color("BaptismsBlue"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if rows.isEmpty && !hasAnyCompleted {
                    Text("No Achievements Yet 😕")
                        .font(.custom("Baskerville", size: 18))
                        .foregroundStyle(Color("BaptismsBlue"))
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done", action: onDismiss)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Display", selection: $showCompleted) {
                        Text("🏆").tag(true)
                        Text("〜").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 108)
                    .accessibilityLabel("Completed or in progress")
                }
            }
        }
        .onAppear { reload() }
        .onChange(of: showCompleted) { _, _ in
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: ProfileManager.profileDidChangeNotification)) { _ in
            reload()
        }
        .sheet(isPresented: $showCelebrationBoard) {
            SafariView(url: CelebrationBoardConfig.pageURL)
                .ignoresSafeArea()
        }
    }

    private func reload() {
        rows = showCompleted ? completed : notCompleted
        hasAnyCompleted = !completed.isEmpty
    }
}

private struct AchievementRow: View {
    let achievement: Achievement

    @State private var shareToken = 0

    var body: some View {
        let imageSide: CGFloat = achievement.placeAchieved == nil ? 55 : 90
        let titleColor = achievementColor(for: achievement.iconName)
        HStack(alignment: .center, spacing: 12) {
            Image(uiImage: UIImage(named: achievement.iconName) ?? UIImage(named: "ach12MT") ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: imageSide, height: imageSide)
                .shadow(color: .white.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.custom("Baskerville", size: 20))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(detailText)
                    .font(.custom("Baskerville", size: 16))
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                if let place = achievement.placeAchieved {
                    Text("at \(place)")
                        .font(.custom("Baskerville", size: 17))
                        .foregroundStyle(placeColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    ProgressView(value: Double(achievement.progress ?? 0))
                        .tint(titleColor)
                        .opacity(0.8)
                        .frame(height: 5)
                }
                if let date = achievement.achieved {
                    Text("on \(Self.dateText(date))")
                        .font(.custom("Baskerville", size: 17))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if achievement.achieved != nil {
                Button {
                    shareToken += 1
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Share achievement")
                .background {
                    AchievementSharePresenter(token: shareToken, achievement: achievement)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(minHeight: achievement.placeAchieved == nil ? 65 : 100)
    }

    private var detailText: String {
        if achievement.placeAchieved != nil {
            return achievement.details
        }
        return "\(achievement.details) ~ \(achievement.remaining ?? 0) more"
    }

    private var placeColor: Color {
        achievement.iconName.last == "H" ? Color(uiColor: historicalColor) : Color(uiColor: templeColor)
    }

    private func achievementColor(for iconName: String) -> Color {
        switch iconName.last {
        case "B":
            return Color(uiColor: baptismsColor)
        case "I":
            return Color(uiColor: initiatoriesColor)
        case "E":
            return Color(uiColor: endowmentsColor)
        case "S":
            return Color(uiColor: sealingsColor)
        case "W":
            return Color(uiColor: hoursWorkedColor)
        case "H":
            return Color(uiColor: historicalColor)
        default:
            return Color(uiColor: templeColor)
        }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }
}

private struct AchievementSharePresenter: UIViewControllerRepresentable {
    var token: Int
    var achievement: Achievement

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard token > 0, context.coordinator.token != token else { return }
        context.coordinator.token = token
        DispatchQueue.main.async {
            guard controller.view.window != nil else { return }
            controller.handleAchievementShareAction(for: achievement, sourceView: controller.view)
        }
    }

    final class Coordinator {
        var token = 0
    }
}
