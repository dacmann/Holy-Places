//
//  HolyPlacesTabBarController.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

final class HolyPlacesTabBarController: UITabBarController, UITabBarControllerDelegate {
    private weak var departed: UIViewController?
    /// True while Places or Visits is opened out of sight ahead of its first visit.
    private(set) var isPreparingFirstVisit = false

    init() {
        super.init(nibName: nil, bundle: nil)
        let router = AppRouter.shared
        viewControllers = [
            homeController(),
            splitHost(PlacesTabView().environmentObject(router), title: "Places", image: "starOfMelchizedek"),
            splitHost(VisitsTabView().environmentObject(router), title: "Visits", image: "journal"),
            summaryController(),
            host(MapTabView(), title: "Map", image: "map")
        ]
        router.tabBar = self
        delegate = self
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior = .never
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        prepareFirstVisit(to: viewController)
        guard let fromView = selectedViewController?.view, let toView = viewController.view, fromView != toView else {
            return true
        }
        departed = selectedViewController
        UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        return true
    }

    /// Switches tabs from code, preparing Places or Visits the same way a tap does.
    func show(tabAt index: Int) {
        if let controllers = viewControllers, controllers.indices.contains(index) {
            prepareFirstVisit(to: controllers[index])
        }
        selectedIndex = index
    }

    /// iPadOS gives Places and Visits a taller top safe area on their first appearance than on
    /// any later one. Opening the tab and returning to the current one before the screen redraws
    /// makes the visit the user sees the tab's second appearance.
    private func prepareFirstVisit(to controller: UIViewController) {
        guard UIDevice.current.userInterfaceIdiom == .pad, !isPreparingFirstVisit,
              let tab = controller as? FirstVisitPreparing, !tab.isPrepared,
              let current = selectedViewController, current !== controller else { return }
        tab.isPrepared = true
        isPreparingFirstVisit = true
        UIView.performWithoutAnimation {
            selectedViewController = controller
            view.layoutIfNeeded()
            controller.view.layoutIfNeeded()
            selectedViewController = current
            view.layoutIfNeeded()
        }
        isPreparingFirstVisit = false
    }

    /// Leaves `controller` for the tab the user came from, then opens it again the way a tap does.
    func reopen(_ controller: UIViewController, completion: @escaping () -> Void) {
        var other = departed
        if other === controller || other?.isViewLoaded != true {
            other = viewControllers?.first { $0 !== controller && $0.isViewLoaded }
        }
        guard selectedViewController === controller, presentedViewController == nil, let other else {
            completion()
            return
        }
        UIView.performWithoutAnimation {
            selectedViewController = other
            view.layoutIfNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.tabBarController(self, shouldSelect: controller) {
                self.selectedViewController = controller
            }
            completion()
        }
    }

    private func homeController() -> UIViewController {
        let controller = HomeHostingController(rootView: HomeTabView())
        controller.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "morningstar-bnw"), selectedImage: nil)
        return controller
    }

    private func host<Content: View>(_ root: Content, title: String, image: String) -> UIViewController {
        let controller = UIHostingController(rootView: root)
        controller.tabBarItem = UITabBarItem(title: title, image: UIImage(named: image), selectedImage: nil)
        return controller
    }

    private func splitHost<Content: View>(_ root: Content, title: String, image: String) -> UIViewController {
        let controller = SplitTabHostingController(rootView: root)
        controller.tabBarItem = UITabBarItem(title: title, image: UIImage(named: image), selectedImage: nil)
        return controller
    }

    private func summaryController() -> UIViewController {
        let controller = SummaryVC()
        controller.tabBarItem = UITabBarItem(title: "Summary", image: UIImage(named: "summary"), selectedImage: nil)
        return controller
    }
}

/// Keeps Home’s title and buttons clear of the iPad top tab bar and the home indicator.
/// The photo still draws full-bleed because Home ignores the safe area only on its background.
final class HomeHostingController: UIHostingController<HomeTabView> {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let window = view.window else { return }
        let viewInWindow = view.convert(view.bounds, to: window)
        var neededTop: CGFloat = 0
        var neededBottom: CGFloat = 0
        if let tabBar = tabBarController?.tabBar, !tabBar.isHidden, tabBar.alpha > 0.01 {
            let tab = tabBar.convert(tabBar.bounds, to: window)
            if tab.midY < window.bounds.midY {
                neededTop = max(0, tab.maxY - viewInWindow.minY)
            } else {
                neededBottom = max(0, viewInWindow.maxY - tab.minY)
            }
        }
        neededTop = max(neededTop, window.safeAreaInsets.top - viewInWindow.minY)
        neededBottom = max(neededBottom, viewInWindow.maxY - (window.bounds.height - window.safeAreaInsets.bottom))
        let systemTop = view.safeAreaInsets.top - additionalSafeAreaInsets.top
        let systemBottom = view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom
        let extra = UIEdgeInsets(
            top: max(0, neededTop - systemTop),
            left: 0,
            bottom: max(0, neededBottom - systemBottom),
            right: 0
        )
        if abs(additionalSafeAreaInsets.top - extra.top) > 0.5
            || abs(additionalSafeAreaInsets.bottom - extra.bottom) > 0.5 {
            additionalSafeAreaInsets = extra
        }
    }
}

protocol FirstVisitPreparing: AnyObject {
    var isPrepared: Bool { get set }
}

/// Hosts Places or Visits. If an appearance still has the taller top inset of a first
/// appearance, which pushes both columns down from the top tab bar, the tab leaves and
/// opens again behind a snapshot of the screen the user came from.
final class SplitTabHostingController<Content: View>: UIHostingController<Content>, FirstVisitPreparing {
    var isPrepared = false
    private var didReopen = false
    private var cover: UIView?

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        if needsReopen {
            coverScreen()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didReopen, cover != nil || needsReopen,
              let tabs = tabBarController as? HolyPlacesTabBarController else { return }
        didReopen = true
        coverScreen()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.reopenWhenClear(tabs)
        }
    }

    private var needsReopen: Bool {
        guard !didReopen, UIDevice.current.userInterfaceIdiom == .pad,
              let tabs = tabBarController as? HolyPlacesTabBarController, !tabs.isPreparingFirstVisit,
              let window = view.window else { return false }
        return view.safeAreaInsets.top - window.safeAreaInsets.top > 20
    }

    /// Switching tabs under an alert or sheet could interrupt it, so the round trip waits for it to close.
    private func reopenWhenClear(_ tabs: HolyPlacesTabBarController) {
        guard tabs.selectedViewController === self else {
            uncoverScreen()
            return
        }
        guard tabs.presentedViewController == nil else {
            uncoverScreen()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.reopenWhenClear(tabs)
            }
            return
        }
        coverScreen()
        tabs.reopen(self) { [weak self] in
            self?.uncoverScreen()
        }
    }

    private func coverScreen() {
        guard cover == nil, let window = tabBarController?.view.window,
              let snapshot = window.snapshotView(afterScreenUpdates: false) else { return }
        snapshot.frame = window.bounds
        window.addSubview(snapshot)
        cover = snapshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak snapshot] in
            snapshot?.removeFromSuperview()
        }
    }

    private func uncoverScreen() {
        guard let cover else { return }
        self.cover = nil
        UIView.animate(withDuration: 0.15, animations: {
            cover.alpha = 0
        }, completion: { _ in
            cover.removeFromSuperview()
        })
    }
}
