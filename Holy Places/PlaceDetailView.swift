//
//  PlaceDetailView.swift
//  Holy Places
//
//  Created by Derek Cordon on 8/26/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import CoreData
import UIKit

struct PlaceDetailActions {
    var openImage: (UIImage) -> Void = { _ in }
    var openURL: (String) -> Void = { _ in }
    var openRecordVisit: () -> Void = {}
    var openNavigationOptions: () -> Void = {}
    var swipePlace: (Int) -> Void = { _ in }
}

final class PlaceDetailModel: ObservableObject {
    @Published var place: Temple?
    @Published var visitCount = 0
    @Published var sealings = 0
    @Published var endowments = 0
    @Published var initiatories = 0
    @Published var confirmations = 0
    @Published var baptisms = 0
    @Published var hoursWorked = 0.0
    @Published var images: [UIImage] = []
    @Published var selectedImageIndex = 0
    @Published var imagesLoaded = false

    private var loadToken = UUID()
    private var lastVisitPictureCount = -1

    var isActiveTemple: Bool { place?.templeType == "T" }

    var nameColor: Color {
        Color(uiColor: colorForPlaceTypeCode(place?.templeType))
    }

    var addressText: String {
        guard let place = place else { return "" }
        return [place.templeAddress, place.templeCityState, place.templeCountry]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var ordinalText: String? {
        guard let place = place, ["T", "C", "A"].contains(place.templeType) else { return nil }
        return place.templeSnippet.components(separatedBy: " - ").first
    }

    var snippetText: String {
        guard let place = place else { return "" }
        if let ordinal = ordinalText {
            return place.templeSnippet.replacingOccurrences(of: "\(ordinal) - ", with: "")
        }
        return place.templeSnippet
    }

    var websiteButtonTitle: String {
        place?.templeType == "T" ? "Schedule" : "Web Site"
    }

    var hasAnyOrdinances: Bool {
        sealings + endowments + initiatories + confirmations + baptisms > 0
    }

    func load(place: Temple?) {
        let token = UUID()
        loadToken = token
        self.place = place
        selectedImageIndex = 0
        images = []
        imagesLoaded = false
        visitCount = 0
        sealings = 0
        endowments = 0
        initiatories = 0
        confirmations = 0
        baptisms = 0
        hoursWorked = 0
        lastVisitPictureCount = -1
        guard let place = place else { return }
        loadVisits(for: place, token: token)
        loadImages(for: place, token: token)
    }

    func refreshIfNeeded(reloadImages: Bool = false) {
        guard let place = place else { return }
        loadVisits(for: place, token: loadToken)
        if reloadImages {
            loadImages(for: place, token: loadToken, forceVisitPhotos: true)
        }
    }

    private func context() -> NSManagedObjectContext {
        ad.persistentContainer.viewContext
    }

    private func placeNamePredicate(for place: Temple) -> NSPredicate {
        var names = [place.templeName]
        names.append(contentsOf: place.oldNames)
        names = Array(Set(names))
        if names.count == 1 {
            return NSPredicate(format: "holyPlace == %@", names[0])
        }
        return NSPredicate(format: "holyPlace IN %@", names)
    }

    private func visitPredicates(for place: Temple, picturesOnly: Bool = false) -> NSCompoundPredicate {
        var predicates: [NSPredicate] = [placeNamePredicate(for: place)]
        if picturesOnly {
            predicates.append(NSPredicate(format: "picture != nil"))
        }
        if let profile = ProfileManager.shared.visitProfilePredicate() {
            predicates.append(profile)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func loadVisits(for place: Temple, token: UUID) {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = visitPredicates(for: place)
        do {
            let visits = try context().fetch(request)
            guard token == loadToken else { return }
            visitCount = visits.count
            if place.templeType == "T" {
                var sealingsSum = 0
                var endowmentsSum = 0
                var initiatoriesSum = 0
                var confirmationsSum = 0
                var baptismsSum = 0
                var hoursSum = 0.0
                for visit in visits {
                    sealingsSum += Int(visit.sealings)
                    endowmentsSum += Int(visit.endowments)
                    initiatoriesSum += Int(visit.initiatories)
                    confirmationsSum += Int(visit.confirmations)
                    baptismsSum += Int(visit.baptisms)
                    hoursSum += visit.shiftHrs
                }
                sealings = sealingsSum
                endowments = endowmentsSum
                initiatories = initiatoriesSum
                confirmations = confirmationsSum
                baptisms = baptismsSum
                hoursWorked = hoursSum
            }
        } catch {
            print("Error loading place visits: \(error)")
        }
    }

    private func loadImages(for place: Temple, token: UUID, forceVisitPhotos: Bool = false) {
        if let stock = cachedStockImage(for: place) {
            guard token == loadToken else { return }
            if images.isEmpty {
                images = [stock]
                imagesLoaded = true
            }
            loadVisitPhotos(for: place, token: token, startingWithStock: true, force: forceVisitPhotos)
        } else {
            downloadStockImage(for: place, token: token, forceVisitPhotos: forceVisitPhotos)
        }
    }

    private func cachedStockImage(for place: Temple) -> UIImage? {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", place.templeName)
        do {
            let results = try context().fetch(request)
            if let data = results.first?.pictureData {
                return UIImage(data: data)
            }
        } catch {
            print("Error loading saved place image: \(error)")
        }
        return nil
    }

    private func downloadStockImage(for place: Temple, token: UUID, forceVisitPhotos: Bool) {
        guard let url = URL(string: place.templePictureURL), !place.templePictureURL.isEmpty else {
            imagesLoaded = true
            loadVisitPhotos(for: place, token: token, startingWithStock: false, force: forceVisitPhotos)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard
                let self = self,
                token == self.loadToken,
                let http = response as? HTTPURLResponse, http.statusCode == 200,
                let mime = response?.mimeType, mime.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async {
                    self?.imagesLoaded = true
                    self?.loadVisitPhotos(for: place, token: token, startingWithStock: false, force: forceVisitPhotos)
                }
                return
            }
            DispatchQueue.main.async {
                guard token == self.loadToken else { return }
                self.saveStockImage(data, for: place)
                self.images = [image]
                self.imagesLoaded = true
                self.loadVisitPhotos(for: place, token: token, startingWithStock: true, force: forceVisitPhotos)
            }
        }.resume()
    }

    private func saveStockImage(_ data: Data, for place: Temple) {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", place.templeName)
        do {
            let results = try context().fetch(request)
            if let stored = results.first {
                stored.pictureData = data
                try context().save()
            }
        } catch {
            print("Could not save place picture \(error)")
        }
    }

    private func loadVisitPhotos(for place: Temple, token: UUID, startingWithStock: Bool, force: Bool) {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = visitPredicates(for: place, picturesOnly: true)
        request.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        do {
            let pictureVisits = try context().fetch(request)
            guard token == loadToken else { return }
            if !force, pictureVisits.count == lastVisitPictureCount {
                imagesLoaded = true
                return
            }
            lastVisitPictureCount = pictureVisits.count
            let photos: [(Date, Data)] = pictureVisits.compactMap { visit in
                guard let data = visit.picture, let date = visit.dateVisited else { return nil }
                return (date, data)
            }
            DispatchQueue.global(qos: .default).async {
                var processed: [(Date, UIImage)] = []
                for (date, data) in photos.prefix(20) {
                    guard var image = UIImage(data: data) else { continue }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, MMMM dd yyyy"
                    let point = CGPoint(x: 60, y: image.size.height - (image.size.height / 16) - 40)
                    if let dated = Self.textToImage(drawText: formatter.string(from: date) as NSString, inImage: image, atPoint: point) {
                        image = dated
                    }
                    if image.size.height > 2000 {
                        let scale: CGFloat = image.size.height > 3000 ? 3 : 2
                        if let small = Self.scaledImage(image, to: CGSize(width: image.size.width / scale, height: image.size.height / scale)) {
                            processed.append((date, small))
                        }
                    } else {
                        processed.append((date, image))
                    }
                }
                let sorted = processed.sorted { $0.0 > $1.0 }.map { $0.1 }
                DispatchQueue.main.async {
                    guard token == self.loadToken else { return }
                    let keepIndex = self.selectedImageIndex
                    if startingWithStock, let stock = self.images.first {
                        self.images = [stock] + sorted
                    } else {
                        self.images = sorted
                    }
                    self.imagesLoaded = true
                    if keepIndex < self.images.count {
                        self.selectedImageIndex = keepIndex
                    } else {
                        self.selectedImageIndex = 0
                    }
                }
            }
        } catch {
            print("Error loading visit pictures: \(error)")
        }
    }

    private static func scaledImage(_ image: UIImage, to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private static func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage? {
        let textFont = UIFont(name: "Baskerville", size: image.size.height / 20) ?? .systemFont(ofSize: image.size.height / 20)
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.white
        ]
        text.draw(in: CGRect(origin: point, size: image.size), withAttributes: attributes)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

struct PlaceDetailView: View {
    @ObservedObject var model: PlaceDetailModel
    var actions: PlaceDetailActions
    @State private var showOrdinancePopup = false

    private let baptismsBlue = Color("BaptismsBlue")
    private let titleFont = Font.custom("Baskerville", size: 22)
    private let bodyFont = Font.custom("Baskerville", size: 17)
    private let buttonFont = Font.custom("Baskerville", size: 20)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    photoPager
                        .frame(maxWidth: .infinity)
                        .frame(height: photoHeight(in: geo))
                        .clipped()
                    metaRow
                        .padding(.top, 8)
                    nameSection
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    detailsAndActions
                        .padding(.bottom, 8)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .contentShape(Rectangle())
                .simultaneousGesture(placeSwipeGesture)
                if showOrdinancePopup {
                    ordinanceOverlay
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .onChange(of: model.place?.templeName) {
            showOrdinancePopup = false
        }
    }

    private var placeSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width),
                      abs(value.translation.height) > 40 else { return }
                actions.swipePlace(value.translation.height < 0 ? 1 : -1)
            }
    }

    private func photoHeight(in geo: GeometryProxy) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = geo.size.width > geo.size.height
        if isPad && isLandscape {
            return geo.size.height * 0.70
        }
        return geo.size.height * (isPad ? 0.50 : 0.38)
    }

    private var photoPager: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            if model.images.isEmpty {
                if model.imagesLoaded {
                    Color.clear
                } else {
                    ProgressView()
                }
            } else {
                TabView(selection: $model.selectedImageIndex) {
                    ForEach(model.images.indices, id: \.self) { index in
                        Image(uiImage: model.images[index])
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                            .onTapGesture {
                                actions.openImage(model.images[index])
                            }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: model.images.count > 1 ? .always : .never))
                .background(Color(uiColor: .systemBackground))
            }
        }
    }

    private var metaRow: some View {
        HStack(alignment: .center) {
            if let code = model.place?.fhCode, !code.isEmpty {
                Text(code)
                    .font(bodyFont)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if model.visitCount > 0 {
                if model.isActiveTemple {
                    Button {
                        showOrdinancePopup = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Visits: \(model.visitCount)")
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .font(bodyFont)
                        .foregroundColor(baptismsBlue)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Visits: \(model.visitCount)")
                        .font(bodyFont)
                        .foregroundColor(baptismsBlue)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: metaRowHeight, alignment: .center)
    }

    private var metaRowHeight: CGFloat {
        ceil((UIFont(name: "Baskerville", size: 17) ?? .systemFont(ofSize: 17)).lineHeight)
    }

    private var nameSection: some View {
        GeometryReader { geo in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let nameText = model.place?.templeName ?? ""
            let nameWidth = max(geo.size.width - 16, 1)
            let nameLayout = Self.nameFontLayout(
                text: nameText,
                fontName: "Baskerville",
                width: nameWidth,
                maxSize: isPad ? 48 : 38,
                minSize: isPad ? 34 : 28
            )
            let ordinalHeight: CGFloat = (model.ordinalText?.isEmpty == false) ? 24 : 0
            let snippetWidth = max(geo.size.width - 32, 1)
            let snippetHeight = max(geo.size.height - nameLayout.height - ordinalHeight - 16, 20)
            let snippetSize = model.snippetText.isEmpty
                ? 17
                : Self.fontSizeToFitRect(
                    text: model.snippetText,
                    fontName: "Baskerville",
                    width: snippetWidth,
                    height: snippetHeight,
                    maxSize: isPad ? 30 : 24,
                    minSize: 16
                )

            VStack(spacing: 6) {
                Text(nameText)
                    .font(.custom("Baskerville", size: nameLayout.size))
                    .foregroundColor(model.nameColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                if let ordinal = model.ordinalText, !ordinal.isEmpty {
                    Text(ordinal)
                        .font(.custom("Baskerville", size: min(20, nameLayout.size * 0.55)))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !model.snippetText.isEmpty {
                    Text(model.snippetText)
                        .font(.custom("Baskerville", size: snippetSize))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, 12)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 8)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Keep the name large. Wrap to a second line before shrinking; only shrink if two lines still overflow.
    private static func nameFontLayout(
        text: String,
        fontName: String,
        width: CGFloat,
        maxSize: CGFloat,
        minSize: CGFloat,
        maxLines: Int = 2
    ) -> (size: CGFloat, height: CGFloat) {
        func font(at size: CGFloat) -> UIFont {
            UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size)
        }
        func oneLineWidth(_ size: CGFloat) -> CGFloat {
            (text as NSString).size(withAttributes: [.font: font(at: size)]).width
        }
        func wrappedHeight(_ size: CGFloat) -> CGFloat {
            (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font(at: size)],
                context: nil
            ).height
        }

        guard !text.isEmpty, width > 0 else {
            return (minSize, font(at: minSize).lineHeight)
        }
        if oneLineWidth(maxSize) <= width {
            return (maxSize, font(at: maxSize).lineHeight)
        }
        var size = maxSize
        while size >= minSize {
            let lineHeight = font(at: size).lineHeight
            let maxHeight = lineHeight * CGFloat(maxLines) + 1
            let height = wrappedHeight(size)
            if height <= maxHeight {
                return (size, min(max(height, lineHeight), maxHeight))
            }
            size -= 0.5
        }
        let lineHeight = font(at: minSize).lineHeight
        return (minSize, lineHeight * CGFloat(maxLines))
    }

    private static func fontSizeToFitRect(
        text: String,
        fontName: String,
        width: CGFloat,
        height: CGFloat,
        maxSize: CGFloat,
        minSize: CGFloat
    ) -> CGFloat {
        guard !text.isEmpty, width > 0, height > 0 else { return minSize }
        var size = maxSize
        while size > minSize {
            let font = UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size)
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            if rect.height <= height {
                return size
            }
            size -= 0.5
        }
        return minSize
    }

    private var detailsAndActions: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if !model.addressText.isEmpty {
                    Button(action: actions.openNavigationOptions) {
                        Text(model.addressText)
                            .font(buttonFont)
                            .foregroundColor(baptismsBlue)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                }
                if let phone = model.place?.templePhone, !phone.isEmpty {
                    if let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                        Link(phone, destination: url)
                            .font(buttonFont)
                            .foregroundColor(baptismsBlue)
                    } else {
                        Text(phone)
                            .font(buttonFont)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                if let info = model.place?.infoURL, !info.isEmpty {
                    actionButton("More Info") { actions.openURL(info) }
                }
                if let site = model.place?.templeSiteURL, !site.isEmpty {
                    actionButton(model.websiteButtonTitle) { actions.openURL(site) }
                }
                actionButton("Record Visit", action: actions.openRecordVisit)
            }
            .frame(width: 120)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(buttonFont)
                .foregroundColor(baptismsBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var ordinanceOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { showOrdinancePopup = false }
            VStack(alignment: .leading, spacing: 10) {
                Text(model.place?.templeName ?? "")
                    .font(titleFont)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                Text("Visits: \(model.visitCount)")
                    .font(bodyFont)
                    .frame(maxWidth: .infinity)
                if model.isActiveTemple {
                    if model.hasAnyOrdinances {
                        ordinanceRow("Sealings", model.sealings, sealingsColor)
                        ordinanceRow("Endowments", model.endowments, endowmentsColor)
                        ordinanceRow("Initiatories", model.initiatories, initiatoriesColor)
                        ordinanceRow("Confirmations", model.confirmations, confirmationsColor)
                        ordinanceRow("Baptisms", model.baptisms, baptismsColor)
                    } else {
                        Text("No ordinances recorded")
                            .font(bodyFont)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    if ordinanceWorker, model.hoursWorked > 0 {
                        hoursRow("Hours Worked", hoursText, hoursWorkedColor)
                    }
                }
                Button("Done") { showOrdinancePopup = false }
                    .font(buttonFont)
                    .foregroundColor(baptismsBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
            .padding(24)
        }
    }

    private var hoursText: String {
        if model.hoursWorked.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(model.hoursWorked))
        }
        return String(format: "%g", model.hoursWorked)
    }

    @ViewBuilder
    private func ordinanceRow(_ title: String, _ count: Int, _ color: UIColor) -> some View {
        if count > 0 {
            HStack {
                Text(title)
                Spacer()
                Text("\(count)")
            }
            .font(bodyFont)
            .foregroundColor(Color(uiColor: color))
        }
    }

    private func hoursRow(_ title: String, _ count: String, _ color: UIColor) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(count)
        }
        .font(bodyFont)
        .foregroundColor(Color(uiColor: color))
    }
}
