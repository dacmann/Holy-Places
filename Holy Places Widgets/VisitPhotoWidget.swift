//
//  VisitPhotoWidget.swift
//  Holy Places Widgets
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct VisitPhotoEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let imageSource: ImageSource
}

// MARK: - Timeline Provider

struct VisitPhotoProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> VisitPhotoEntry {
        VisitPhotoEntry(date: Date(), data: .placeholder, imageSource: .visitPhoto)
    }
    
    func snapshot(for configuration: VisitWidgetConfigurationIntent, in context: Context) async -> VisitPhotoEntry {
        let data = WidgetData.load()
        // Auto-switch to place images if no visit photos available
        let imageSource = data.visitPhotos.isEmpty ? .placeImage : configuration.imageSource
        return VisitPhotoEntry(date: Date(), data: data, imageSource: imageSource)
    }
    
    func timeline(for configuration: VisitWidgetConfigurationIntent, in context: Context) async -> Timeline<VisitPhotoEntry> {
        let data = WidgetData.load()
        // Auto-switch to place images if no visit photos available
        let imageSource = data.visitPhotos.isEmpty ? .placeImage : configuration.imageSource
        let entry = VisitPhotoEntry(date: Date(), data: data, imageSource: imageSource)
        
        // Calculate next midnight for daily refresh
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        return timeline
    }
}

// MARK: - Widget View

struct LargeVisitWidgetView: View {
    let entry: VisitPhotoEntry
    
    private func widgetURL(for visitEntry: VisitWidgetData?, sourceType: ImageSourceType) -> URL {
        guard let visitEntry = visitEntry else {
            return URL(string: "net.dacworld.holyplaces://summary")!
        }
        // Visit photos with object ID: navigate to that visit (use query param to avoid path splitting on slashes in URI)
        if sourceType == .visitPhoto, let objectID = visitEntry.visitObjectID, !objectID.isEmpty {
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-_.~")
            let encoded = objectID.addingPercentEncoding(withAllowedCharacters: allowed) ?? objectID
            return URL(string: "net.dacworld.holyplaces://visit?id=\(encoded)")!
        }
        // Place images or no object ID: navigate to place
        let encodedPlace = visitEntry.placeName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return URL(string: "net.dacworld.holyplaces://place/\(encodedPlace)")!
    }
    
    var body: some View {
        let sourceType: ImageSourceType = entry.imageSource == .visitPhoto ? .visitPhoto : .placeImage
        let visitEntry = entry.data.imageForCurrentDay(source: sourceType)
        
        // Content with fixed app icon overlay
        ZStack(alignment: .topLeading) {
            // Main content
            VStack(spacing: 8) {
                // Place name at top (centered, with extra padding to avoid logo)
                if let visitEntry = visitEntry {
                    Text(visitEntry.placeName)
                        .font(.custom("Baskerville-Bold", size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 50)  // Extra padding to avoid logo
                        .padding(.trailing, 50)
                        .padding(.top, 12)
                }
                
                // Photo with minimal spacing
                if let visitEntry = visitEntry,
                   let uiImage = UIImage(data: visitEntry.picture) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                } else {
                    // Placeholder when no images available
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No photos available")
                            .font(.custom("Baskerville", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 4)
                }
                
                // Date at bottom
                if let visitEntry = visitEntry {
                    let dateText = visitEntry.date.isEmpty || visitEntry.date == "Not yet visited" 
                        ? "Not yet visited" 
                        : "Visited on \(visitEntry.date)"
                    Text(dateText)
                        .font(.custom("Baskerville", size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // App icon fixed in upper left corner of widget container
            VStack {
                HStack {
                    Image("holyPlacesIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .white.opacity(0.6), radius: 4)
                    Spacer()
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(widgetURL(for: visitEntry, sourceType: sourceType))
    }
}

// MARK: - Widget Definition

struct VisitPhotoWidget: Widget {
    let kind = "VisitPhotoWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: VisitWidgetConfigurationIntent.self,
            provider: VisitPhotoProvider()
        ) { entry in
            LargeVisitWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Photos")
        .description("Shows a photo from your temple visits or a daily-rotating holy place image.")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    VisitPhotoWidget()
} timeline: {
    VisitPhotoEntry(date: .now, data: .placeholder, imageSource: .visitPhoto)
}
