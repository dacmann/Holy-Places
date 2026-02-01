//
//  VisitWidgetIntent.swift
//  Holy Places Widgets
//
//  Created by Derek Cordon on 2026.
//  Copyright © 2026 Derek Cordon. All rights reserved.
//

import AppIntents
import WidgetKit

enum ImageSource: String, AppEnum {
    case visitPhoto = "visitPhoto"
    case placeImage = "placeImage"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Image Source")
    static var caseDisplayRepresentations: [ImageSource: DisplayRepresentation] = [
        .visitPhoto: "My Visit Photos",
        .placeImage: "Place Images"
    ]
}

struct VisitWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description = IntentDescription("Choose which images to display")
    
    @Parameter(title: "Image Source", default: .visitPhoto)
    var imageSource: ImageSource
}
