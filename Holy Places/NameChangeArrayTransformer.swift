//
//  NameChangeArrayTransformer.swift
//  Holy Places
//
//  Created by Derek Cordon on 6/13/25.
//  Copyright © 2025 Derek Cordon. All rights reserved.
//

import Foundation

/// Core Data value transformer that serialises [NameChange] to/from JSON Data.
/// Registered at launch alongside StringArrayTransformer.
@objc(NameChangeArrayTransformer)
final class NameChangeArrayTransformer: ValueTransformer {

    override class func allowsReverseTransformation() -> Bool { true }
    override class func transformedValueClass() -> AnyClass { NSData.self }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [NameChange] else { return nil }
        do {
            return try NameChangeArrayTransformer.encoder.encode(array) as NSData
        } catch {
            print("NameChangeArrayTransformer: encode failed — \(error)")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            return try NameChangeArrayTransformer.decoder.decode([NameChange].self, from: data)
        } catch {
            print("NameChangeArrayTransformer: decode failed — \(error)")
            return nil
        }
    }
}
