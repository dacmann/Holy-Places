//
//  SettingsTVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 12/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

class SettingsTableVC: UIHostingController<SettingsView> {

    private let model: SettingsModel

    required init?(coder: NSCoder) {
        let model = SettingsModel()
        self.model = model
        super.init(coder: coder, rootView: SettingsView(model: model, onManageProfiles: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
        rootView = SettingsView(
            model: model,
            onManageProfiles: { [weak self] in
                self?.presentProfiles()
            }
        )
    }

    @IBAction func doneButton(_ sender: Any) {
        saveAndDismiss()
    }

    private func saveAndDismiss() {
        view.endEditing(true)
        model.commit()
        ad.needsVisitRefresh = true
        if profilesEnabled {
            ProfileManager.shared.saveGoalsToActiveProfile()
        }
        NotificationCenter.default.post(name: .homeAppearanceDidChange, object: nil)
        dismiss(animated: true)
    }

    private func presentProfiles() {
        let profileVC = ProfileManagementVC()
        let nav = UINavigationController(rootViewController: profileVC)
        present(nav, animated: true)
    }
}
