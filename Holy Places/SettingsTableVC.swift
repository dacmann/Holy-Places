//
//  SettingsTVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 12/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

class SettingsTableVC: UIHostingController<SettingsView>, UIAdaptivePresentationControllerDelegate {

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.presentationController?.delegate = self
    }

    @IBAction func doneButton(_ sender: Any) {
        saveAndDismiss()
    }

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        view.endEditing(true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        commitGoalsAndNotifyHome()
    }

    private func saveAndDismiss() {
        view.endEditing(true)
        commitGoalsAndNotifyHome()
        dismiss(animated: true)
    }

    private func commitGoalsAndNotifyHome() {
        model.commit()
        ad.needsVisitRefresh = true
        if profilesEnabled {
            ProfileManager.shared.saveGoalsToActiveProfile()
        }
        NotificationCenter.default.post(name: .homeAppearanceDidChange, object: nil)
    }

    private func presentProfiles() {
        let host = UIHostingController(rootView: ProfilesScreen { [weak self] in
            self?.dismiss(animated: true)
        })
        let nav = UINavigationController(rootViewController: host)
        present(nav, animated: true)
    }
}
