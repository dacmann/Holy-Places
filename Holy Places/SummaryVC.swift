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

    required init?(coder: NSCoder) {
        let model = SummaryModel()
        self.model = model
        super.init(coder: coder, rootView: SummaryView(model: model, onAchievements: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

        if ad.newFileParsed {
            ad.storePlaces()
            ad.savePlaceVersion()
            checkedForUpdate = Date()
            ad.newFileParsed = false
        }

        if changesDate != "" {
            var changesMsg = changesMsg1
            if changesMsg2 != "" {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg2)
            }
            if changesMsg3 != "" {
                changesMsg.append("\n\n")
                changesMsg.append(changesMsg3)
            }
            let alert = UIAlertController(title: changesDate + " Update", message: changesMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                changesDate = ""
            }))
            present(alert, animated: true)
        }

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

    private func presentAchievements() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "AchievementsNav")
        present(controller, animated: true)
    }
}
