//
//  ShareActivityView.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var popoverSource: UIView?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        if let popoverSource {
            controller.popoverPresentationController?.sourceView = popoverSource
            controller.popoverPresentationController?.sourceRect = popoverSource.bounds
        }
        controller.completionWithItemsHandler = { _, _, _, _ in
            context.coordinator.onComplete?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var onComplete: (() -> Void)?
    }
}
