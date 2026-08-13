//
//  Achievement.swift
//  Holy Places
//
//  Created by Derek Cordon on 10/11/18.
//  Copyright © 2018 Derek Cordon. All rights reserved.
//

import Foundation
import UIKit

class Achievement: NSObject {
    var name = String()
    var details = String()
    var iconName = String()
    var achieved: Date?
    var placeAchieved: String?
    var progress: Float?
    var remaining: Int?
    
    init(Name:String, Details:String, IconName:String) {
        self.name = Name
        self.details = Details
        self.iconName = IconName
    }
    
    init(Name:String, Details:String, IconName:String, Achieved:Date?, PlaceAchieved:String?) {
        self.name = Name
        self.details = Details
        self.iconName = IconName
        self.achieved = Achieved
        self.placeAchieved = PlaceAchieved
    }
}

class AchievementCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellDetails: UILabel!
    @IBOutlet weak var cellPlaceAchieved: UILabel!
    @IBOutlet weak var cellDateAchieved: UILabel!
    @IBOutlet weak var cellProgress: UIProgressView!

    private(set) lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Share achievement"
        return button
    }()

    private var didInstallShareButton = false

    func configureShareButton(show: Bool) {
        if !didInstallShareButton {
            contentView.addSubview(shareButton)
            NSLayoutConstraint.activate([
                shareButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                shareButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                shareButton.widthAnchor.constraint(equalToConstant: 36),
                shareButton.heightAnchor.constraint(equalToConstant: 36)
            ])
            didInstallShareButton = true
        }
        shareButton.isHidden = !show
        shareButton.isEnabled = show
    }
}
