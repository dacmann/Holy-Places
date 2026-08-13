//
//  AchievementShareImageRenderer.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import UIKit
import LinkPresentation

enum AchievementShareImageRenderer {

    private static let homeTagline = "\"Stand ye in holy places, and be not moved...\""
    private static let homeReference = "D&C 87:8"

    static func shareItems(for achievement: Achievement) -> [Any] {
        let image = render(achievement: achievement)
        let caption = shareCaption(for: achievement)
        // Many social apps ignore extra text items and only take the image.
        // Copying the caption lets the user paste it into the post.
        UIPasteboard.general.string = caption
        return [
            AchievementShareCaptionItem(caption: caption, image: image),
            AchievementShareImageItem(image: image)
        ]
    }

    static func shareCaption(for achievement: Achievement) -> String {
        """
        I just unlocked \(achievement.name) — \(achievement.details). Holy Places of the Lord helped me record my visits and see this milestone come together. It’s a free app for keeping a personal history of temples and historic sites, available on the App Store and Google Play.
        """
    }

    static func render(achievement: Achievement) -> UIImage {
        let size = CGSize(width: 675, height: 410)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            let accent = accentColor(for: achievement.iconName)
            let placeColor = placeAccentColor(for: achievement.iconName)
            accent.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: 6))
            UIRectFill(CGRect(x: 0, y: size.height - 6, width: size.width, height: 6))

            // MARK: Header
            let logoSide: CGFloat = 76
            if let logo = UIImage(named: "morningstarmoroni") {
                logo.draw(in: CGRect(x: 10, y: 12, width: logoSide, height: logoSide))
            }

            let appName = CelebrationBoardConfig.appDisplayName as NSString
            let appAttrs: [NSAttributedString.Key: Any] = [
                .font: font("Baskerville", size: 36),
                .foregroundColor: UIColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1)
            ]
            let appTextSize = appName.size(withAttributes: appAttrs)
            var y: CGFloat = 22
            appName.draw(at: CGPoint(x: (size.width - appTextSize.width) / 2, y: y), withAttributes: appAttrs)
            y += appTextSize.height + 1

            let tagline = homeTagline as NSString
            let taglineAttrs: [NSAttributedString.Key: Any] = [
                .font: font("Baskerville-Italic", size: 20, italicFallback: true),
                .foregroundColor: UIColor.darkGray
            ]
            let taglineSize = tagline.size(withAttributes: taglineAttrs)
            tagline.draw(at: CGPoint(x: (size.width - taglineSize.width) / 2, y: y), withAttributes: taglineAttrs)
            y += taglineSize.height

            let reference = homeReference as NSString
            let referenceAttrs: [NSAttributedString.Key: Any] = [
                .font: font("Baskerville-Italic", size: 15, italicFallback: true),
                .foregroundColor: UIColor.gray
            ]
            let referenceSize = reference.size(withAttributes: referenceAttrs)
            reference.draw(
                at: CGPoint(
                    x: (size.width - taglineSize.width) / 2 + taglineSize.width - referenceSize.width,
                    y: y
                ),
                withAttributes: referenceAttrs
            )
            y += referenceSize.height + 18

            let unlocked = "Achievement Unlocked!" as NSString
            let unlockedAttrs: [NSAttributedString.Key: Any] = [
                .font: font("Baskerville-Bold", size: 48, boldFallback: true),
                .foregroundColor: accent
            ]
            let unlockedSize = unlocked.size(withAttributes: unlockedAttrs)
            unlocked.draw(at: CGPoint(x: (size.width - unlockedSize.width) / 2, y: y), withAttributes: unlockedAttrs)
            y += unlockedSize.height + 8

            // MARK: Main content
            let contentTop = y
            let contentBottom = size.height - 8
            let contentHeight = contentBottom - contentTop

            let iconSide: CGFloat = min(220, contentHeight)
            let iconX: CGFloat = 12
            let textX = iconX + iconSide + 10
            let textWidth = size.width - textX - 12

            let titleFont = font("Baskerville-Bold", size: 42, boldFallback: true)
            let detailsFont = font("Baskerville", size: 26)
            let metaFont = font("Baskerville", size: 24)

            let title = achievement.name as NSString
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: accent
            ]
            let titleHeight = ceil(title.boundingRect(
                with: CGSize(width: textWidth, height: 110),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: titleAttrs,
                context: nil
            ).height)

            let details = achievement.details as NSString
            let detailsAttrs: [NSAttributedString.Key: Any] = [
                .font: detailsFont,
                .foregroundColor: UIColor.darkGray
            ]
            let detailsHeight = ceil(details.boundingRect(
                with: CGSize(width: textWidth, height: 80),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: detailsAttrs,
                context: nil
            ).height)

            let hasPlace = !(achievement.placeAchieved ?? "").isEmpty
            let hasDate = achievement.achieved != nil
            let metaLineHeight = metaFont.lineHeight
            let gapAfterTitle: CGFloat = 4
            let gapAfterDetails: CGFloat = 12
            let gapBetweenMeta: CGFloat = 4

            var textBlockHeight = titleHeight + gapAfterTitle + detailsHeight
            if hasPlace || hasDate { textBlockHeight += gapAfterDetails }
            if hasPlace { textBlockHeight += metaLineHeight }
            if hasPlace && hasDate { textBlockHeight += gapBetweenMeta }
            if hasDate { textBlockHeight += metaLineHeight }

            let blockHeight = max(iconSide, textBlockHeight)
            let blockTop = contentTop + max(0, (contentHeight - blockHeight) / 2)

            let iconY = blockTop + (blockHeight - iconSide) / 2
            if let iconImage = UIImage(named: achievement.iconName) ?? UIImage(named: "ach12MT") {
                iconImage.draw(in: CGRect(x: iconX, y: iconY, width: iconSide, height: iconSide))
            }

            var textY = blockTop + (blockHeight - textBlockHeight) / 2

            title.draw(
                with: CGRect(x: textX, y: textY, width: textWidth, height: titleHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: titleAttrs,
                context: nil
            )
            textY += titleHeight + gapAfterTitle

            details.draw(
                with: CGRect(x: textX, y: textY, width: textWidth, height: detailsHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: detailsAttrs,
                context: nil
            )
            textY += detailsHeight + gapAfterDetails

            if let place = achievement.placeAchieved, !place.isEmpty {
                let atAttrs: [NSAttributedString.Key: Any] = [
                    .font: metaFont,
                    .foregroundColor: UIColor.gray
                ]
                let atText = "at " as NSString
                let atWidth = atText.size(withAttributes: atAttrs).width
                atText.draw(at: CGPoint(x: textX, y: textY), withAttributes: atAttrs)

                let placeAttrs: [NSAttributedString.Key: Any] = [
                    .font: metaFont,
                    .foregroundColor: placeColor
                ]
                (place as NSString).draw(at: CGPoint(x: textX + atWidth, y: textY), withAttributes: placeAttrs)
                textY += metaLineHeight + gapBetweenMeta
            }

            if let date = achievement.achieved {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM dd, yyyy"
                let dateAttrs: [NSAttributedString.Key: Any] = [
                    .font: metaFont,
                    .foregroundColor: UIColor.gray
                ]
                ("on \(formatter.string(from: date))" as NSString)
                    .draw(at: CGPoint(x: textX, y: textY), withAttributes: dateAttrs)
            }
        }
    }

    /// Prefer named face; fall back to system with the same point size so sizing always applies.
    private static func font(_ name: String, size: CGFloat, boldFallback: Bool = false, italicFallback: Bool = false) -> UIFont {
        if let named = UIFont(name: name, size: size) {
            return named
        }
        if boldFallback {
            return .boldSystemFont(ofSize: size)
        }
        if italicFallback {
            return .italicSystemFont(ofSize: size)
        }
        return .systemFont(ofSize: size)
    }

    private static func accentColor(for iconName: String) -> UIColor {
        switch iconName.last {
        case "B":
            return UIColor(named: "BaptismsBlue") ?? UIColor(red: 0, green: 84/255, blue: 147/255, alpha: 1)
        case "I":
            return UIColor(named: "InitiatoriesOlive") ?? UIColor(red: 50/255, green: 50/255, blue: 0, alpha: 1)
        case "E":
            return UIColor.darkTangerine()
        case "S":
            return UIColor(named: "SealingsPurple") ?? UIColor(red: 104/255, green: 71/255, blue: 141/255, alpha: 1)
        case "W":
            return UIColor.iron()
        case "H":
            return UIColor(red: 0.45, green: 0.0, blue: 0.0, alpha: 1)
        case "T":
            return UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1)
        default:
            return UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1)
        }
    }

    private static func placeAccentColor(for iconName: String) -> UIColor {
        if iconName.last == "H" {
            return UIColor(red: 0.45, green: 0.0, blue: 0.0, alpha: 1)
        }
        return UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1)
    }
}

/// Text payload for the share sheet. Social apps often drop a raw String sitting next to an image;
/// `UIActivityItemSource` + link metadata makes the caption available to more destinations.
private final class AchievementShareCaptionItem: NSObject, UIActivityItemSource {
    let caption: String
    let image: UIImage

    init(caption: String, image: UIImage) {
        self.caption = caption
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        caption
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        caption
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        CelebrationBoardConfig.appDisplayName
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = caption
        // Do not set originalURL to the App Store — iOS fetches that page and shows the app icon
        // instead of the achievement graphic on first present.
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}

private final class AchievementShareImageItem: NSObject, UIActivityItemSource {
    let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }
}
