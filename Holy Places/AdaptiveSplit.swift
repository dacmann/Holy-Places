//
//  AdaptiveSplit.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

/// Whether Places and Visits should follow the iPhone Duo hinge.
///
/// iPad keeps `NavigationSplitView`. Its column width, divider, and first-visit
/// layout are built on that controller. iPhone and iPhone Duo on iOS 27.1 use
/// `ArrangementView`, which places the divider on the fold.
enum ListSplit {
    static var usesHingeArrangement: Bool {
        if #available(iOS 27.1, *) {
            return UIDevice.current.userInterfaceIdiom != .pad
        }
        return false
    }
}

/// Two-pane container for Places and Visits.
///
/// `showsBothColumns` is true only while the detail column is on screen.
/// A folded phone and a collapsed split leave it false, so a list selection
/// pushes the detail instead of opening it beside the list.
struct AdaptiveSplit<Primary: View, Secondary: View>: View {
    var widenSidebar = false
    @Binding var showsBothColumns: Bool
    @ViewBuilder var primary: () -> Primary
    @ViewBuilder var detail: () -> Secondary
    @State private var listWidth: CGFloat = 0
    @State private var arrangementWidth: CGFloat = 0
    @State private var reportedSideBySide: Bool?
    @State private var confirmToken = 0

    var body: some View {
        if ListSplit.usesHingeArrangement {
            hingeSplit
        } else {
            classicSplit
        }
    }

    private var classicSplit: some View {
        NavigationSplitView {
            primary()
                .modifier(SidebarColumnBackground())
                .background {
                    SplitColumnReporter(showsBothColumns: $showsBothColumns)
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
        if #available(iOS 27.1, *) {
            ArrangementView {
                NavigationStack {
                    primary()
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: ListColumnWidthKey.self, value: geo.size.width)
                            }
                        }
                }
            } secondary: {
                NavigationStack {
                    detail()
                }
            }
            .arrangementViewStyle(.split.axes(.horizontal))
            .background {
                GeometryReader { geo in
                    Color.clear.preference(key: ArrangementWidthKey.self, value: geo.size.width)
                }
            }
            .onPreferenceChange(ListColumnWidthKey.self) { listWidth = $0 }
            .onPreferenceChange(ArrangementWidthKey.self) { arrangementWidth = $0 }
            .onChange(of: listWidth) { _, _ in noteFold() }
            .onChange(of: arrangementWidth) { _, _ in noteFold() }
            .task(id: confirmToken) {
                guard confirmToken > 0, let sideBySide = reportedSideBySide else { return }
                // The first layout can look split for a moment. Wait before selecting
                // a row, so opening a folded tab does not launch the first place.
                if sideBySide {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    guard !Task.isCancelled else { return }
                }
                if showsBothColumns != sideBySide {
                    showsBothColumns = sideBySide
                }
            }
        }
    }

    /// Folded, the list fills the arrangement. Unfolded, the detail column takes the rest.
    private func noteFold() {
        guard listWidth > 1, arrangementWidth > 1 else { return }
        let sideBySide = arrangementWidth - listWidth > 80
        guard reportedSideBySide != sideBySide else { return }
        reportedSideBySide = sideBySide
        confirmToken += 1
    }
}

private struct ListColumnWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ArrangementWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    /// Pushes the detail when the arrangement is showing only the list.
    /// The push waits until the arrangement has reported, so opening the tab
    /// does not flash the detail over a split that is still settling.
    @ViewBuilder
    func hingeDetailNavigation<Destination: View>(
        showsBothColumns: Binding<Bool>,
        hasDetail: Bool,
        suppressPush: Binding<Bool>,
        onDismiss: @escaping () -> Bool,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        if #available(iOS 27.1, *), ListSplit.usesHingeArrangement {
            modifier(HingeDetailModifier(
                showsBothColumns: showsBothColumns,
                hasDetail: hasDetail,
                suppressPush: suppressPush,
                onDismiss: onDismiss,
                destination: destination
            ))
        } else {
            self
        }
    }
}

@available(iOS 27.1, *)
private struct HingeDetailModifier<Destination: View>: ViewModifier {
    @Binding var showsBothColumns: Bool
    var hasDetail: Bool
    @Binding var suppressPush: Bool
    var onDismiss: () -> Bool
    @ViewBuilder var destination: () -> Destination
    @State private var pushed = false

    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: $pushed) {
                destination()
            }
            .onChange(of: showsBothColumns) { _, sideBySide in
                if !sideBySide, hasDetail, !suppressPush {
                    pushed = true
                } else {
                    syncPush()
                }
            }
            .onChange(of: hasDetail) { wasDetail, isDetail in
                let suppressed = suppressPush
                suppressPush = false
                // A tap, Add, or Record opens over the folded list. The first-row
                // selection used beside an open fold does not.
                if isDetail, !wasDetail, !showsBothColumns, !suppressed {
                    pushed = true
                } else {
                    syncPush()
                }
            }
            .onChange(of: pushed) { _, isPushed in
                guard !isPushed, !showsBothColumns, hasDetail else { return }
                if !onDismiss() {
                    pushed = true
                }
            }
    }

    private func syncPush() {
        if showsBothColumns || !hasDetail {
            if pushed {
                pushed = false
            }
        }
    }
}

/// Publishes whether an arrangement is showing two columns. Summary uses this so
/// Most Visited stays on the right of an open fold and joins the single column when folded.
struct ArrangementSideBySideReader: View {
    @Binding var showsBothColumns: Bool

    var body: some View {
        if #available(iOS 27.1, *) {
            SplitColumnReporter(showsBothColumns: $showsBothColumns)
                .allowsHitTesting(false)
        }
    }
}

/// Reports whether the detail column is visible beside the list.
private struct SplitColumnReporter: UIViewRepresentable {
    @Binding var showsBothColumns: Bool
    var onReport: ((Bool) -> Void)? = nil

    func makeUIView(context: Context) -> Reporter {
        Reporter()
    }

    func updateUIView(_ uiView: Reporter, context: Context) {
        uiView.onChange = { visible in
            onReport?(visible)
            if showsBothColumns != visible {
                showsBothColumns = visible
            }
        }
        uiView.report()
    }

    final class Reporter: UIView {
        var onChange: (Bool) -> Void = { _ in }
        private var last: Bool?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        func report() {
            guard let visible = columnsAreSideBySide(), visible != last else { return }
            last = visible
            DispatchQueue.main.async { [weak self] in
                guard let self, self.columnsAreSideBySide() == visible else { return }
                self.onChange(visible)
            }
        }

        private func columnsAreSideBySide() -> Bool? {
            if #available(iOS 27.1, *), let arrangement = enclosingArrangementViewController {
                return arrangementIsSideBySide(arrangement)
            }
            if let split = enclosingSplitViewController {
                if split.isCollapsed { return false }
                let width = split.viewController(for: .secondary)?.view.bounds.width ?? 0
                return width > 1 ? true : nil
            }
            return nil
        }

        /// Side by side only when the detail column is actually on screen.
        /// A hidden column can still report a width, which kept folded taps from pushing.
        @available(iOS 27.1, *)
        private func arrangementIsSideBySide(_ arrangement: UIArrangementViewController) -> Bool? {
            let container = arrangement.view.bounds
            guard container.width > 1, container.height > 1 else { return nil }
            if let secondary = arrangement.state(for: .secondary),
               secondary.isHidden || !secondary.splitAxis.contains(.horizontal) {
                return false
            }
            guard let secondaryView = arrangement.viewController(for: .secondary)?.viewIfLoaded,
                  !secondaryView.isHidden else { return false }
            let frame = secondaryView.convert(secondaryView.bounds, to: arrangement.view)
            let visible = frame.intersection(container)
            return visible.width > 80 && visible.height > 80
        }
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

    @available(iOS 27.1, *)
    var enclosingArrangementViewController: UIArrangementViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let arrangement = next as? UIArrangementViewController { return arrangement }
            if let controller = next as? UIViewController, let arrangement = controller.arrangementViewController {
                return arrangement
            }
            responder = next
        }
        return nil
    }
}

/// Dark mode draws the iPad sidebar one step above the screen, which turns
/// `systemBackground` gray. The list itself stays the base screen color.
enum ListHeaderColor {
    static let matchingScreen = UIColor { traits in
        let base = traits.modifyingTraits { $0.userInterfaceLevel = .base }
        return UIColor.systemBackground.resolvedColor(with: base)
    }
}

/// The split column's own plate is the gray behind the Places and Visits header.
private struct SidebarColumnBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.containerBackground(Color(uiColor: ListHeaderColor.matchingScreen), for: .navigationSplitView)
        } else {
            content
        }
    }
}

/// Keeps the iPad list header on top of the list, drops the sidebar edge line,
/// and paints that header the same black (or white) as the rest of the screen.
private struct SidebarSeparator: UIViewRepresentable {
    func makeUIView(context: Context) -> Installer {
        Installer()
    }

    func updateUIView(_ uiView: Installer, context: Context) {
        uiView.setNeedsLayout()
        DispatchQueue.main.async { [weak uiView] in
            uiView?.place()
        }
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

        fileprivate func place() {
            guard UIDevice.current.userInterfaceIdiom == .pad,
                  let split = enclosingSplitViewController,
                  let primary = split.viewController(for: .primary) else { return }
            // `.none` drops the gray plate but draws the column divider again.
            // The sidebar style has no divider; the header color is painted separately.
            split.primaryBackgroundStyle = .sidebar
            let column: UIView = (primary.navigationController ?? primary).view
            column.subviews
                .filter { $0.accessibilityIdentifier == Self.identifier }
                .forEach { $0.removeFromSuperview() }
            hideColumnDivider(of: split, beside: column)
            guard let bar = column.subviews.compactMap({ $0 as? UINavigationBar }).first
                    ?? nearestNavigationBar else { return }
            bar.subviews
                .filter { $0.accessibilityIdentifier == Self.fillIdentifier }
                .forEach { $0.removeFromSuperview() }
            // The sidebar list is inserted above the navigation bar and covers the
            // title between the header buttons. Keep the bar on top of that list.
            if column.subviews.last !== bar, bar.superview === column {
                column.bringSubviewToFront(bar)
            }
            paintHeader(bar)
        }

        /// Recolors the bar behind the title, search field, and header buttons.
        /// The buttons and search field stay in the bar; only its fill changes.
        private func paintHeader(_ bar: UINavigationBar) {
            let appearance = bar.standardAppearance.copy()
            let titleAttributes = appearance.titleTextAttributes
            let largeTitleAttributes = appearance.largeTitleTextAttributes
            let buttonAppearance = appearance.buttonAppearance
            let backAppearance = appearance.backButtonAppearance
            let doneAppearance = appearance.doneButtonAppearance
            let prominentAppearance: UIBarButtonItemAppearance? = if #available(iOS 26.0, *) {
                appearance.prominentButtonAppearance
            } else {
                nil
            }
            let shadowColor = appearance.shadowColor
            let shadowImage = appearance.shadowImage
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = titleAttributes
            appearance.largeTitleTextAttributes = largeTitleAttributes
            appearance.buttonAppearance = buttonAppearance
            appearance.backButtonAppearance = backAppearance
            appearance.doneButtonAppearance = doneAppearance
            if #available(iOS 26.0, *), let prominentAppearance {
                appearance.prominentButtonAppearance = prominentAppearance
            }
            appearance.backgroundColor = ListHeaderColor.matchingScreen
            appearance.backgroundEffect = nil
            appearance.backgroundImage = nil
            appearance.shadowColor = shadowColor
            appearance.shadowImage = shadowImage
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.compactScrollEdgeAppearance = appearance
            for item in bar.items ?? [] {
                item.standardAppearance = appearance
                item.scrollEdgeAppearance = appearance
                item.compactAppearance = appearance
                item.compactScrollEdgeAppearance = appearance
            }
        }

        /// Hides the system divider on the trailing edge of the list column.
        private func hideColumnDivider(of split: UISplitViewController, beside column: UIView) {
            let edge = column.convert(CGPoint(x: column.bounds.maxX, y: column.bounds.midY), to: split.view)
            func walk(_ view: UIView) {
                let name = String(describing: type(of: view))
                let frame = view.convert(view.bounds, to: split.view)
                let verticalLine = frame.width > 0 && frame.width <= 2 && frame.height > 40
                let onEdge = abs(frame.midX - edge.x) < 4
                let isDivider = name.contains("Separator") || name.contains("Divider") || name.contains("Border")
                if verticalLine, onEdge, isDivider {
                    view.isHidden = true
                    view.alpha = 0
                }
                view.subviews.forEach(walk)
            }
            walk(split.view)
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

        private static let fillIdentifier = "HolyPlaces.listHeaderFill"
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
    var active: Bool

    func makeUIView(context: Context) -> Anchor {
        Anchor()
    }

    func updateUIView(_ uiView: Anchor, context: Context) {
        uiView.active = active
        uiView.title = title
        uiView.subtitle = subtitle
        uiView.titleColor = titleColor
        uiView.sync()
    }

    final class Anchor: UIView {
        var active = false
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
            guard active else {
                panel.removeFromSuperview()
                return
            }
            guard !positioning else { return }
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
