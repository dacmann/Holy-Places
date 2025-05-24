//
//  StringArrayTransformer.swift
//  Holy Places
//
//  Created by Derek Cordon on 5/23/25.
//  Copyright © 2025 Derek Cordon. All rights reserved.
//
import Foundation

@objc(StringArrayTransformer)
final class StringArrayTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool { true }
    override class func transformedValueClass() -> AnyClass { NSArray.self }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [String] else { return nil }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: true)
            return data
        } catch {
            print("Failed to archive oldNames: \(error)")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            let array = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSString.self], from: data)
            return array as? [String]
        } catch {
            print("Failed to unarchive oldNames: \(error)")
            return nil
        }
    }
}

