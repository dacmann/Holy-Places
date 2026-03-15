//
//  AchievementGoalWidget.swift
//  Holy Places Widgets
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct AchievementGoalEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct AchievementGoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> AchievementGoalEntry {
        AchievementGoalEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AchievementGoalEntry) -> Void) {
        completion(AchievementGoalEntry(date: Date(), data: WidgetData.load()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AchievementGoalEntry>) -> Void) {
        let entry = AchievementGoalEntry(date: Date(), data: WidgetData.load())
        
        // Refresh every 6 hours to keep data current
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct MediumAchievementWidgetView: View {
    let entry: AchievementGoalEntry
    
    // Get current year for header
    var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    // Dynamic font size based on number of goals (1-5)
    func goalFontSize(for goalCount: Int) -> CGFloat {
        switch goalCount {
        case 1: return 24
        case 2: return 21
        case 3: return 19
        case 4: return 17
        default: return 15  // 5 or more
        }
    }
    
    // Dynamic title font size based on number of goals
    func titleFontSize(for goalCount: Int) -> CGFloat {
        switch goalCount {
        case 1: return 22
        case 2: return 20
        case 3: return 19
        case 4: return 18
        default: return 17  // 5 or more
        }
    }
    
    var body: some View {
        let allLines = entry.data.goalProgress.components(separatedBy: "\n").filter { !$0.isEmpty }
        let hasProfileHeader = allLines.first?.hasSuffix("Goals") ?? false
        let headerText = hasProfileHeader ? (allLines.first ?? "\(currentYear) Goal Progress") : "\(currentYear) Goal Progress"
        let goals = hasProfileHeader ? Array(allLines.dropFirst()) : allLines
        let goalCount = min(max(goals.count, 1), 5)
        
        ZStack {
            // Main content
            HStack(spacing: 20) {
                // Achievement icon on the left
                Image(entry.data.achievementIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .shadow(color: .white.opacity(0.6), radius: 4)
                
                // Goals on the right - expand to fill available width on Max screens
                VStack(alignment: .leading, spacing: 3) {
                    Text(headerText)
                        .font(.custom("Baskerville-Bold", size: titleFontSize(for: goalCount)))
                        .foregroundColor(.white)
                    
                    if entry.data.goalProgress == "SET GOAL" {
                        Text("Tap to set your goals")
                            .font(.custom("Baskerville", size: goalFontSize(for: 1)))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        // Parse and display goal progress
                        ForEach(goals.prefix(5), id: \.self) { goal in
                            Text(goal)
                                .font(.custom("Baskerville", size: goalFontSize(for: goalCount)))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 8))
            
            // App icon fixed in lower right corner of widget container
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("holyPlacesIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .white.opacity(0.6), radius: 4)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "net.dacworld.holyplaces://summary"))
    }
}

// MARK: - Widget Definition

struct AchievementGoalWidget: Widget {
    let kind = "AchievementGoalWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: AchievementGoalProvider()
        ) { entry in
            MediumAchievementWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Achievement & Goals")
        .description("Shows your latest achievement and current goals.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    AchievementGoalWidget()
} timeline: {
    AchievementGoalEntry(date: .now, data: .placeholder)
}
