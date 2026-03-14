//
//  WidgetData.swift
//  Holy Places Widgets
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import Foundation
import SwiftUI

// Image source option for widget configuration
enum ImageSourceType: String, CaseIterable {
    case visitPhoto = "My Visit Photos"
    case placeImage = "Place Images"
}

// Individual entry for large widget
struct VisitWidgetData {
    let picture: Data
    let placeName: String
    let date: String  // Empty for place images
    let visitObjectID: String?  // Core Data object ID for visit photos; nil for place images
}

struct WidgetData {
    // Large widget - both arrays available, user chooses via configuration
    let visitPhotos: [VisitWidgetData]   // User's personal visit photos
    let placeImages: [VisitWidgetData]   // Official place images
    
    // Medium widget
    let achievementIcon: String
    let achievementName: String
    let goalProgress: String
    
    // Small widget - array of quotes for daily rotation
    let quotes: [String]
    
    // Placeholder data for widget gallery preview
    static var placeholder: WidgetData {
        WidgetData(
            visitPhotos: [],
            placeImages: [],
            achievementIcon: "ach10T",
            achievementName: "10 Temples Visited",
            goalProgress: "0 of 12 Visits",
            quotes: ["The temple is a place of peace."]
        )
    }
    
    static func load() -> WidgetData {
        let defaults = UserDefaults(suiteName: "group.net.dacworld.holyplaces")
        
        // Decode visit photos from JSON with base64 encoded pictures
        var visitPhotos: [VisitWidgetData] = []
        if let data = defaults?.data(forKey: "widgetVisitPhotos"),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                if let pictureBase64 = item["picture"] as? String,
                   let pictureData = Data(base64Encoded: pictureBase64),
                   let placeName = item["placeName"] as? String,
                   let date = item["date"] as? String {
                    let visitObjectID = item["visitObjectID"] as? String
                    visitPhotos.append(VisitWidgetData(picture: pictureData, placeName: placeName, date: date, visitObjectID: visitObjectID))
                }
            }
        }
        
        // Decode place images from JSON with base64 encoded pictures (no visitObjectID)
        var placeImages: [VisitWidgetData] = []
        if let data = defaults?.data(forKey: "widgetPlaceImages"),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray {
                if let pictureBase64 = item["picture"] as? String,
                   let pictureData = Data(base64Encoded: pictureBase64),
                   let placeName = item["placeName"] as? String,
                   let date = item["date"] as? String {
                    placeImages.append(VisitWidgetData(picture: pictureData, placeName: placeName, date: date, visitObjectID: nil))
                }
            }
        }
        
        // Load quotes array for daily rotation
        var quotes: [String] = []
        if let data = defaults?.data(forKey: "widgetQuotes"),
           let decodedQuotes = try? JSONDecoder().decode([String].self, from: data) {
            quotes = decodedQuotes
        }
        // Fallback to old single quote key for backwards compatibility
        if quotes.isEmpty, let singleQuote = defaults?.string(forKey: "widgetQuote") {
            quotes = [singleQuote]
        }
        if quotes.isEmpty {
            quotes = ["The temple is a place of peace."]
        }
        
        return WidgetData(
            visitPhotos: visitPhotos,
            placeImages: placeImages,
            achievementIcon: defaults?.string(forKey: "widgetAchievementIcon") ?? "ach10T",
            achievementName: defaults?.string(forKey: "widgetAchievementName") ?? "",
            goalProgress: defaults?.string(forKey: "goalProgress") ?? "SET GOAL",
            quotes: quotes
        )
    }
    
    // Get image for current day (cycles daily through selected source)
    func imageForCurrentDay(source: ImageSourceType) -> VisitWidgetData? {
        let images = source == .visitPhoto ? visitPhotos : placeImages
        guard !images.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % images.count
        return images[index]
    }
    
    // Get quote for current day (cycles daily through quotes)
    func quoteForCurrentDay() -> String {
        // Multiple fallback layers for safety
        guard !quotes.isEmpty else { return "The temple is a place of peace." }
        
        // Safe calendar calculation with fallback
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        guard dayOfYear > 0 else { return quotes.first ?? "The temple is a place of peace." }
        
        // Safe index calculation
        let index = (dayOfYear - 1) % quotes.count
        guard index >= 0 && index < quotes.count else { return quotes.first ?? "The temple is a place of peace." }
        
        let quote = quotes[index]
        // Ensure quote is not empty
        return quote.isEmpty ? "The temple is a place of peace." : quote
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
