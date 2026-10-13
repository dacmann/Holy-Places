//
//  SummaryVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/23/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit
import CoreData
import StoreKit

class SummaryVC: UIHostingController<SummaryView> {

    private let model: SummaryModel

    init() {
        let model = SummaryModel()
        self.model = model
        super.init(rootView: SummaryView(model: model, onAchievements: {}))
    }

    required init?(coder: NSCoder) {
        let model = SummaryModel()
        self.model = model
        super.init(coder: coder, rootView: SummaryView(model: model, onAchievements: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaceCatalogUpdate),
            name: .placeCatalogDidUpdate,
            object: nil
        )
        rootView = SummaryView(
            model: model,
            onAchievements: { [weak self] in
                self?.presentAchievements()
            }
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ad.applyParsedPlaceUpdate()
        presentDataUpdateIfNeeded()

        let defaults = UserDefaults.standard
        let hasRequestedReview = defaults.bool(forKey: "hasRequestedReview")
        if !hasRequestedReview {
            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            do {
                let visitCount = try ad.persistentContainer.viewContext.count(for: fetchRequest)
                if visitCount > 5 {
                    if let scene = view.window?.windowScene {
                        SKStoreReviewController.requestReview(in: scene)
                        defaults.set(true, forKey: "hasRequestedReview")
                    }
                }
            } catch {
                print("Error counting visits: \(error)")
            }
        }
    }

    @objc private func handlePlaceCatalogUpdate() {
        presentDataUpdateIfNeeded()
    }

    private func presentDataUpdateIfNeeded() {
        guard AppRouter.shared.isSelected(.summary) else { return }
        guard changesDate != "", presentedViewController == nil else { return }
        var changesMsg = changesMsg1
        if changesMsg2 != "" {
            changesMsg.append("\n\n")
            changesMsg.append(changesMsg2)
        }
        if changesMsg3 != "" {
            changesMsg.append("\n\n")
            changesMsg.append(changesMsg3)
        }
        let title = changesDate + " Update"
        changesDate = ""
        let alert = UIAlertController(title: title, message: changesMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func presentAchievements() {
        let host = UIHostingController(rootView: AchievementsScreen { [weak self] in
            self?.dismiss(animated: true)
        })
        host.modalPresentationStyle = .pageSheet
        present(host, animated: true)
    }
}
