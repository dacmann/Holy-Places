//
//  AchievementUnlockedView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

struct AchievementUnlockedView: View {
    let achievements: [Achievement]
    var onDismiss: () -> Void
    var onShare: (Achievement) -> Void

    @State private var currentIndex = 0
    @State private var showIdentitySheet = false
    @State private var identityName = ""
    @State private var identityLocation = ""
    @State private var isPosting = false
    @State private var statusMessage: String?
    @State private var statusIsError = false

    private var achievement: Achievement {
        achievements[min(currentIndex, achievements.count - 1)]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Congratulations!")
                    .font(.custom("Baskerville-Bold", size: 28))
                    .padding(.top, 8)

                Image(uiImage: UIImage(named: achievement.iconName) ?? UIImage(named: "ach12MT") ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: .white.opacity(0.6), radius: 4)

                Text(achievement.name)
                    .font(.custom("Baskerville-Bold", size: 22))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(titleColor)

                Text(achievement.details)
                    .font(.custom("Baskerville", size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let place = achievement.placeAchieved {
                    Text("at \(place)")
                        .font(.custom("Baskerville", size: 16))
                }
                if let date = achievement.achieved {
                    Text("on \(formatted(date))")
                        .font(.custom("Baskerville", size: 16))
                        .foregroundStyle(.secondary)
                }

                if achievements.count > 1 {
                    Text("Achievement \(currentIndex + 1) of \(achievements.count)")
                        .font(.custom("Baskerville", size: 14))
                        .foregroundStyle(.secondary)
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.custom("Baskerville", size: 15))
                        .foregroundStyle(statusIsError ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button {
                        onShare(achievement)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if achievement.isCelebrationBoardEligible {
                        Button {
                            prepareIdentityAndShow()
                        } label: {
                            Label("Post to \(CelebrationBoardConfig.displayName)", systemImage: "globe")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isPosting)
                    }

                    if achievements.count > 1 && currentIndex < achievements.count - 1 {
                        Button("Next Achievement") {
                            statusMessage = nil
                            currentIndex += 1
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
            .sheet(isPresented: $showIdentitySheet) {
                CelebrationBoardIdentityView(
                    name: $identityName,
                    location: $identityLocation,
                    isPosting: $isPosting,
                    onCancel: { showIdentitySheet = false },
                    onConfirm: { postToBoard() }
                )
            }
        }
    }

    private var titleColor: Color {
        switch achievement.iconName.last {
        case "B": return Color("BaptismsBlue")
        case "I": return Color("InitiatoriesOlive")
        case "E": return .orange
        case "S": return Color("SealingsPurple")
        case "W": return .gray
        case "H": return Color(red: 0.45, green: 0, blue: 0)
        default: return Color(red: 0, green: 0, blue: 0.5)
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }

    private func prepareIdentityAndShow() {
        guard let profileId = ProfileManager.shared.effectiveProfileId() else {
            statusIsError = true
            statusMessage = "No active profile is available for posting."
            return
        }
        identityName = CelebrationBoardConfig.savedName(for: profileId) ?? ""
        identityLocation = CelebrationBoardConfig.savedLocation(for: profileId) ?? ""
        showIdentitySheet = true
    }

    private func postToBoard() {
        let name = identityName.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = identityLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !location.isEmpty else {
            statusIsError = true
            statusMessage = "Please enter your name and where you live."
            return
        }
        guard let profileId = ProfileManager.shared.effectiveProfileId(),
              let submission = CelebrationBoardClient.buildSubmission(
                achievement: achievement,
                userName: name,
                location: location
              ) else {
            statusIsError = true
            statusMessage = "Unable to prepare Celebration Board post."
            return
        }

        isPosting = true
        CelebrationBoardClient.post(submission) { result in
            isPosting = false
            switch result {
            case .success:
                CelebrationBoardConfig.saveIdentity(name: name, location: location, for: profileId)
                showIdentitySheet = false
                statusIsError = false
                statusMessage = "Posted to \(CelebrationBoardConfig.displayName)!"
            case .failure(let message):
                statusIsError = true
                statusMessage = message
            }
        }
    }
}

struct CelebrationBoardIdentityView: View {
    @Binding var name: String
    @Binding var location: String
    @Binding var isPosting: Bool
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                    TextField("Where you live", text: $location)
                        .textContentType(.addressCity)
                } footer: {
                    Text("This name and location will appear publicly on the \(CelebrationBoardConfig.displayName).")
                }
            }
            .navigationTitle(CelebrationBoardConfig.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPosting {
                        ProgressView()
                    } else {
                        Button("Post", action: onConfirm)
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      || location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

final class AchievementUnlockedVC: UIHostingController<AchievementUnlockedView> {
    private let onFinished: () -> Void

    init(achievements: [Achievement], onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        super.init(rootView: AchievementUnlockedView(achievements: achievements, onDismiss: {}, onShare: { _ in }))
        modalPresentationStyle = .pageSheet
        rootView = AchievementUnlockedView(
            achievements: achievements,
            onDismiss: { [weak self] in
                self?.dismiss(animated: true) {
                    onFinished()
                }
            },
            onShare: { [weak self] achievement in
                self?.shareAchievementImage(achievement, sourceView: self?.view)
            }
        )
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
