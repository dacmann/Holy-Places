//
//  Holy_Places_WidgetsBundle.swift
//  Holy Places Widgets
//
//  Created by Derek Cordon on 1/28/26.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct Holy_Places_WidgetsBundle: WidgetBundle {
    var body: some Widget {
        VisitPhotoWidget()      // Large - configurable image source (visit photos or place images)
        AchievementGoalWidget() // Medium - latest achievement + goals
        QuoteWidget()           // Small - app logo + short quote
    }
}
