//
//  Extensions.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/12/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import SwiftUI
import UIKit

struct HolyPlacesSearchFontFix: UIViewRepresentable {
    func makeUIView(context: Context) -> SearchFontAnchor {
        SearchFontAnchor()
    }

    func updateUIView(_ uiView: SearchFontAnchor, context: Context) {
        uiView.apply()
    }

    final class SearchFontAnchor: UIView {
        private var pendingApply = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            apply()
            guard !pendingApply else { return }
            pendingApply = true
            DispatchQueue.main.async { [weak self] in
                self?.pendingApply = false
                self?.apply()
            }
        }

        func apply() {
            let font = UIFont(name: "Baskerville", size: 16) ?? .systemFont(ofSize: 16)
            var responder: UIResponder? = self
            var roots: [UIView] = []
            while let next = responder?.next {
                if let controller = next as? UIViewController {
                    if let navigationView = controller.navigationController?.view {
                        roots.append(navigationView)
                    }
                    if let view = controller.view {
                        roots.append(view)
                    }
                } else if let window = next as? UIWindow {
                    roots.append(window)
                }
                responder = next
            }
            for root in roots {
                styleSearchFields(in: root, font: font)
            }
        }

        private func styleSearchFields(in view: UIView, font: UIFont) {
            if let field = view as? UITextField, isSearchField(field) {
                if field.font?.fontName != font.fontName || field.font?.pointSize != font.pointSize {
                    var attributes = field.defaultTextAttributes
                    attributes[.font] = font
                    field.defaultTextAttributes = attributes
                    field.font = font
                }
                if let placeholder = field.placeholder, !placeholder.isEmpty {
                    let current = field.attributedPlaceholder?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
                    if current?.fontName != font.fontName || current?.pointSize != font.pointSize {
                        let color = (field.attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor) ?? .placeholderText
                        field.attributedPlaceholder = NSAttributedString(
                            string: placeholder,
                            attributes: [.font: font, .foregroundColor: color]
                        )
                    }
                }
            }
            for subview in view.subviews {
                styleSearchFields(in: subview, font: font)
            }
        }

        private func isSearchField(_ field: UITextField) -> Bool {
            if field is UISearchTextField { return true }
            var view: UIView? = field
            while let current = view {
                if current is UISearchBar { return true }
                if String(describing: type(of: current)).localizedCaseInsensitiveContains("search") {
                    return true
                }
                view = current.superview
            }
            return false
        }
    }
}

extension Notification.Name {
    static let reload = Notification.Name("reload")
    static let homeAppearanceDidChange = Notification.Name("homeAppearanceDidChange")
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}

extension Date {
    func daysBetweenDate(toDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: toDate)
        return components.day ?? 0
    }
}

extension CGSize {
    
    func resizeFill(toSize: CGSize) -> CGSize {
        
        let scale : CGFloat = (self.height / self.width) < (toSize.height / toSize.width) ? (self.height / toSize.height) : (self.width / toSize.width)
        return CGSize(width: (self.width / scale), height: (self.height / scale))
        
    }
}

extension UIImage {
    
    func scale(toSize newSize:CGSize) -> UIImage {
        
        // make sure the new size has the correct aspect ratio
        let aspectFill = self.size.resizeFill(toSize: newSize)
        
        UIGraphicsBeginImageContextWithOptions(aspectFill, false, 0.0)
        self.draw(in: CGRect(x:0, y:0, width:aspectFill.width, height:aspectFill.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// JPEG data sized for visit storage and XML backup (well under the 10 MB CDATA limit).
    func jpegDataForVisitStorage() -> Data? {
        VisitPhotoCompression.encodedData(from: self)
    }

    /// Complementary letterbox color sampled from the image, darkened so the photo stays
    /// the focus when Crop to fill is off. Matches Android `ColorUtils.complementaryFillColor`.
    func complementaryFillColor() -> UIColor {
        let sampleSize = 32
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: sampleSize, height: sampleSize), format: format)
        let sampled = renderer.image { _ in
            draw(in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))
        }
        guard let cgImage = sampled.cgImage else { return .black }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return .black }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .black }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var red: Int64 = 0
        var green: Int64 = 0
        var blue: Int64 = 0
        var count: Int64 = 0
        let pixelCount = width * height
        for i in 0..<pixelCount {
            let offset = i * bytesPerPixel
            if rawData[offset + 3] >= 32 {
                red += Int64(rawData[offset])
                green += Int64(rawData[offset + 1])
                blue += Int64(rawData[offset + 2])
                count += 1
            }
        }
        guard count > 0 else { return .black }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(
            red: CGFloat(red / count) / 255,
            green: CGFloat(green / count) / 255,
            blue: CGFloat(blue / count) / 255,
            alpha: 1
        ).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        hue = (hue + 0.5).truncatingRemainder(dividingBy: 1)
        saturation = min(max(saturation * 0.55 + 0.25, 0.2), 0.7)
        brightness = min(max(brightness * 0.45 + 0.15, 0.18), 0.45)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
}

/// Caps visit photos at 1920px on the long edge and ~1.5 MB so base64 XML stays far below
/// libxml2's 10 MB CDATA limit. Always renders at scale 1.0 — `UIGraphicsBeginImageContext`
/// uses the screen scale and can *increase* file size on @2x/@3x devices.
enum VisitPhotoCompression {
    static let maxDimension: CGFloat = 1920
    static let maxBytes = 1_500_000
    static let jpegQuality: CGFloat = 0.7
    
    static func encodedData(from image: UIImage) -> Data? {
        jpegData(from: resized(image), maxBytes: maxBytes, startingQuality: jpegQuality)
    }
    
    static func encodedData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let pixelLongest = max(image.size.width * image.scale, image.size.height * image.scale)
        if data.count <= maxBytes, image.scale == 1, pixelLongest <= maxDimension {
            return data
        }
        return encodedData(from: image)
    }
    
    private static func resized(_ image: UIImage) -> UIImage {
        let pixelSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let longest = max(pixelSize.width, pixelSize.height)
        let targetSize: CGSize
        if longest > maxDimension {
            let ratio = maxDimension / longest
            targetSize = CGSize(width: pixelSize.width * ratio, height: pixelSize.height * ratio)
        } else if image.scale == 1 {
            return image
        } else {
            targetSize = pixelSize
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private static func jpegData(from image: UIImage, maxBytes: Int, startingQuality: CGFloat) -> Data? {
        var quality = startingQuality
        var data = image.jpegData(compressionQuality: quality)
        while let current = data, current.count > maxBytes, quality > 0.4 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }
        return data
    }
}

// Utility to lock the orientation of the device when called
struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
    
}

extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return false }
        return !window.frame.equalTo(window.screen.bounds)
    }
}

extension View {
    /// Hides the bottom tab bar on iPhone once a place or visit detail is showing.
    /// On iPad the list stays on screen, so the tab bar stays visible.
    func hideTabBarWhenCompact() -> some View {
        modifier(CompactTabBarHider())
    }

    /// Thin separator around a wheel picker, inset from the sheet edges.
    func pickerBorder() -> some View {
        padding(.horizontal, 20)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(uiColor: .separator), lineWidth: 1)
                    .padding(.horizontal, 20)
                    .allowsHitTesting(false)
            }
    }
}

/// All / Visited / Not Visited style choices, matching the Visits list:
/// selected text is white on BaptismsBlueBtn, and the others stay plain.
struct ScopeChoiceButtons: View {
    let titles: [String]
    var selection: Int
    var accessibilityLabel: ((String) -> String)? = nil
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(titles.indices, id: \.self) { index in
                let title = titles[index]
                let selected = selection == index
                Button {
                    onSelect(index)
                } label: {
                    Text(title)
                        .font(.custom("Baskerville", size: 16))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selected ? Color("BaptismsBlueBtn") : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel?(title) ?? title)
            }
        }
    }
}

private struct CompactTabBarHider: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .toolbar(horizontalSizeClass == .compact ? .hidden : .automatic, for: .tabBar)
            .background {
                CompactTabBarBridge(hidden: horizontalSizeClass == .compact)
            }
    }
}

/// Posted before a navigation controller actually pops, so the tab bar can be
/// shown before the back-button animation starts. A swipe already does this
/// from the gesture; the back button does not.
private enum HolyPlacesNavigationPop {
    static let willPop = Notification.Name("hp.navigationWillPop")
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true
        replace(#selector(UINavigationController.popViewController(animated:))) { original, selector in
            let block: @convention(block) (UINavigationController, Bool) -> UIViewController? = { nav, animated in
                NotificationCenter.default.post(name: willPop, object: nav)
                let function = unsafeBitCast(original, to: (@convention(c) (AnyObject, Selector, Bool) -> UIViewController?).self)
                return function(nav, selector, animated)
            }
            return imp_implementationWithBlock(block)
        }
        replace(#selector(UINavigationController.setViewControllers(_:animated:))) { original, selector in
            let block: @convention(block) (UINavigationController, NSArray, Bool) -> Void = { nav, controllers, animated in
                let next = controllers.compactMap { $0 as? UIViewController }
                if animated, next.count < nav.viewControllers.count {
                    NotificationCenter.default.post(name: willPop, object: nav, userInfo: ["remaining": next])
                }
                let function = unsafeBitCast(original, to: (@convention(c) (AnyObject, Selector, NSArray, Bool) -> Void).self)
                function(nav, selector, controllers, animated)
            }
            return imp_implementationWithBlock(block)
        }
    }

    private static func replace(_ selector: Selector, implementation: (IMP, Selector) -> IMP) {
        guard let method = class_getInstanceMethod(UINavigationController.self, selector) else { return }
        let original = method_getImplementation(method)
        method_setImplementation(method, implementation(original, selector))
    }
}

/// The Places and Visits screens own the tab bar, so a SwiftUI toolbar preference
/// does not hide it. This bridge hides that bar only while the detail is on screen
/// and shows it again as soon as the detail starts leaving.
private struct CompactTabBarBridge: UIViewControllerRepresentable {
    var hidden: Bool

    func makeUIViewController(context: Context) -> BridgeController {
        BridgeController()
    }

    func updateUIViewController(_ controller: BridgeController, context: Context) {
        controller.wantsHidden = hidden
        controller.apply()
    }

    static func dismantleUIViewController(_ controller: BridgeController, coordinator: ()) {
        controller.leave()
    }

    final class BridgeController: UIViewController {
        var wantsHidden = false
        /// Set when this detail is going back to the list, so layout during the
        /// slide does not hide the bar again.
        private var leaving = false
        private weak var tabs: UITabBarController?
        private var isApplying = false
        private weak var popGesture: UIGestureRecognizer?
        private static let active = NSHashTable<BridgeController>.weakObjects()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            HolyPlacesNavigationPop.install()
            Self.active.add(self)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(navigationWillPop(_:)),
                name: HolyPlacesNavigationPop.willPop,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            Self.active.remove(self)
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            leaving = false
            attachPopGesture()
            apply()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            attachPopGesture()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            guard wantsHidden, isPoppingOrDismissing else { return }
            beginLeaving()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            // A sheet over the detail also disappears this controller, but its view
            // stays in the window. Only a real pop takes the view out of the window.
            guard view.window == nil else { return }
            leaving = true
            reveal(animated: false)
            DispatchQueue.main.async { [weak self] in
                self?.reveal(animated: false)
            }
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            apply()
        }

        func leave() {
            wantsHidden = false
            leaving = true
            detachPopGesture()
            reveal(animated: false)
            // The pop animation can hide the bar again as it finishes.
            DispatchQueue.main.async { [weak self] in
                self?.reveal(animated: false)
            }
        }

        func apply() {
            guard !isApplying else { return }
            isApplying = true
            defer { isApplying = false }
            guard let tabs = resolvedTabs() else { return }
            let compact = tabs.traitCollection.horizontalSizeClass == .compact
            let shouldHide = wantsHidden && isOnScreen && !leaving && compact
            setTabBar(hidden: shouldHide, on: tabs)
        }

        private func reveal(animated: Bool) {
            beginLeaving()
            guard animated, let tabs = resolvedTabs() else { return }
            let coordinator = transitionCoordinator ?? ancestorTransitionCoordinator()
            coordinator?.animate(alongsideTransition: { _ in
                self.setTabBar(hidden: false, on: tabs)
            }, completion: { context in
                // A cancelled swipe keeps the detail up; viewWillAppear hides the bar.
                if !context.isCancelled {
                    self.setTabBar(hidden: false, on: tabs)
                }
            })
        }

        /// Shows the bar before a pop animation starts and keeps later layouts from hiding it.
        private func beginLeaving() {
            leaving = true
            guard let tabs = resolvedTabs() else { return }
            UIView.performWithoutAnimation {
                setTabBar(hidden: false, on: tabs)
            }
        }

        @objc private func navigationWillPop(_ note: Notification) {
            guard wantsHidden, let nav = note.object as? UINavigationController else { return }
            let remaining = note.userInfo?["remaining"] as? [UIViewController] ?? Array(nav.viewControllers.dropLast())
            let bridges = Self.active.allObjects.filter(\.wantsHidden)
            let staying = bridges.filter { bridge in
                remaining.contains { bridge.isContained(in: $0) }
            }
            // A place detail still on the stack should keep the bar hidden.
            guard staying.isEmpty else { return }
            let popping = bridges.contains { bridge in
                bridge.isOnScreen && !remaining.contains { bridge.isContained(in: $0) }
            }
            guard popping else { return }
            beginLeaving()
        }

        private func isContained(in controller: UIViewController?) -> Bool {
            guard let controller, let root = viewIfLoaded else { return false }
            return root.isDescendant(of: controller.view)
        }

        @objc private func popGestureChanged(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .began:
                beginLeaving()
            case .cancelled, .failed:
                guard wantsHidden, isOnScreen else { return }
                leaving = false
                apply()
            default:
                break
            }
        }

        private func attachPopGesture() {
            guard let gesture = enclosingNavigationController()?.interactivePopGestureRecognizer else { return }
            if popGesture !== gesture {
                detachPopGesture()
                gesture.addTarget(self, action: #selector(popGestureChanged))
                popGesture = gesture
            }
        }

        private func detachPopGesture() {
            if let popGesture {
                popGesture.removeTarget(self, action: #selector(popGestureChanged))
            }
            popGesture = nil
        }

        private func setTabBar(hidden: Bool, on tabs: UITabBarController) {
            let alreadyHidden: Bool
            if #available(iOS 18.0, *) {
                alreadyHidden = tabs.isTabBarHidden
            } else {
                alreadyHidden = tabs.tabBar.isHidden
            }
            if alreadyHidden == hidden {
                if hidden || tabs.tabBar.alpha > 0.99 { return }
            }
            if #available(iOS 18.0, *) {
                tabs.setTabBarHidden(hidden, animated: false)
                tabs.isTabBarHidden = hidden
            } else {
                tabs.tabBar.isHidden = hidden
            }
            if !hidden {
                tabs.tabBar.alpha = 1
            }
        }

        private var isPoppingOrDismissing: Bool {
            var controller: UIViewController? = self
            while let current = controller {
                if current.isMovingFromParent || current.isBeingDismissed { return true }
                controller = current.parent
            }
            return false
        }

        private var isOnScreen: Bool {
            guard let window = view.window, view.bounds.width > 1, view.bounds.height > 1 else { return false }
            let frame = view.convert(view.bounds, to: window)
            return frame.intersects(window.bounds)
        }

        private func resolvedTabs() -> UITabBarController? {
            if let found = nearestTabBarController() {
                tabs = found
            }
            return tabs
        }

        private func ancestorTransitionCoordinator() -> UIViewControllerTransitionCoordinator? {
            var controller: UIViewController? = self
            while let current = controller {
                if let coordinator = current.transitionCoordinator ?? current.navigationController?.transitionCoordinator {
                    return coordinator
                }
                controller = current.parent
            }
            return nil
        }

        private func enclosingNavigationController() -> UINavigationController? {
            var controller: UIViewController? = self
            while let current = controller {
                if let nav = current.navigationController { return nav }
                controller = current.parent
            }
            var responder: UIResponder? = view
            while let next = responder?.next {
                if let nav = next as? UINavigationController { return nav }
                responder = next
            }
            return nil
        }

        private func nearestTabBarController() -> UITabBarController? {
            if let tabBarController { return tabBarController }
            var responder: UIResponder? = self
            while let next = responder?.next {
                if let controller = next as? UIViewController, let tabs = controller.tabBarController {
                    return tabs
                }
                if let tabs = next as? UITabBarController {
                    return tabs
                }
                responder = next
            }
            return nil
        }
    }
}

extension UIViewController {
    /// Hide or show the tab bar, including the iPadOS 18+ tab bar at the top of the screen.
    func setAppTabBarHidden(_ hidden: Bool, animated: Bool = false) {
        guard let tabBarController else { return }
        if #available(iOS 18.0, *) {
            tabBarController.setTabBarHidden(hidden, animated: animated)
            tabBarController.isTabBarHidden = hidden
        } else {
            tabBarController.tabBar.isHidden = hidden
        }
    }

    /// Call from a pushed detail screen’s `viewWillAppear`.
    func hideTabBarForDetailScreen() {
        hidesBottomBarWhenPushed = true
        setAppTabBarHidden(true)
        hideCoveredListSearchBar()
        navigationItem.searchController = nil
        navigationItem.leftItemsSupplementBackButton = false
        if navigationItem.leftBarButtonItem?.accessibilityIdentifier == "hp.padDetailBackButton" {
            navigationItem.leftBarButtonItem = nil
        }
        navigationItem.hidesBackButton = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        if #available(iOS 16.0, *) {
            navigationItem.style = .navigator
        }
        let refresh: () -> Void = { [weak self] in
            self?.forceNavigationBarRefresh()
        }
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                refresh()
            }
        } else {
            DispatchQueue.main.async(execute: refresh)
        }
    }

    /// iPadOS 18 keeps the previous screen’s nav bar until a layout change (such as rotation).
    /// Toggling visibility forces it to pick up this screen’s items immediately.
    func forceNavigationBarRefresh() {
        guard UIDevice.current.userInterfaceIdiom == .pad, let nav = navigationController else { return }
        let isRootList = nav.viewControllers.count == 1
        if #available(iOS 16.0, *) {
            // `.browser` left-aligns the title; keep the default navigator style so
            // Places/Visits stay centered after popping from detail.
            navigationItem.style = .navigator
        }
        nav.setNavigationBarHidden(true, animated: false)
        nav.setNavigationBarHidden(false, animated: false)
        navigationItem.hidesBackButton = false
        if isRootList {
            // A leftover back-button slot shifts the custom titleView left.
            navigationItem.leftItemsSupplementBackButton = false
        } else {
            navigationItem.leftItemsSupplementBackButton = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
        if navigationItem.leftBarButtonItem?.accessibilityIdentifier == "hp.padDetailBackButton" {
            navigationItem.leftBarButtonItem = nil
        }
        if isRootList, let titleView = navigationItem.titleView {
            navigationItem.titleView = nil
            navigationItem.titleView = titleView
        }
    }

    /// After popping back to Places/Visits, bounce the iPadOS 18 tab/nav chrome so it
    /// drops Map / Places from the detail screen and shows this list’s items.
    func forceListChromeRefresh() {
        guard UIDevice.current.userInterfaceIdiom == .pad,
              navigationController?.viewControllers.count == 1,
              navigationController?.topViewController === self else { return }
        if #available(iOS 16.0, *) {
            navigationItem.style = .navigator
        }
        if #available(iOS 26.0, *) {
            tabBarController?.tabBarMinimizeBehavior = .never
        }
        setAppTabBarHidden(false)
        if #available(iOS 18.0, *) {
            tabBarController?.setTabBarHidden(true, animated: false)
            tabBarController?.setTabBarHidden(false, animated: false)
        }
        forceNavigationBarRefresh()
        tabBarController?.view.setNeedsLayout()
        tabBarController?.view.layoutIfNeeded()
    }

    func refreshListChromeAfterDetailPop() {
        forceListChromeRefresh()
        DispatchQueue.main.async { [weak self] in
            self?.forceListChromeRefresh()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.forceListChromeRefresh()
        }
    }

    /// iPadOS 18 hides the top tab bar when Search becomes active and often never
    /// shows it again until a layout change (rotation or a swipe from the top).
    func restoreIPadTabBar() {
        guard UIDevice.current.userInterfaceIdiom == .pad,
              navigationController?.viewControllers.count == 1 else { return }
        if #available(iOS 26.0, *) {
            tabBarController?.tabBarMinimizeBehavior = .never
        }
        navigationController?.setNavigationBarHidden(false, animated: false)
        setAppTabBarHidden(false)
        tabBarController?.view.setNeedsLayout()
        tabBarController?.view.layoutIfNeeded()
    }

    /// Call from a list screen’s `viewDidLayoutSubviews` so a system hide during Search is undone.
    /// Do not unhide the tab bar here — after a pop that would lock in Place Detail’s Map/Places items.
    func keepIPadListChromeVisible() {
        guard UIDevice.current.userInterfaceIdiom == .pad,
              view.window != nil,
              navigationController?.viewControllers.count == 1,
              navigationController?.topViewController === self else { return }
        if navigationController?.isNavigationBarHidden == true {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }

    func scheduleIPadTabBarRestore() {
        restoreIPadTabBar()
        DispatchQueue.main.async { [weak self] in
            self?.restoreIPadTabBar()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.restoreIPadTabBar()
        }
    }

    /// Places/Visits pin their search bar in the nav bar; remove it while a detail screen is on top.
    func hideCoveredListSearchBar() {
        guard let nav = navigationController, nav.viewControllers.count > 1 else { return }
        nav.viewControllers[nav.viewControllers.count - 2].navigationItem.searchController = nil
    }

    func restoreListSearchBar(_ searchController: UISearchController) {
        if navigationItem.searchController == nil {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }

    /// Call from a pushed detail screen’s `viewWillDisappear`.
    /// Restores the tab bar only when popping back to a root tab screen, not when pushing another detail.
    func restoreTabBarIfLeavingDetail() {
        guard isMovingFromParent else { return }
        if navigationController?.viewControllers.last?.hidesBottomBarWhenPushed == true {
            return
        }
        // On iPad the combined tab/nav bar would keep this detail’s items (Map / Places)
        // if we show it while this screen is still top. The list restores chrome after the pop.
        if UIDevice.current.userInterfaceIdiom == .pad {
            return
        }
        setAppTabBarHidden(false)
    }

    /// Height of the list search bar that remains drawn over a pushed screen during the transition.
    static func incomingSearchBarClearance(from searchBar: UISearchBar?) -> CGFloat {
        guard let searchBar = searchBar else { return 56 }
        return searchBar.bounds.height > 1 ? searchBar.bounds.height : 56
    }
    
    /// Places and Visits keep a search bar in the nav bar. During a push that bar
    /// stays on screen and covers the new screen's top (visit name/date, or the
    /// place photo). Pad content below it until the transition finishes.
    func padContentBelowIncomingSearchBar() {
        guard let coordinator = transitionCoordinator,
              coordinator.isAnimated,
              let from = coordinator.viewController(forKey: .from) else { return }
        let extra: CGFloat
        if let searchBar = from.navigationItem.searchController?.searchBar {
            extra = UIViewController.incomingSearchBarClearance(from: searchBar)
        } else {
            return
        }
        additionalSafeAreaInsets.top = extra
        coordinator.animate(alongsideTransition: nil) { [weak self] context in
            guard !context.isCancelled else { return }
            self?.additionalSafeAreaInsets.top = 0
        }
    }
}

public extension NSLayoutConstraint {
    
    func changeMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(
            item: firstItem!,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        newConstraint.priority = priority
        
        NSLayoutConstraint.deactivate([self])
        NSLayoutConstraint.activate([newConstraint])
        
        return newConstraint
    }
}

public extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        // iPhone (iOS 15+ supported)
        case "iPhone8,4": return "iPhone SE"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1": return "iPhone 8"
        case "iPhone10,2": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd Gen)"
        case "iPhone13,1": return "iPhone 12 Mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 Mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd Gen)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
            
        // iPhone 16 Series
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,5": return "iPhone 16e"

        // iPhone 17 Series
        case "iPhone18,3": return "iPhone 17"
        case "iPhone18,1": return "iPhone 17 Pro"
        case "iPhone18,2": return "iPhone 17 Pro Max"
        case "iPhone18,4": return "iPhone Air"
        case "iPhone18,5": return "iPhone 17e"

        // iPhone 18 Series
        case "iPhone19,2": return "iPhone 18 Pro"
        case "iPhone19,3", "iPhone19,7": return "iPhone 18 Pro Max"
        case "iPhone19,4": return "iPhone Duo"

        // iPad (iOS 15+ supported)
        case "iPad6,11", "iPad6,12": return "iPad 5th Gen"
        case "iPad7,5", "iPad7,6": return "iPad 6th Gen"
        case "iPad7,11", "iPad7,12": return "iPad 7th Gen"
        case "iPad11,6", "iPad11,7": return "iPad 8th Gen"
        case "iPad12,1", "iPad12,2": return "iPad 9th Gen"
        case "iPad13,18", "iPad13,19": return "iPad 10th Gen"

        case "iPad11,1", "iPad11,2": return "iPad Mini 5"
        case "iPad14,1", "iPad14,2": return "iPad Mini 6"

        case "iPad11,3", "iPad11,4": return "iPad Air 3rd Gen"
        case "iPad13,1", "iPad13,2": return "iPad Air 4th Gen"
        case "iPad13,16", "iPad13,17": return "iPad Air 5th Gen"

        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro 11-inch (1st Gen)"
        case "iPad8,9", "iPad8,10": return "iPad Pro 11-inch (2nd Gen)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (3rd Gen)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (4th Gen)"

        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro 12.9-inch (3rd Gen)"
        case "iPad8,11", "iPad8,12": return "iPad Pro 12.9-inch (4th Gen)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th Gen)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th Gen)"

        // Simulator
        case "i386", "x86_64", "arm64":
            return "Simulator"

        default:
            return identifier
        }
    }
}


extension UIColor {
    
    // home screen font color
    class func home() -> UIColor {
        if homeTextColor == 0 {
            return UIColor.white
        } else {
            return UIColor.black
        }
    }
    
    class func cantaloupe() -> UIColor {
        return UIColor(red:255/255, green:204/255, blue:102/255, alpha:1.0)
    }
    class func honeydew() -> UIColor {
        return UIColor(red:204/255, green:255/255, blue:102/255, alpha:1.0)
    }
    class func spindrift() -> UIColor {
        return UIColor(red:102/255, green:255/255, blue:204/255, alpha:1.0)
    }
    class func sky() -> UIColor {
        return UIColor(red:102/255, green:204/255, blue:255/255, alpha:1.0)
    }
    class func lavender() -> UIColor {
        return UIColor(red:204/255, green:102/255, blue:255/255, alpha:1.0)
    }
    class func carnation() -> UIColor {
        return UIColor(red:255/255, green:111/255, blue:207/255, alpha:1.0)
    }
    class func licorice() -> UIColor {
        return UIColor(red:0/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func snow() -> UIColor {
        return UIColor(red:255/255, green:255/255, blue:255/255, alpha:1.0)
    }
    class func salmon() -> UIColor {
        return UIColor(red:255/255, green:102/255, blue:102/255, alpha:1.0)
    }
    class func banana() -> UIColor {
        return UIColor(red:255/255, green:255/255, blue:102/255, alpha:1.0)
    }
    class func flora() -> UIColor {
        return UIColor(red:102/255, green:255/255, blue:102/255, alpha:1.0)
    }
    class func ice() -> UIColor {
        return UIColor(red:102/255, green:255/255, blue:255/255, alpha:1.0)
    }
    class func orchid() -> UIColor {
        return UIColor(red:102/255, green:102/255, blue:255/255, alpha:1.0)
    }
    class func bubblegum() -> UIColor {
        return UIColor(red:255/255, green:102/255, blue:255/255, alpha:1.0)
    }
    class func lead() -> UIColor {
        return UIColor(red:25/255, green:25/255, blue:25/255, alpha:1.0)
    }
    class func mercury() -> UIColor {
        return UIColor(red:230/255, green:230/255, blue:230/255, alpha:1.0)
    }
    class func tangerine() -> UIColor {
        return UIColor(red:255/255, green:128/255, blue:0/255, alpha:1.0)
    }
    class func lime() -> UIColor {
        return UIColor(red:128/255, green:255/255, blue:0/255, alpha:1.0)
    }
    class func seafoam() -> UIColor {
        return UIColor(red:0/255, green:255/255, blue:128/255, alpha:1.0)
    }
    class func aqua() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:255/255, alpha:1.0)
    }
    class func grape() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:255/255, alpha:1.0)
    }
    class func strawberry() -> UIColor {
        return UIColor(red:255/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func tungsten() -> UIColor {
        return UIColor(red:51/255, green:51/255, blue:51/255, alpha:1.0)
    }
    class func silver() -> UIColor {
        return UIColor(red:204/255, green:204/255, blue:204/255, alpha:1.0)
    }
    class func maraschino() -> UIColor {
        return UIColor(red:255/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func lemon() -> UIColor {
        return UIColor(red:255/255, green:255/255, blue:0/255, alpha:1.0)
    }
    class func spring() -> UIColor {
        return UIColor(red:0/255, green:255/255, blue:0/255, alpha:1.0)
    }
    class func turquoise() -> UIColor {
        return UIColor(red:0/255, green:255/255, blue:255/255, alpha:1.0)
    }
    class func blueberry() -> UIColor {
        return UIColor(red:0/255, green:0/255, blue:255/255, alpha:1.0)
    }
    class func magenta() -> UIColor {
        return UIColor(red:255/255, green:0/255, blue:255/255, alpha:1.0)
    }
    class func iron() -> UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 179/255, green: 179/255, blue: 179/255, alpha: 1.0)
            }
            return UIColor(red: 76/255, green: 76/255, blue: 76/255, alpha: 1.0)
        }
    }
    class func magnesium() -> UIColor {
        return UIColor(red:179/255, green:179/255, blue:179/255, alpha:1.0)
    }
    class func mocha() -> UIColor {
        return UIColor(red:128/255, green:64/255, blue:0/255, alpha:1.0)
    }
    class func fern() -> UIColor {
        return UIColor(red:64/255, green:128/255, blue:0/255, alpha:1.0)
    }
    class func moss() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:64/255, alpha:1.0)
    }
    class func ocean() -> UIColor {
        return UIColor(red:0/255, green:64/255, blue:128/255, alpha:1.0)
    }
    class func eggplant() -> UIColor {
        return UIColor(red:64/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func maroon() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:64/255, alpha:1.0)
    }
    class func steel() -> UIColor {
        return UIColor(red:102/255, green:102/255, blue:102/255, alpha:1.0)
    }
    class func aluminium() -> UIColor {
        return UIColor(red:153/255, green:153/255, blue:153/255, alpha:1.0)
    }
    class func cayenne() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func asparagus() -> UIColor {
        return UIColor(red:128/255, green:120/255, blue:0/255, alpha:1.0)
    }
    class func clover() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:0/255, alpha:1.0)
    }
    class func teal() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:128/255, alpha:1.0)
    }
    class func midnight() -> UIColor {
        return UIColor(red:0/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func plum() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func tin() -> UIColor {
        return UIColor(red:127/255, green:127/255, blue:127/255, alpha:1.0)
    }
    class func nickel() -> UIColor {
        return UIColor(red:128/255, green:128/255, blue:128/255, alpha:1.0)
    }
    class func royalPurple() -> UIColor {
        return UIColor(red:83/255, green:56/255, blue:117/255, alpha:1.0)
    }
    class func darkRed() -> UIColor {
        return UIColor(red:114/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func strongYellow() -> UIColor {
        return UIColor(red:179/255, green:151/255, blue:0/255, alpha:1.0)
    }
    class func pureYellow() -> UIColor {
        return UIColor(red:230/255, green:194/255, blue:0/255, alpha:1.0)
    }
    class func darkOrange() -> UIColor {
        return UIColor(red:166/255, green:83/255, blue:0/255, alpha:1.0)
    }
    class func darkLimeGreen() -> UIColor {
        return UIColor(red:0/255, green:114/255, blue:0/255, alpha:1.0)
    }
    class func darkTangerine() -> UIColor {
        return UIColor(red:255/255, green:168/255, blue:18/255, alpha:1.0)
    }
    class func olive() -> UIColor {
        return UIColor(red:50/255, green:50/255, blue:0/255, alpha:1.0)
    }
    class func flame() -> UIColor {
        return UIColor(red:226/255, green:88/255, blue:34/255, alpha:1.0)
    }
}
