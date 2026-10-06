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
                    SidebarSeparator()
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

private extension UIView {
    var enclosingSplitViewController: UISplitViewController? {
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

/// iPadOS 26 draws the sidebar as a card with no divider, so the list and the
/// detail beside it read as one surface. This draws a line on the card's trailing edge.
private struct SidebarSeparator: UIViewRepresentable {
    func makeUIView(context: Context) -> Installer {
        Installer()
    }

    func updateUIView(_ uiView: Installer, context: Context) {
        uiView.setNeedsLayout()
    }

    final class Installer: UIView {
        private static let identifier = "HolyPlaces.sidebarSeparator"

        override func didMoveToWindow() {
            super.didMoveToWindow()
            place()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            place()
        }

        private func place() {
            guard #available(iOS 26.0, *),
                  UIDevice.current.userInterfaceIdiom == .pad,
                  let split = enclosingSplitViewController,
                  let primary = split.viewController(for: .primary) else { return }
            let column: UIView = (primary.navigationController ?? primary).view
            let line = column.subviews.first { $0.accessibilityIdentifier == Self.identifier } ?? addLine(to: column)
            line.frame = CGRect(x: column.bounds.width - 1, y: 0, width: 1, height: column.bounds.height)
            line.isHidden = split.isCollapsed
        }

        private func addLine(to column: UIView) -> UIView {
            let line = UIView()
            line.accessibilityIdentifier = Self.identifier
            line.backgroundColor = .opaqueSeparator
            line.isUserInteractionEnabled = false
            line.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
            line.layer.zPosition = 1
            column.addSubview(line)
            return line
        }
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
        private var appliedTotal: CGFloat = 0
        private var lastTarget: CGFloat = 0
        private var remeasuring = false
        private var remeasureAttempts = 0

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            apply()
        }

        func apply() {
            guard let split = enclosingSplitViewController else { return }
            let total = split.view.bounds.width
            guard total > 0 else { return }
            if abs(total - appliedTotal) > 1 {
                guard !remeasuring else { return }
                remeasuring = true
                remeasureAttempts = 0
                releaseColumnWidth(split)
                DispatchQueue.main.async { [weak self] in
                    self?.finishRemeasure()
                }
                return
            }
            guard lastTarget > 0 else { return }
            guard abs(split.preferredPrimaryColumnWidth - lastTarget) > 1
                    || abs(split.maximumPrimaryColumnWidth - lastTarget) > 1 else { return }
            lockColumn(split, to: lastTarget)
        }

        private func finishRemeasure() {
            guard let split = enclosingSplitViewController else {
                remeasuring = false
                return
            }
            let total = split.view.bounds.width
            guard total > 0 else {
                remeasuring = false
                return
            }
            split.view.layoutIfNeeded()
            let system = split.primaryColumnWidth
            if lastTarget > 0, abs(system - lastTarget) < 1 {
                remeasureAttempts += 1
                if remeasureAttempts < 3 {
                    releaseColumnWidth(split)
                    split.view.setNeedsLayout()
                    DispatchQueue.main.async { [weak self] in
                        self?.finishRemeasure()
                    }
                    return
                }
                remeasuring = false
                appliedTotal = total
                return
            }
            guard system > 50 else {
                remeasuring = false
                return
            }
            if system >= total * 0.7 {
                remeasuring = false
                appliedTotal = total
                return
            }
            let target = min(system * 1.5, total * 0.65)
            lockColumn(split, to: target)
            split.view.layoutIfNeeded()
            lastTarget = target
            appliedTotal = total
            remeasuring = false
            remeasureAttempts = 0
            stretchPrimary(split, width: target)
        }

        private func releaseColumnWidth(_ split: UISplitViewController) {
            let automatic = UISplitViewController.automaticDimension
            split.minimumPrimaryColumnWidth = automatic
            split.maximumPrimaryColumnWidth = automatic
            split.preferredPrimaryColumnWidth = automatic
        }

        private func lockColumn(_ split: UISplitViewController, to target: CGFloat) {
            split.minimumPrimaryColumnWidth = target
            split.maximumPrimaryColumnWidth = target
            split.preferredPrimaryColumnWidth = target
        }

        private func stretchPrimary(_ split: UISplitViewController, width: CGFloat) {
            guard let primary = split.viewController(for: .primary), width > 1 else { return }
            var frame = primary.view.frame
            if abs(frame.size.width - width) > 1 {
                frame.size.width = width
                primary.view.frame = frame
            }
            primary.view.setNeedsLayout()
            primary.view.layoutIfNeeded()
        }
    }
}
