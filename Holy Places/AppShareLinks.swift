//
//  AppShareLinks.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation

enum AppSharePlatform {
    case ios
    case android

    var storeURL: URL {
        switch self {
        case .ios:
            return AppShareLinks.iosStoreURL
        case .android:
            return AppShareLinks.androidStoreURL
        }
    }

    var qrTitle: String {
        switch self {
        case .ios:
            return "App Store"
        case .android:
            return "Google Play"
        }
    }

    var linkPickerTitle: String {
        switch self {
        case .ios:
            return "App Store (iOS)"
        case .android:
            return "Google Play (Android)"
        }
    }

    var qrCodeMenuTitle: String {
        switch self {
        case .ios:
            return "App Store (Apple) QR Code"
        case .android:
            return "Google Play (Android) QR Code"
        }
    }

    var qrScanInstruction: String {
        switch self {
        case .ios:
            return "Scan to open in the App Store"
        case .android:
            return "Scan to open in Google Play"
        }
    }
}

enum AppShareLinks {
    static let shareText = "Holy Places of the Lord - Temples and Historic Sites by Derek Cordon"

    static let iosStoreURL = URL(string: "https://apps.apple.com/us/app/holy-places-of-the-lord/id1200184537")!
    static let androidStoreURL = URL(string: "https://play.google.com/store/apps/details?id=net.dacworld.android.holyplacesofthelord")!

    static let promotionalPDFName = "HolyPlacesPromo"

    static func activityItems(for platform: AppSharePlatform) -> [Any] {
        [shareText, platform.storeURL]
    }

    static var promotionalPDFURL: URL? {
        Bundle.main.url(forResource: promotionalPDFName, withExtension: "pdf")
    }
}
