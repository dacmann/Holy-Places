//
//  SummaryView.swift
//  Holy Places
//
//  Created by Derek Cordon on 9/1/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import SwiftUI
import CoreData
import UIKit

private let fallbackQuote = "\"The supreme benefits of membership in the Church can only be realized through the exalting ordinances of the temple.\"\r\n~ Russell M. Nelson ~"

struct SummaryYearColumn {
    var attended = 0
    var uniqueTemples = 0
    var hoursWorked = 0.0
    var sealings = 0
    var endowments = 0
    var initiatories = 0
    var confirmations = 0
    var baptisms = 0
    var ordinances = 0
}

struct MostVisitedPlace: Identifiable {
    var id: String { name }
    let name: String
    let count: String
    let typeCode: String?
}

final class SummaryModel: ObservableObject {
    @Published var quote = fallbackQuote
    @Published var showHoursWorked = false
    @Published var themeRevision = 0

    @Published var templesVisited = 0
    @Published var templesTotal = 0
    @Published var historicalVisited = 0
    @Published var historicalTotal = 0
    @Published var visitorsVisited = 0
    @Published var visitorsTotal = 0

    @Published var year1Title = ""
    @Published var year2Title = ""
    @Published var year1 = SummaryYearColumn()
    @Published var year2 = SummaryYearColumn()
    @Published var lifetime = SummaryYearColumn()

    @Published var mostVisited: [MostVisitedPlace] = []

    private var yearOffset = 0
    private var quoteIndex = 0
    private var didSeedQuote = false

    func reload() {
        applyThemeColors()
        showHoursWorked = ordinanceWorker
        templesTotal = activeTemples.count + construction.count
        historicalTotal = historical.count
        visitorsTotal = visitors.count
        fetchTotals()
        advanceQuoteOnAppear()
        themeRevision += 1
    }

    func cycleQuote() {
        showNextQuote()
    }

    func shiftYear(forward: Bool) {
        if forward {
            guard yearOffset < 0 else { return }
            yearOffset += 1
        } else {
            yearOffset -= 1
        }
        refetchYearTotals()
    }

    private func context() -> NSManagedObjectContext {
        ad.persistentContainer.viewContext
    }

    private func profilePredicate() -> NSPredicate? {
        ProfileManager.shared.visitProfilePredicate()
    }

    private func combinedPredicate(_ typePredicate: NSPredicate) -> NSPredicate {
        if let profile = profilePredicate() {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, profile])
        }
        return typePredicate
    }

    private func advanceQuoteOnAppear() {
        if !didSeedQuote {
            if summaryQuotes.isEmpty {
                ad.loadSummaryQuotes()
            }
            if !summaryQuotes.isEmpty {
                quoteIndex = Int.random(in: 0..<summaryQuotes.count)
            }
            didSeedQuote = true
        }
        showNextQuote()
    }

    private func showNextQuote() {
        if summaryQuotes.isEmpty {
            quote = fallbackQuote
            return
        }
        if quoteIndex >= summaryQuotes.count {
            quoteIndex = 0
        }
        quote = summaryQuotes[quoteIndex]
        quoteIndex += 1
    }

    private func fetchTotals() {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        do {
            fetchRequest.predicate = combinedPredicate(NSPredicate(format: "type == %@", "T"))
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: true)]
            let templeVisits = try context().fetch(fetchRequest)
            applyYearTotals(from: templeVisits)

            ordinancesTotal = sealingsTotal + endowmentsTotal + initiatoriesTotal + confirmationsTotal + baptismsTotal
            lifetime.attended = attendedTotal
            lifetime.sealings = sealingsTotal
            lifetime.endowments = endowmentsTotal
            lifetime.initiatories = initiatoriesTotal
            lifetime.confirmations = confirmationsTotal
            lifetime.baptisms = baptismsTotal
            lifetime.ordinances = ordinancesTotal
            lifetime.hoursWorked = shiftHoursTotal

            fetchRequest.predicate = combinedPredicate(NSPredicate(format: "type == %@ OR type == %@", "T", "C"))
            var searchResults = try context().fetch(fetchRequest)
            templesVisited = Set(searchResults.compactMap { visit -> String? in
                guard let name = visit.holyPlace else { return nil }
                return ad.canonicalName(for: name)
            }).count

            fetchRequest.predicate = combinedPredicate(NSPredicate(format: "type == %@", "T"))
            searchResults = try context().fetch(fetchRequest)
            lifetime.uniqueTemples = Set(searchResults.compactMap { visit -> String? in
                guard let name = visit.holyPlace else { return nil }
                return ad.canonicalName(for: name)
            }).count

            fetchRequest.predicate = combinedPredicate(NSPredicate(format: "type == %@", "H"))
            searchResults = try context().fetch(fetchRequest)
            historicalVisited = Set(searchResults.compactMap { visit -> String? in
                guard let name = visit.holyPlace else { return nil }
                return ad.canonicalName(for: name)
            }).count

            fetchRequest.predicate = combinedPredicate(NSPredicate(format: "type == %@", "V"))
            searchResults = try context().fetch(fetchRequest)
            visitorsVisited = Set(searchResults.compactMap { visit -> String? in
                guard let name = visit.holyPlace else { return nil }
                return ad.canonicalName(for: name)
            }).count

            fetchMostVisited()
        } catch {
            print("Error with request: \(error)")
        }
    }

    private func refetchYearTotals() {
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        fetchRequest.predicate = combinedPredicate(NSPredicate(format: "type == %@", "T"))
        do {
            applyYearTotals(from: try context().fetch(fetchRequest))
        } catch {
            print("Error with request: \(error)")
        }
    }

    private func applyYearTotals(from visits: [Visit]) {
        var year1Stats = SummaryYearColumn()
        var year2Stats = SummaryYearColumn()
        var uniqueYear1: Set<String> = []
        var uniqueYear2: Set<String> = []

        let resolvedYear = Int(currentYear) ?? Calendar.current.component(.year, from: Date())
        let year1 = String(resolvedYear + yearOffset)
        let year2 = String(resolvedYear + yearOffset - 1)
        year1Title = yearOffset < 0 ? "<\(year1)" : year1
        year2Title = "\(year2)>"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"

        for visit in visits {
            guard let date = visit.dateVisited, let placeName = visit.holyPlace else { continue }
            let yearVisited = formatter.string(from: date)
            let countedVisit: Bool
            if excludeNonOrdinanceVisits {
                countedVisit = Int(visit.baptisms) > 0
                    || Int(visit.confirmations) > 0
                    || Int(visit.initiatories) > 0
                    || Int(visit.endowments) > 0
                    || Int(visit.sealings) > 0
            } else {
                countedVisit = true
            }

            if yearVisited == year1 {
                year1Stats.sealings += Int(visit.sealings)
                year1Stats.endowments += Int(visit.endowments)
                year1Stats.initiatories += Int(visit.initiatories)
                year1Stats.confirmations += Int(visit.confirmations)
                year1Stats.baptisms += Int(visit.baptisms)
                year1Stats.hoursWorked += visit.shiftHrs
                if countedVisit {
                    year1Stats.attended += 1
                }
                uniqueYear1.insert(ad.canonicalName(for: placeName))
            }
            if yearVisited == year2 {
                year2Stats.sealings += Int(visit.sealings)
                year2Stats.endowments += Int(visit.endowments)
                year2Stats.initiatories += Int(visit.initiatories)
                year2Stats.confirmations += Int(visit.confirmations)
                year2Stats.baptisms += Int(visit.baptisms)
                year2Stats.hoursWorked += visit.shiftHrs
                if countedVisit {
                    year2Stats.attended += 1
                }
                uniqueYear2.insert(ad.canonicalName(for: placeName))
            }
        }

        year1Stats.uniqueTemples = uniqueYear1.count
        year1Stats.ordinances = year1Stats.sealings + year1Stats.endowments + year1Stats.initiatories + year1Stats.confirmations + year1Stats.baptisms
        year2Stats.uniqueTemples = uniqueYear2.count
        year2Stats.ordinances = year2Stats.sealings + year2Stats.endowments + year2Stats.initiatories + year2Stats.confirmations + year2Stats.baptisms
        self.year1 = year1Stats
        self.year2 = year2Stats
    }

    private func fetchMostVisited() {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Visit")
        fetchRequest.predicate = profilePredicate()
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "holyPlace", ascending: true)]
        fetchRequest.propertiesToGroupBy = ["holyPlace"]

        let nameExpr = NSExpression(forKeyPath: "holyPlace")
        let countExpr = NSExpressionDescription()
        countExpr.name = "count"
        countExpr.expression = NSExpression(forFunction: "count:", arguments: [nameExpr])
        countExpr.expressionResultType = .integer64AttributeType
        fetchRequest.propertiesToFetch = ["holyPlace", countExpr]

        do {
            let grouped = try context().fetch(fetchRequest)
            let ranked = grouped.sorted {
                ($0.value(forKey: "count") as? Int ?? 0) > ($1.value(forKey: "count") as? Int ?? 0)
            }
            mostVisited = ranked.prefix(12).compactMap { row in
                guard let name = row.object(forKey: "holyPlace") as? String else { return nil }
                let count = String(format: "%@", row.object(forKey: "count") as! CVarArg)
                let canonical = ad.canonicalName(for: name)
                let typeCode = allPlaces.first(where: { $0.templeName == canonical })?.templeType
                return MostVisitedPlace(name: name, count: count, typeCode: typeCode)
            }
        } catch {
            print("Error with request: \(error)")
        }
    }
}

struct SummaryView: View {
    @ObservedObject var model: SummaryModel
    var onAchievements: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let baptismsBlue = Color("BaptismsBlue")

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            let regularWidth = horizontalSizeClass == .regular
            VStack(spacing: 0) {
                quoteHeader(regularWidth: regularWidth, landscape: landscape)
                ScrollView {
                    VStack(spacing: 28) {
                        Button("Tap for Achievements", action: onAchievements)
                            .font(.custom("Baskerville", size: regularWidth ? 22 : 19))
                            .foregroundColor(baptismsBlue)
                            .buttonStyle(.plain)
                            .padding(.top, 8)

                        if landscape {
                            HStack(alignment: .top, spacing: 56) {
                                statsGrid(regularWidth: regularWidth, showHolyPlaces: true, showTempleVisits: true, showMostVisited: false)
                                    .frame(maxWidth: geo.size.width * 0.48, alignment: .leading)
                                statsGrid(regularWidth: regularWidth, showHolyPlaces: false, showTempleVisits: false, showMostVisited: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            statsGrid(regularWidth: regularWidth, showHolyPlaces: true, showTempleVisits: true, showMostVisited: true)
                        }
                    }
                    .padding(.horizontal, regularWidth ? 28 : 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(uiColor: .systemBackground))
        }
    }

    private func quoteHeader(regularWidth: Bool, landscape: Bool) -> some View {
        let height: CGFloat
        if landscape {
            height = UIDevice.current.userInterfaceIdiom == .pad ? 132 : 100
        } else {
            height = regularWidth ? 200 : 132
        }
        return ZStack(alignment: .bottomTrailing) {
            baptismsBlue.opacity(0.85)
            Text(model.quote)
                .font(.custom("Baskerville", size: regularWidth ? 33 : 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(6)
                .padding(.horizontal, regularWidth ? 60 : 28)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Button("▷", action: model.cycleQuote)
                .font(.system(size: 17))
                .foregroundColor(Color(white: 0.94))
                .buttonStyle(.plain)
                .padding(.trailing, 10)
                .padding(.bottom, 5)
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func statsGrid(regularWidth: Bool, showHolyPlaces: Bool, showTempleVisits: Bool, showMostVisited: Bool) -> some View {
        let body = regularWidth ? 24.0 : 20.0
        let header = regularWidth ? 26.0 : 20.0
        let columns = columnMetrics(bodySize: body, headerSize: header)
        VStack(alignment: .leading, spacing: 10) {
            if showHolyPlaces {
                HStack(spacing: 8) {
                    rowLabel("Holy Places", size: header, bold: true, width: columns.label)
                    headerText("Visited", size: header)
                        .frame(maxWidth: .infinity, alignment: .center)
                    trailingHeader("Total", size: header, width: columns.total)
                }
                holyPlaceRow("Temples", visited: model.templesVisited, total: model.templesTotal, color: templeColor, size: body, columns: columns)
                holyPlaceRow("Historical Sites", visited: model.historicalVisited, total: model.historicalTotal, color: historicalColor, size: body, columns: columns)
                holyPlaceRow("Visitors' Centers", visited: model.visitorsVisited, total: model.visitorsTotal, color: visitorCenterColor, size: body, columns: columns)
            }
            if showHolyPlaces, showTempleVisits {
                Color.clear.frame(height: 12)
            }
            if showTempleVisits {
                HStack(spacing: 8) {
                    rowLabel("Temple Visits", size: header, bold: true, width: columns.label)
                    yearButton(model.year1Title, forward: true, size: header)
                        .frame(maxWidth: .infinity, alignment: .center)
                    yearButton(model.year2Title, forward: false, size: header)
                        .frame(maxWidth: .infinity, alignment: .center)
                    trailingHeader("Total", size: header, width: columns.total)
                }
                visitRow("Attended", year1: "\(model.year1.attended)", year2: "\(model.year2.attended)", total: "\(model.lifetime.attended)", color: nil, size: body, columns: columns)
                visitRow("Unique Temples", year1: "\(model.year1.uniqueTemples)", year2: "\(model.year2.uniqueTemples)", total: "\(model.lifetime.uniqueTemples)", color: templeColor, size: body, columns: columns)
                if model.showHoursWorked {
                    visitRow("Hours Worked", year1: model.year1.hoursWorked.description, year2: model.year2.hoursWorked.description, total: model.lifetime.hoursWorked.description, color: hoursWorkedColor, size: body, columns: columns)
                }
                visitRow("Sealings", year1: "\(model.year1.sealings)", year2: "\(model.year2.sealings)", total: "\(model.lifetime.sealings)", color: sealingsColor, size: body, columns: columns)
                visitRow("Endowments", year1: "\(model.year1.endowments)", year2: "\(model.year2.endowments)", total: "\(model.lifetime.endowments)", color: endowmentsColor, size: body, columns: columns)
                visitRow("Initiatories", year1: "\(model.year1.initiatories)", year2: "\(model.year2.initiatories)", total: "\(model.lifetime.initiatories)", color: initiatoriesColor, size: body, columns: columns)
                visitRow("Confirmations", year1: "\(model.year1.confirmations)", year2: "\(model.year2.confirmations)", total: "\(model.lifetime.confirmations)", color: confirmationsColor, size: body, columns: columns)
                visitRow("Baptisms", year1: "\(model.year1.baptisms)", year2: "\(model.year2.baptisms)", total: "\(model.lifetime.baptisms)", color: baptismsColor, size: body, columns: columns)
                visitRow("Total Ordinances", year1: "\(model.year1.ordinances)", year2: "\(model.year2.ordinances)", total: "\(model.lifetime.ordinances)", color: nil, size: body, columns: columns)
            }
            if showMostVisited, showHolyPlaces || showTempleVisits {
                Color.clear.frame(height: 12)
            }
            if showMostVisited {
                HStack(spacing: 8) {
                    headerText("Most Visited - Top 12", size: header)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    trailingHeader("Visits", size: header, width: columns.total)
                }
                ForEach(model.mostVisited) { place in
                    HStack(spacing: 8) {
                        Text(place.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(place.count)
                            .frame(width: columns.total, alignment: .trailing)
                    }
                    .font(.custom("Baskerville", size: body))
                    .foregroundColor(Color(uiColor: colorForPlaceTypeCode(place.typeCode)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func columnMetrics(bodySize: CGFloat, headerSize: CGFloat) -> (label: CGFloat, total: CGFloat) {
        let bodyFont = UIFont(name: "Baskerville", size: bodySize) ?? .systemFont(ofSize: bodySize)
        let headerFont = UIFont(name: "Baskerville-SemiBold", size: headerSize) ?? .boldSystemFont(ofSize: headerSize)
        func width(_ text: String, _ font: UIFont) -> CGFloat {
            ceil((text as NSString).size(withAttributes: [.font: font]).width)
        }
        let labels = [
            "Holy Places", "Temple Visits", "Visitors' Centers", "Historical Sites",
            "Total Ordinances", "Unique Temples", "Hours Worked", "Confirmations",
            "Initiatories", "Endowments"
        ]
        let label = labels.map { max(width($0, bodyFont), width($0, headerFont)) }.max() ?? 130
        let total = max(width("Total", headerFont), width("Visits", headerFont), width("0000.0", bodyFont))
        return (label, total)
    }

    private func holyPlaceRow(_ title: String, visited: Int, total: Int, color: UIColor, size: CGFloat, columns: (label: CGFloat, total: CGFloat)) -> some View {
        HStack(spacing: 8) {
            rowLabel(title, size: size, width: columns.label)
            Text("\(visited)")
                .frame(maxWidth: .infinity, alignment: .center)
            trailingValue("\(total)", width: columns.total)
        }
        .font(.custom("Baskerville", size: size))
        .foregroundColor(Color(uiColor: color))
    }

    private func visitRow(_ title: String, year1: String, year2: String, total: String, color: UIColor?, size: CGFloat, columns: (label: CGFloat, total: CGFloat)) -> some View {
        let tint = color.map { Color(uiColor: $0) } ?? Color.primary
        return HStack(spacing: 8) {
            rowLabel(title, size: size, width: columns.label)
            Text(year1)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(year2)
                .frame(maxWidth: .infinity, alignment: .center)
            trailingValue(total, width: columns.total)
        }
        .font(.custom("Baskerville", size: size))
        .foregroundColor(tint)
    }

    private func rowLabel(_ title: String, size: CGFloat, bold: Bool = false, width: CGFloat) -> some View {
        Text(title)
            .font(.custom(bold ? "Baskerville-SemiBold" : "Baskerville", size: size))
            .lineLimit(1)
            .frame(width: width, alignment: .leading)
    }

    private func trailingHeader(_ title: String, size: CGFloat, width: CGFloat) -> some View {
        headerText(title, size: size)
            .frame(width: width, alignment: .trailing)
    }

    private func trailingValue(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .frame(width: width, alignment: .trailing)
    }

    private func headerText(_ title: String, size: CGFloat) -> some View {
        Text(title)
            .font(.custom("Baskerville-SemiBold", size: size))
            .foregroundColor(.primary)
    }

    private func yearButton(_ title: String, forward: Bool, size: CGFloat) -> some View {
        Button(title) {
            model.shiftYear(forward: forward)
        }
        .font(.custom("Baskerville", size: size))
        .foregroundColor(baptismsBlue)
        .buttonStyle(.plain)
    }
}
