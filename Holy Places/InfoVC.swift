//
//  InfoVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/26/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import SwiftUI

class InfoVC: UIHostingController<InfoView> {

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: InfoView(onDismiss: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView = InfoView(onDismiss: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}
