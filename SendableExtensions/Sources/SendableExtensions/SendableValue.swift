//
//  SendableValue.swift
//  SendableExtensions
//
//


import Foundation
import SimpleFeatures
import SimpleFeaturesGeoJSON

public enum SendableValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case dictionary([String: SendableValue])
    case array([SendableValue])
    case simpleFeature(String)
    case null
    
    public func anyHashableValue() -> AnyHashable {
        switch self {
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
            return dict.mapValues { $0.anyHashableValue() }

        case .array(let array):
            return array.map { $0.anyHashableValue() }
            
        case .simpleFeature(let string):
            return SFGFeatureConverter.json(toSimpleGeometry: string) ?? NSNull()

        case .null:
            return NSNull()
        }
    }
    
    public func anyValue() -> Any {
        switch self {
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
            return dict.mapValues { $0.anyValue }

        case .array(let array):
            return array.map { $0.anyValue }
            
        case .simpleFeature(let string):
            return SFGFeatureConverter.json(toSimpleGeometry: string) ?? NSNull()

        case .null:
            return NSNull()
        }
    }
    
    public func primitiveValue() -> Sendable {
        switch self {
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
            return dict.mapValues { $0.primitiveValue }

        case .array(let array):
            return array.map { $0.primitiveValue }
            
        case .simpleFeature(let string):
            return string

        case .null:
            return NSNull()
        }
    }
    
    public static func makeSendableValue(_ value: Any?) -> SendableValue? {
        guard let value else { return nil }
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
}

extension SendableValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Date.self) {
            self = .date(value)
        } else if let value = try? container.decode([String: SendableValue].self) {
            self = .dictionary(value)
        } else if let value = try? container.decode([SendableValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                SendableValue.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported SendableValue type"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let a0):
            try? container.encode(a0)
        case .int(let a0):
            try? container.encode(a0)
        case .double(let a0):
            try? container.encode(a0)
        case .bool(let a0):
            try? container.encode(a0)
        case .date(let a0):
            try? container.encode(a0)
        case .dictionary(let a0):
            try? container.encode(a0)
        case .array(let a0):
            try? container.encode(a0)
        case .simpleFeature(let a0):
            try? container.encode(a0)
        case .null:
            try? container.encodeNil()
        }
    }
}
