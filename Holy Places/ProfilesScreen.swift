//
//  ProfilesScreen.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import CoreData
import SwiftUI
import UIKit

struct ProfilesScreen: View {
    var onDismiss: () -> Void

    @State private var profiles: [NSManagedObject] = ProfileManager.shared.allProfiles()
    @State private var editor: ProfileDraft?
    @State private var pendingDelete: ProfileDeleteRequest?
    @State private var showLimitAlert = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles, id: \.objectID) { profile in
                    profileRow(profile)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openEditor(for: profile)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if (profile.value(forKey: "isDefault") as? Bool ?? false) == false {
                                Button("Delete", role: .destructive) {
                                    queueDelete(profile)
                                }
                            }
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Manage Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done", action: onDismiss)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addProfile) {
                        Image(systemName: "plus")
                    }
                    .disabled(profiles.count >= ProfileManager.profileMaxCount)
                    .accessibilityLabel("Add Profile")
                }
            }
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: ProfileManager.profileDidChangeNotification)) { _ in
            reload()
        }
        .sheet(item: $editor) { draft in
            ProfileEditorSheet(draft: draft) { name, iconName in
                if draft.isNew {
                    _ = ProfileManager.shared.createProfile(name: name, iconName: iconName)
                } else if let profile = draft.profile {
                    ProfileManager.shared.renameProfile(profile, to: name)
                    ProfileManager.shared.updateProfileIcon(profile, iconName: iconName)
                }
                reload()
            }
        }
        .alert(pendingDelete?.title ?? "Delete Profile?", isPresented: deleteAlertPresented) {
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let profile = pendingDelete?.profile {
                    ProfileManager.shared.deleteProfile(profile)
                    reload()
                }
                pendingDelete = nil
            }
        } message: {
            Text(pendingDelete?.message ?? "")
        }
        .alert("Limit Reached", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can have up to \(ProfileManager.profileMaxCount) profiles.")
        }
    }

    private var deleteAlertPresented: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private func profileRow(_ profile: NSManagedObject) -> some View {
        let name = profile.value(forKey: "name") as? String ?? ""
        let iconName = profile.value(forKey: "iconName") as? String ?? "person.fill"
        let isDefault = profile.value(forKey: "isDefault") as? Bool ?? false
        let profileId = profile.value(forKey: "profileId") as? String ?? ""
        let visitCount = ProfileManager.shared.visitCount(for: profile)
        let subtitle = "\(visitCount) visit\(visitCount == 1 ? "" : "s")\(isDefault ? " · Default" : "")"

        return HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 22))
                .foregroundStyle(Color("BaptismsBlue"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("Baskerville", size: 17))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.custom("Baskerville", size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if profileId == activeProfileId {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color("BaptismsBlue"))
            }
        }
        .padding(.vertical, 4)
    }

    private func reload() {
        profiles = ProfileManager.shared.allProfiles()
    }

    private func addProfile() {
        guard profiles.count < ProfileManager.profileMaxCount else {
            showLimitAlert = true
            return
        }
        editor = ProfileDraft(name: "", iconName: "star.fill", isNew: true, profile: nil)
    }

    private func openEditor(for profile: NSManagedObject) {
        editor = ProfileDraft(
            name: profile.value(forKey: "name") as? String ?? "",
            iconName: profile.value(forKey: "iconName") as? String ?? "person.fill",
            isNew: false,
            profile: profile
        )
    }

    private func queueDelete(_ profile: NSManagedObject) {
        let name = profile.value(forKey: "name") as? String ?? "this profile"
        let visitCount = ProfileManager.shared.visitCount(for: profile)
        pendingDelete = ProfileDeleteRequest(
            profile: profile,
            title: "Delete \(name)?",
            message: "This will permanently remove \(name) and all \(visitCount) of their visits. Consider exporting their visits first as a backup.\n\nThis cannot be undone."
        )
    }
}

private struct ProfileDraft: Identifiable {
    let id = UUID()
    var name: String
    var iconName: String
    var isNew: Bool
    var profile: NSManagedObject?
}

private struct ProfileDeleteRequest: Identifiable {
    let id = UUID()
    let profile: NSManagedObject
    let title: String
    let message: String
}

private struct ProfileEditorSheet: View {
    let draft: ProfileDraft
    var onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedIcon: String
    @State private var showNameAlert = false
    @FocusState private var nameFocused: Bool

    init(draft: ProfileDraft, onSave: @escaping (String, String) -> Void) {
        self.draft = draft
        self.onSave = onSave
        _name = State(initialValue: draft.name)
        _selectedIcon = State(initialValue: draft.iconName)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Name")
                    .font(.custom("Baskerville", size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                    .padding(.leading, 4)
                TextField("Profile Name", text: $name)
                    .font(.custom("Baskerville", size: 17))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
                    .padding(.top, 8)
                Text("Icon")
                    .font(.custom("Baskerville", size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.top, 24)
                    .padding(.leading, 4)
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 50, maximum: 50), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(ProfileManager.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 22))
                                    .frame(width: 28, height: 28)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selectedIcon == icon
                                            ? Color("BaptismsBlue").opacity(0.2)
                                            : Color.clear
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                Color("BaptismsBlue"),
                                                lineWidth: selectedIcon == icon ? 2 : 0
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color("BaptismsBlue"))
                            .accessibilityLabel(icon)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 200)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 8)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(draft.isNew ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear { nameFocused = true }
        }
        .alert("Name Required", isPresented: $showNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a name for this profile.")
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showNameAlert = true
            return
        }
        onSave(trimmed, selectedIcon)
        dismiss()
    }
}
