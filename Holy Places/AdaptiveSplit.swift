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
            guard UIDevice.current.userInterfaceIdiom == .pad,
                  let split = enclosingSplitViewController,
                  let primary = split.viewController(for: .primary) else { return }
            let column: UIView = (primary.navigationController ?? primary).view
            // The sidebar list is inserted above the navigation bar and covers the
            // title between the header buttons. Keep the bar on top of that list.
            if let bar = column.subviews.first(where: { $0 is UINavigationBar }) as? UINavigationBar {
                if column.subviews.last(where: { $0.accessibilityIdentifier != Self.identifier }) !== bar {
                    column.bringSubviewToFront(bar)
                }
            }
            guard #available(iOS 26.0, *) else { return }
            let line = column.subviews.first { $0.accessibilityIdentifier == Self.identifier } ?? addLine(to: column)
            let top = headerTop(in: column)
            line.frame = CGRect(x: column.bounds.width - 1, y: top, width: 1, height: max(0, column.bounds.height - top))
            line.isHidden = split.isCollapsed
            column.bringSubviewToFront(line)
        }

        /// Top of the title row, below the screen edge and above the search bar.
        private func headerTop(in column: UIView) -> CGFloat {
            guard let bar = column.subviews.compactMap({ $0 as? UINavigationBar }).first else {
                return column.safeAreaInsets.top
            }
            let barFrame = bar.convert(bar.bounds, to: column)
            return max(0, barFrame.minY + bar.safeAreaInsets.top)
        }

        private func addLine(to column: UIView) -> UIView {
            let line = UIView()
            line.accessibilityIdentifier = Self.identifier
            line.backgroundColor = .opaqueSeparator
            line.isUserInteractionEnabled = false
            line.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
            line.layer.zPosition = 4
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

/// Draws the Places and Visits title in the center of the iPad list header.
///
/// The sidebar navigation bar leads-aligns its title, which puts it under the
/// Location button. This view is positioned from the bar's own bounds instead.
struct CenteredColumnTitle: UIViewRepresentable {
    var title: String
    var subtitle: String
    var titleColor: UIColor

    func makeUIView(context: Context) -> Anchor {
        Anchor()
    }

    func updateUIView(_ uiView: Anchor, context: Context) {
        uiView.title = title
        uiView.subtitle = subtitle
        uiView.titleColor = titleColor
        uiView.sync()
    }

    final class Anchor: UIView {
        var title = ""
        var subtitle = ""
        var titleColor: UIColor = .label

        private let panel = Panel()
        private var positioning = false
        private var pending = false
        private weak var watchedHost: UIView?
        private weak var watchedBar: UINavigationBar?
        private var hostObservation: NSKeyValueObservation?
        private var barObservation: NSKeyValueObservation?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil {
                hostObservation = nil
                barObservation = nil
                watchedHost = nil
                watchedBar = nil
                panel.removeFromSuperview()
            } else {
                sync()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            sync()
        }

        func sync() {
            apply()
            guard !pending else { return }
            pending = true
            DispatchQueue.main.async { [weak self] in
                self?.pending = false
                self?.panel.setNeedsLayout()
            }
        }

        private func apply() {
            guard !positioning, UIDevice.current.userInterfaceIdiom == .pad else { return }
            guard let bar = nearestNavigationBar, bar.bounds.width > 1 else { return }
            positioning = true
            defer { positioning = false }
            let host = bar.superview ?? bar
            if panel.superview !== host {
                host.addSubview(panel)
            }
            watch(host, bar: bar)
            panel.bar = bar
            panel.title = title
            panel.subtitle = subtitle
            panel.titleColor = titleColor
            panel.frame = host.bounds
            panel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hideSystemTitle(on: bar)
            hideDuplicateTitles(in: bar)
            panel.layer.zPosition = 2
            panel.setNeedsLayout()
        }

        /// The column width changes again after rotation, once the sidebar settles.
        private func watch(_ host: UIView, bar: UINavigationBar) {
            if watchedHost !== host {
                watchedHost = host
                hostObservation = host.layer.observe(\.bounds, options: [.new]) { [weak self, weak host] _, _ in
                    self?.followResize(of: host)
                }
            }
            if watchedBar !== bar {
                watchedBar = bar
                barObservation = bar.layer.observe(\.bounds, options: [.new]) { [weak self, weak host] _, _ in
                    self?.followResize(of: host)
                }
            }
        }

        private func followResize(of host: UIView?) {
            DispatchQueue.main.async { [weak self, weak host] in
                guard let self, let host, host.window != nil else { return }
                self.panel.frame = host.bounds
                self.panel.layoutIfNeeded()
            }
        }

        private var nearestNavigationBar: UINavigationBar? {
            var responder: UIResponder? = self
            while let next = responder?.next {
                if let navigation = next as? UINavigationController {
                    return navigation.navigationBar
                }
                responder = next
            }
            return nil
        }

        private func hideSystemTitle(on bar: UINavigationBar) {
            if let titleView = bar.topItem?.titleView {
                titleView.alpha = 0
                titleView.isHidden = true
            }
            let appearance = bar.standardAppearance.copy()
            var attributes = appearance.titleTextAttributes
            let current = attributes[.foregroundColor] as? UIColor
            var alpha: CGFloat = 1
            current?.getWhite(nil, alpha: &alpha)
            guard alpha > 0.01 else { return }
            attributes[.foregroundColor] = UIColor.clear
            appearance.titleTextAttributes = attributes
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.compactScrollEdgeAppearance = appearance
        }

        private func hideDuplicateTitles(in bar: UINavigationBar) {
            let root = bar.superview ?? bar
            func walk(_ view: UIView) {
                if view === panel || view.isDescendant(of: panel) { return }
                if let label = view as? UILabel, let text = label.text, !text.isEmpty {
                    let matchesCustomTitle = text == title || text == subtitle || title.hasPrefix(text)
                    let frame = label.convert(label.bounds, to: bar)
                    if matchesCustomTitle, frame.midY < 90, label.font?.fontName.contains("Baskerville") != true {
                        label.alpha = 0
                        label.isHidden = true
                    }
                }
                view.subviews.forEach(walk)
            }
            walk(root)
        }

    }

    /// Fills the column and recenters its labels whenever that column changes size,
    /// including the extra width change after a rotation.
    final class Panel: UIView {
        var title = "" {
            didSet { titleLabel.text = title; updateAccessibility() }
        }
        var subtitle = "" {
            didSet { subtitleLabel.text = subtitle; updateAccessibility() }
        }
        var titleColor: UIColor = .label {
            didSet { titleLabel.textColor = titleColor }
        }
        weak var bar: UINavigationBar?

        private let titleLabel = UILabel()
        private let subtitleLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
            accessibilityIdentifier = "HolyPlaces.centeredColumnTitle"
            titleLabel.font = UIFont(name: "Baskerville", size: 19)
            titleLabel.textAlignment = .center
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.7
            titleLabel.lineBreakMode = .byTruncatingTail
            subtitleLabel.font = UIFont(name: "Baskerville", size: 15)
            subtitleLabel.textColor = .gray
            subtitleLabel.textAlignment = .center
            subtitleLabel.adjustsFontSizeToFitWidth = true
            subtitleLabel.minimumScaleFactor = 0.7
            subtitleLabel.lineBreakMode = .byTruncatingTail
            addSubview(titleLabel)
            addSubview(subtitleLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard let bar, bar.window != nil, bar.bounds.width > 1, bounds.width > 1 else { return }
            let barFrame = bar.convert(bar.bounds, to: self)
            let mid = barFrame.midX
            let frames = buttonFrames(in: bar)
            let margin: CGFloat = 8
            var leftLimit = barFrame.minX + margin
            var rightLimit = barFrame.maxX - margin
            var midY = barFrame.minY + min(28, bar.bounds.midY)
            if let top = frames.map(\.midY).min() {
                let row = frames.filter { abs($0.midY - top) < 28 }
                if !row.isEmpty {
                    midY = row.map(\.midY).reduce(0, +) / CGFloat(row.count)
                }
                for frame in row {
                    if frame.midX < mid, frame.maxX < mid, frame.width <= 140 {
                        leftLimit = max(leftLimit, frame.maxX + 10)
                    } else if frame.midX > mid, frame.minX > mid, frame.width <= 220 {
                        rightLimit = min(rightLimit, frame.minX - 10)
                    }
                }
            }
            let half = min(mid - leftLimit, rightLimit - mid)
            guard half > 20 else { return }
            let natural = ceil(max(
                titleLabel.sizeThatFits(CGSize(width: 1200, height: 20)).width,
                subtitleLabel.sizeThatFits(CGSize(width: 1200, height: 18)).width
            ))
            let width = min(half * 2, max(44, natural))
            let x = mid - width / 2
            titleLabel.frame = CGRect(x: x, y: midY - 18, width: width, height: 20)
            subtitleLabel.frame = CGRect(x: x, y: midY - 1, width: width, height: 18)
        }

        private func updateAccessibility() {
            accessibilityLabel = [title, subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
        }

        private func buttonFrames(in bar: UINavigationBar) -> [CGRect] {
            let root = bar.superview ?? bar
            var frames: [CGRect] = []
            func walk(_ view: UIView) {
                if view === self || view.isDescendant(of: self) || view is UITextField { return }
                let frame = view.convert(view.bounds, to: self)
                let headerButton = view is UIButton
                    && frame.width >= 24
                    && frame.width <= 220
                    && frame.height >= 18
                    && frame.height <= 48
                    && frame.midY >= 0
                    && frame.midY < 80
                    && view.alpha > 0.01
                    && !view.isHidden
                if headerButton {
                    frames.append(frame)
                }
                view.subviews.forEach(walk)
            }
            walk(root)
            return frames
        }
    }
}
