//
//  ShareVC.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI

class ShareVC: UIHostingController<ShareView> {

    private weak var popoverSourceView: UIView?

    init(sourceView: UIView) {
        self.popoverSourceView = sourceView
        super.init(rootView: ShareView(onDismiss: {}, popoverSource: sourceView))
        modalPresentationStyle = .pageSheet
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView = ShareView(onDismiss: { [weak self] in
            self?.dismiss(animated: true)
        }, popoverSource: popoverSourceView)
    }
}
