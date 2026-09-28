//
//  AdaptiveSplit.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

/// Two-pane container for Places, Visits, and Map.
///
/// iOS 27.1's `ArrangementView` is the hinge-aware split, but it is not in the
/// iOS 27.0 SDK this project builds with, so a reference would not compile.
/// `NavigationSplitView` is the system split on iOS 17.6 through 27.0 and is
/// what this container uses. When a future SDK exposes `ArrangementView`, the
/// `iOS 27.1` branch below is the place to host it inside one `NavigationStack`
/// without nesting another navigation container.
struct AdaptiveSplit<Primary: View, Secondary: View>: View {
    var widenSidebar = false
    @ViewBuilder var primary: () -> Primary
    @ViewBuilder var detail: () -> Secondary

    var body: some View {
        if #available(iOS 27.1, *) {
            hingeSplit
        } else {
            classicSplit
        }
    }

    private var classicSplit: some View {
        NavigationSplitView {
            primary()
                .background {
                    if widenSidebar {
                        SidebarWidthEnforcer()
                    }
                }
        } detail: {
            detail()
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var hingeSplit: some View {
        classicSplit
    }
}

/// Makes the sidebar 50% wider than the width NavigationSplitView chose on its own.
private struct SidebarWidthEnforcer: UIViewRepresentable {
    func makeUIView(context: Context) -> Enforcer {
        Enforcer()
    }

    func updateUIView(_ uiView: Enforcer, context: Context) {
        uiView.apply()
    }

    final class Enforcer: UIView {
        private static var targets: [ObjectIdentifier: CGFloat] = [:]

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            apply()
        }

        func apply() {
            guard let split = nearestSplit() else { return }
            let key = ObjectIdentifier(split)
            if Self.targets[key] == nil {
                let current = split.primaryColumnWidth
                let total = split.view.bounds.width
                guard current > 50, total > 0, current < total * 0.7 else { return }
                Self.targets[key] = min(current * 1.5, total * 0.65)
            }
            guard let target = Self.targets[key] else { return }
            guard abs(split.preferredPrimaryColumnWidth - target) > 1
                    || abs(split.maximumPrimaryColumnWidth - target) > 1 else { return }
            split.minimumPrimaryColumnWidth = target
            split.maximumPrimaryColumnWidth = target
            split.preferredPrimaryColumnWidth = target
        }

        private func nearestSplit() -> UISplitViewController? {
            var responder: UIResponder? = self
            while let next = responder?.next {
                if let split = next as? UISplitViewController { return split }
                if let controller = next as? UIViewController, let split = controller.splitViewController {
                    return split
                }
                responder = next
            }
            return nil
        }
    }
}
