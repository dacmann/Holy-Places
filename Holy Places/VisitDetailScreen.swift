//
//  VisitDetailScreen.swift
//  Holy Places
//
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import AppIntents
import CoreData
import SwiftUI
import UIKit

struct VisitDetailScreen: View {
    var visit: Visit
    var onEdit: () -> Void
    var onPhoto: (UIImage) -> Void
    var onSwipe: (Int) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }
    private var nameSize: CGFloat { isRegularWidth ? 30 : 26 }
    private var dateSize: CGFloat { isRegularWidth ? 28 : 24 }
    private var ordinanceSize: CGFloat { isRegularWidth ? 22 : 18 }

    var body: some View {
        GeometryReader { geo in
            let photoMax = geo.size.height * (isRegularWidth ? 0.65 : 0.50)
            let commentText = visit.comments ?? ""
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Text(visit.holyPlace ?? "")
                        .font(.custom("Baskerville", size: nameSize))
                        .foregroundStyle(Color(uiColor: nameColor))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, visit.isFavorite ? 44 : 0)

                    Text(dateText)
                        .font(.custom("Baskerville", size: dateSize))
                        .foregroundStyle(Color(uiColor: .label))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color(white: 0.33))
                        .frame(height: 1)
                        .padding(.horizontal, -1)

                    if !ordinanceItems.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(ordinanceItems) { item in
                                Text(item.text)
                                    .font(.custom("Baskerville", size: ordinanceSize))
                                    .foregroundStyle(Color(uiColor: item.color))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    ScrollView {
                        Text(commentText)
                            .font(.custom("Baskerville", size: 18))
                            .foregroundStyle(Color(uiColor: .label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: .infinity)

                    if let image = displayImage {
                        visitPhoto(image, height: photoMax)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)

                if visit.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(uiColor: .darkTangerine()))
                        .frame(width: 40, height: 40)
                        .padding(.top, 4)
                        .padding(.trailing, 10)
                        .accessibilityLabel("Favorite")
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(swipeGesture)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Visit Details")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBarWhenCompact()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Visit Details")
                    .font(.custom("Baskerville", size: 20))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.custom("Baskerville", size: 17))
                }
                .accessibilityLabel("Edit")
            }
        }
        .modifier(SiriVisitAnnotation(visit: visit))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width),
                      abs(value.translation.height) > 40 else { return }
                onSwipe(value.translation.height < 0 ? 1 : -1)
            }
    }

    private var dateText: String {
        guard let date = visit.dateVisited else { return "(no date)" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd yyyy"
        return formatter.string(from: date)
    }

    private var nameColor: UIColor {
        switch visit.type {
        case "T": return templeColor
        case "H": return historicalColor
        case "C": return constructionColor
        case "V": return visitorCenterColor
        default: return defaultColor
        }
    }

    private var ordinanceItems: [VisitOrdinanceLine] {
        guard visit.type == "T" else { return [] }
        var items: [VisitOrdinanceLine] = []
        if visit.sealings > 0 {
            items.append(VisitOrdinanceLine(text: "Sealings: \(visit.sealings.description)", color: sealingsColor))
        }
        if visit.endowments > 0 {
            items.append(VisitOrdinanceLine(text: "Endowments: \(visit.endowments.description)", color: endowmentsColor))
        }
        if visit.initiatories > 0 {
            items.append(VisitOrdinanceLine(text: "Initiatories: \(visit.initiatories.description)", color: initiatoriesColor))
        }
        if visit.confirmations > 0 {
            items.append(VisitOrdinanceLine(text: "Confirmations: \(visit.confirmations.description)", color: confirmationsColor))
        }
        if visit.baptisms > 0 {
            items.append(VisitOrdinanceLine(text: "Baptisms: \(visit.baptisms.description)", color: baptismsColor))
        }
        if visit.shiftHrs > 0 {
            items.append(VisitOrdinanceLine(text: "Hours Worked: \(visit.shiftHrs.description)", color: hoursWorkedColor))
        }
        return items
    }

    private var displayImage: UIImage? {
        if let imageData = visit.picture, let image = UIImage(data: imageData) {
            return image
        }
        if showStockPlaceImageOnVisits, let fallback = placeFallbackImage(for: visit) {
            return fallback
        }
        return nil
    }

    private func visitPhoto(_ image: UIImage, height: CGFloat) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Rectangle())
            .onTapGesture { onPhoto(image) }
            .accessibilityLabel("Visit photo")
    }

    private func placeFallbackImage(for visit: Visit) -> UIImage? {
        guard let holyPlace = visit.holyPlace else { return nil }
        let context = ad.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", holyPlace)
        if let results = try? context.fetch(fetchRequest), let place = results.first {
            if let data = place.pictureData { return UIImage(data: data as Data) }
            return nil
        }
        let allFetch: NSFetchRequest<Place> = Place.fetchRequest()
        guard let places = try? context.fetch(allFetch) else { return nil }
        for place in places {
            guard let changes = place.value(forKey: "nameChanges") as? [NameChange] else { continue }
            if let change = changes.first(where: { $0.oldName == holyPlace }) {
                if let cutoff = change.changeDate,
                   let visitDate = visit.dateVisited, visitDate < cutoff,
                   let oldData = change.oldImageData {
                    return UIImage(data: oldData)
                }
                if let data = place.pictureData { return UIImage(data: data as Data) }
            }
        }
        return nil
    }
}

struct VisitOrdinanceLine: Identifiable {
    var id: String { text }
    var text: String
    var color: UIColor
}

struct SiriVisitAnnotation: ViewModifier {
    var visit: Visit

    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            SiriAnnotatedVisit(visit: visit, content: content)
        } else {
            content
        }
    }
}

@available(iOS 27.0, *)
private struct SiriAnnotatedVisit<Content: View>: View {
    var visit: Visit
    var content: Content

    var body: some View {
        content.appEntityIdentifier(VisitEntity.identifier(for: visit))
    }
}
