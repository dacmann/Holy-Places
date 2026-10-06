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
        guard let fromView = selectedViewController?.view, let toView = viewController.view, fromView != toView else {
            return true
        }
        departed = selectedViewController
        // The first iPad visit to Places or Visits opens behind a cover, so a crossfade would not be seen.
        if UIDevice.current.userInterfaceIdiom == .pad,
           let split = viewController as? SplitTabPreparing, !split.hasAppeared {
            return true
        }
        UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        return true
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

protocol SplitTabPreparing: AnyObject {
    var hasAppeared: Bool { get }
}

/// iPadOS gives Places and Visits a taller top safe area on their first appearance than on
/// any later one, which pushes both columns down from the top tab bar. The first visit
/// therefore leaves the tab and opens it again behind a snapshot of the screen the user came from.
final class SplitTabHostingController<Content: View>: UIHostingController<Content>, SplitTabPreparing {
    private(set) var hasAppeared = false
    private var cover: UIView?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasAppeared, UIDevice.current.userInterfaceIdiom == .pad {
            coverScreen()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAppeared else { return }
        hasAppeared = true
        guard UIDevice.current.userInterfaceIdiom == .pad,
              let tabs = tabBarController as? HolyPlacesTabBarController else {
            uncoverScreen()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.reopenWhenClear(tabs)
        }
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
