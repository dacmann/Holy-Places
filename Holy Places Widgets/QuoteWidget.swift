//
//  QuoteWidget.swift
//  Holy Places Widgets
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct QuoteEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        // Always load real data (like other widgets) to ensure quotes appear on device
        let data = WidgetData.load()
        let entry = QuoteEntry(date: Date(), data: data)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        // Defensive error handling - always return valid entry
        let data = WidgetData.load()
        let entry = QuoteEntry(date: Date(), data: data)
        
        // If no quotes are available yet (only fallback quote), refresh more frequently
        // to pick up quotes as soon as the app writes them
        let hasRealQuotes = data.quotes.count > 1 || (data.quotes.count == 1 && data.quotes.first != "The temple is a place of peace.")
        
        if !hasRealQuotes {
            // Refresh every 15 minutes when waiting for quotes to be written
            let nextUpdate = Date().addingTimeInterval(15 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        // Refresh daily to get a new quote when quotes are available
        let calendar = Calendar.current
        guard let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            // Fallback: refresh in 24 hours if date calculation fails
            let fallbackDate = Date().addingTimeInterval(24 * 60 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(fallbackDate))
            completion(timeline)
            return
        }
        let tomorrow = calendar.startOfDay(for: tomorrowDate)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Widget View
struct SmallQuoteWidgetView: View {
    let entry: QuoteEntry
    
    var body: some View {
        let quote = entry.data.quoteForCurrentDay()
        
        ZStack(alignment: .topLeading) {
            // Main content - vertically centered so short quotes look balanced
            VStack {
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                            .frame(width: 50) // Space for icon (24+8) + gap before title
                        Text("Daily Quote")
                            .font(.custom("Baskerville-Bold", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    Text(quote.isEmpty ? "The temple is a place of peace." : quote)
                        .font(.custom("Baskerville", size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(7)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 12)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // App icon
            VStack {
                HStack {
                    Image("holyPlacesIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .white.opacity(0.6), radius: 4)
                        .padding(4)
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "net.dacworld.holyplaces://summary"))
    }
}

// MARK: - Widget Definition

struct QuoteWidget: Widget {
    let kind = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QuoteProvider()
        ) { entry in
            SmallQuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Daily Quote")
        .description("Inspirational quotes about temples.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: .now, data: .placeholder)
}
