//
//  HolyPlacesTabBarController.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

final class HolyPlacesTabBarController: UITabBarController, UITabBarControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        let router = AppRouter.shared
        viewControllers = [
            homeController(),
            host(PlacesTabView().environmentObject(router), title: "Places", image: "starOfMelchizedek"),
            host(VisitsTabView().environmentObject(router), title: "Visits", image: "journal"),
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
        UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        return true
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
