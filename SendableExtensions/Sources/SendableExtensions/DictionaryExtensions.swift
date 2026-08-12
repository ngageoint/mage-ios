//
//  DictionaryExtensions.swift
//  SendableExtensions
//
//

import Foundation
import SimpleFeatures
import SimpleFeaturesGeoJSON

public extension Dictionary where Key == String, Value == Any {
    func toSendablePrimitives() -> [String: Sendable] {
        compactMapValues { makeSendablePrimitive($0) }
    }
    
    func toSendableValues() -> [String: SendableValue] {
        compactMapValues { makeSendableValue($0) }
    }
    
    func makeSendableValue(_ value: Any) -> SendableValue? {
        switch value {
        case let v as AnyHashable:
            if type(of: v.base) == AnyHashable.self {
                return nil // avoid recursion
            }
            return makeSendableNotAnyHashable(v.base)
        default:
            return makeSendableNotAnyHashable(value)
        }
    }
    func makeSendableNotAnyHashable(_ value: Any) -> SendableValue? {
        switch value {
        case let v as String:
            return .string(v)
            
        case let v as Int:
            return .int(v)
            
        case let v as Double:
            return .double(v)
            
        case let v as Bool:
            return .bool(v)
            
        case let v as Date:
            return .date(v)
            
        case let v as NSNumber:
            let type = String(cString: v.objCType)
            
            switch type {
            case "c": // Bool / char
                return .bool(v.boolValue)
            case "q", "i", "s", "l":
                return .int(v.intValue)
            case "d", "f":
                return .double(v.doubleValue)
            default:
                return .double(v.doubleValue)
            }
            
        case let v as [String: Any]:
            let converted = v.compactMapValues { makeSendableValue($0) }
            return .dictionary(converted)
            
        case let v as [Any]:
            let converted = v.compactMap { makeSendableValue($0) }
            return .array(converted)
            
        case let v as SFGeometry:
            if let converted = SFGFeatureConverter.simpleGeometry(toJSON: v) {
                return .simpleFeature(converted)
            }
            return nil
        case _ as NSNull:
            return .null
        default:
            if case Optional<Any>.none = value {
                print("It is nil")
                return .null
            } else {
                print("It is NOT nil")
            }
            // Unsupported / non-Sendable type
            return nil
        }
    }
    
    func makeSendablePrimitive(_ value: Any) -> (any Sendable)? {
        guard let value = makeSendableValue(value) else {
            return nil
        }
        switch value {
        case .string(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .bool(let v): return v
        case .date(let v): return v
        case .dictionary(let v): return v.mapValues { $0.primitiveValue() }
        case .array(let v): return v.map { $0.primitiveValue() }
        case .simpleFeature(let v): return v
        case .null: return nil
        }
    }
    
}

public extension Dictionary where Key == String, Value == Any? {
    func toSendablePrimitives() -> [String: Sendable] {
        compactMapValues { makeSendablePrimitive($0) }
    }
    
    func toSendableValues() -> [String: SendableValue] {
        compactMapValues { makeSendableValue($0) }
    }
    
    func makeSendableValue(_ value: Any?) -> SendableValue? {
        switch value {
        case let v as String:
            return .string(v)
            
        case let v as Int:
            return .int(v)
            
        case let v as Double:
            return .double(v)
            
        case let v as Bool:
            return .bool(v)
            
        case let v as Date:
            return .date(v)
            
        case let v as NSNumber:
            // NSNumber can represent Bool, Int, or Double
            if CFGetTypeID(v) == CFBooleanGetTypeID() {
                return .bool(v.boolValue)
            } else if floor(v.doubleValue) == v.doubleValue {
                return .int(v.intValue)
            } else {
                return .double(v.doubleValue)
            }
            
        case let v as [String: Any]:
            let converted = v.compactMapValues { makeSendableValue($0) }
            return .dictionary(converted)
            
        case let v as [Any]:
            let converted = v.compactMap { makeSendableValue($0) }
            return .array(converted)
            
        case let v as SFGeometry:
            if let converted = SFGFeatureConverter.simpleGeometry(toJSON: v) {
                return .simpleFeature(converted)
            }
            return nil
        case _ as NSNull:
            return .null
            
        default:
            // Unsupported / non-Sendable type
            return nil
        }
    }
    
    func makeSendablePrimitive(_ value: Any?) -> Sendable? {
        switch value {
        case let v as String:
            return v
            
        case let v as Int:
            return v
            
        case let v as Double:
            return v
            
        case let v as Bool:
            return v
            
        case let v as Date:
            return v
            
        case let v as NSNumber:
            // NSNumber can represent Bool, Int, or Double
            if CFGetTypeID(v) == CFBooleanGetTypeID() {
                return v.boolValue
            } else if floor(v.doubleValue) == v.doubleValue {
                return v.intValue
            } else {
                return v.doubleValue
            }
            
        case let v as [String: Any]:
            let converted = v.compactMapValues { makeSendablePrimitive($0) }
            return converted
            
        case let v as [Any]:
            let converted = v.compactMap { makeSendablePrimitive($0) }
            return converted
            
        case let v as SFGeometry:
            if let converted = SFGFeatureConverter.simpleGeometry(toJSON: v) {
                return converted
            }
            return nil
        case _ as NSNull:
            return nil
            
        default:
            // Unsupported / non-Sendable type
            return nil
        }
    }
    
}

public extension Dictionary where Key == String, Value == SendableValue {
    
    func anyValue(from value: SendableValue) -> Any {
        switch value {
        case .string(let v):
            return v

        case .int(let v):
            return v

        case .double(let v):
            return v

        case .bool(let v):
            return v
            
        case .date(let v):
            return v

        case .dictionary(let dict):
            return dict.mapValues { anyValue(from: $0) }

        case .array(let array):
            return array.map { anyValue(from: $0) }
            
        case .simpleFeature(let string):
            return SFGFeatureConverter.json(toSimpleGeometry: string) ?? NSNull()

        case .null:
            return NSNull()
        }
    }
    
    
    func toAnyValues() -> [String: Any] {
        mapValues { anyValue(from: $0) }
    }
}

public extension Dictionary where Key == String, Value == AnyHashable {
    func toSendablePrimitives() -> [String: Sendable] {
        compactMapValues { makeSendablePrimitive($0) }
    }
    
    func toSendableValues() -> [String: SendableValue] {
        compactMapValues { makeSendableValue($0) }
    }
    
    func makeSendableValue(_ value: AnyHashable) -> SendableValue? {
        switch value {
        case let v as String:
            return .string(v)
            
        case let v as Int:
            return .int(v)
            
        case let v as Double:
            return .double(v)
            
        case let v as Bool:
            return .bool(v)
            
        case let v as Date:
            return .date(v)
            
        case let v as NSNumber:
            // NSNumber can represent Bool, Int, or Double
            if CFGetTypeID(v) == CFBooleanGetTypeID() {
                return .bool(v.boolValue)
            } else if floor(v.doubleValue) == v.doubleValue {
                return .int(v.intValue)
            } else {
                return .double(v.doubleValue)
            }
            
        case let v as [String: AnyHashable]:
            let converted = v.compactMapValues { makeSendableValue($0) }
            return .dictionary(converted)
            
        case let v as [AnyHashable]:
            let converted = v.compactMap { makeSendableValue($0) }
            return .array(converted)
            
        case let v as SFGeometry:
            if let converted = SFGFeatureConverter.simpleGeometry(toJSON: v) {
                return .simpleFeature(converted)
            }
            return nil
        case _ as NSNull:
            return .null
            
        default:
            // Unsupported / non-Sendable type
            return nil
        }
    }
    
    func makeSendablePrimitive(_ value: AnyHashable) -> Sendable? {
        switch value {
        case let v as String:
            return v
            
        case let v as Int:
            return v
            
        case let v as Double:
            return v
            
        case let v as Bool:
            return v
            
        case let v as Date:
            return v
            
        case let v as NSNumber:
            // NSNumber can represent Bool, Int, or Double
            if CFGetTypeID(v) == CFBooleanGetTypeID() {
                return v.boolValue
            } else if floor(v.doubleValue) == v.doubleValue {
                return v.intValue
            } else {
                return v.doubleValue
            }
            
        case let v as [String: AnyHashable]:
            let converted = v.compactMapValues { makeSendablePrimitive($0) }
            return converted
            
        case let v as [AnyHashable]:
            let converted = v.compactMap { makeSendablePrimitive($0) }
            return converted
            
        case let v as SFGeometry:
            if let converted = SFGFeatureConverter.simpleGeometry(toJSON: v) {
                return converted
            }
            return nil
        case _ as NSNull:
            return nil
            
        default:
            // Unsupported / non-Sendable type
            return nil
        }
    }
    
}

public extension Dictionary where Key == AnyHashable, Value == Any {
    // this is to correct an error where the data is pulled form the db as a swift array not an nsarray
    func toStringAnyHashable() -> [String: AnyHashable]? {
        return self.compactMapValues { value -> AnyHashable? in
            if let hashableValue = value as? AnyHashable {
                return hashableValue
            }
            if let hashableValue = value as? [AnyHashable] {
                return hashableValue
            }
            if let dictionary = value as? [AnyHashable: Any] {
                return dictionary.toStringAnyHashable()
            }
            // If it's a [String] that failed the direct cast,
            // wrapping it in AnyHashable explicitly often works
            if let stringArray = value as? [String] {
                return AnyHashable(stringArray)
            }
            return nil
        } as? [String: AnyHashable]
    }
}
