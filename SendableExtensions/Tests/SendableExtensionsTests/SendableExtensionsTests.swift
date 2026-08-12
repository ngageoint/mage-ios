import Foundation
import Testing
@testable import SendableExtensions

struct DictionarySendableConversionTests {
    
    @Test func testBool() async throws {
        let dictionary: [String: Any] = ["key": AnyHashable(true)]
        let sendable = dictionary.toSendableValues()
        print("Sendable \(sendable)") // this is SendableValue.int(1)
        
        let dictionary2: [String: Any] = ["key": true]
        let sendable2 = dictionary2.toSendableValues()
        print("Sendable2 \(sendable2)") // this is SendableValue.bool(true)
    }
    
    @Test
    func testAnyHashableBoolRegression() {
        let dictionary: [String: Any] = [
            "key": AnyHashable(true)
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(result["key"] == .bool(true))
    }
    
    @Test
    func testToSendableValues_Primitives() {
        let date = Date()
        
        let dictionary: [String: Any] = [
            "string": "hello",
            "int": 5,
            "double": 3.14,
            "bool": true,
            "date": date
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(result["string"] == .string("hello"))
        #expect(result["int"] == .int(5))
        #expect(result["double"] == .double(3.14))
        #expect(result["bool"] == .bool(true))
        #expect(result["date"] == .date(date))
    }
    
    @Test
    func testToSendableValues_NSNumber() {
        let dictionary: [String: Any] = [
            "bool": NSNumber(value: true),
            "int": NSNumber(value: 42),
            "double": NSNumber(value: 2.5),
            "float": NSNumber(value: Float(1.5))
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(result["bool"] == .bool(true))
        #expect(result["int"] == .int(42))
        #expect(result["double"] == .double(2.5))
        #expect(result["float"] == .double(1.5))
    }
    
    @Test
    func testToSendableValues_AnyHashable() {
        let dictionary: [String: Any] = [
            "string": AnyHashable("hello"),
            "int": AnyHashable(10),
            "double": AnyHashable(1.25),
            "bool": AnyHashable(true)
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(result["string"] == .string("hello"))
        #expect(result["int"] == .int(10))
        #expect(result["double"] == .double(1.25))
        #expect(result["bool"] == .bool(true))
    }
    
    @Test
    func testToSendableValues_NestedDictionary() {
        let dictionary: [String: Any] = [
            "nested": [
                "name": "test",
                "enabled": true,
                "count": 2
            ]
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(
            result["nested"] ==
                .dictionary([
                    "name": .string("test"),
                    "enabled": .bool(true),
                    "count": .int(2)
                ])
        )
    }
    
    @Test
    func testToSendableValues_Array() {
        let dictionary: [String: Any] = [
            "array": [
                "hello",
                1,
                true,
                2.5
            ]
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(
            result["array"] ==
                .array([
                    .string("hello"),
                    .int(1),
                    .bool(true),
                    .double(2.5)
                ])
        )
    }
    
    @Test
    func testToSendableValues_NSNull() {
        let dictionary: [String: Any] = [
            "null": NSNull()
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(result["null"] == .null)
    }
    
    @Test
    func testToSendableValues_UnsupportedValueDropped() {
        let dictionary: [String: Any] = [
            "object": NSObject()
        ]
        
        let result = dictionary.toSendableValues()
        
        #expect(result.isEmpty)
    }
    
    @Test
    func testToSendablePrimitives_Primitives() {
        let date = Date()
        
        let dictionary: [String: Any] = [
            "string": "hello",
            "int": 1,
            "double": 2.5,
            "bool": true,
            "date": date
        ]
        
        let result = dictionary.toSendablePrimitives()
        
        #expect(result["string"] as? String == "hello")
        #expect(result["int"] as? Int == 1)
        #expect(result["double"] as? Double == 2.5)
        #expect(result["bool"] as? Bool == true)
        #expect(result["date"] as? Date == date)
    }
    
    @Test
    func testToSendablePrimitives_NestedCollections() {
        let dictionary: [String: Any] = [
            "dictionary": [
                "a": 1,
                "b": true
            ],
            "array": [
                1,
                "two",
                false
            ]
        ]
        
        let result = dictionary.toSendablePrimitives()
        
        let nested = result["dictionary"] as? [String: Sendable]
        #expect(nested?["a"] as? Int == 1)
        #expect(nested?["b"] as? Bool == true)
        
        let array = result["array"] as? [any Sendable]
        #expect(array?.count == 3)
        #expect(array?[0] as? Int == 1)
        #expect(array?[1] as? String == "two")
        #expect(array?[2] as? Bool == false)
    }
    
    @Test
    func testToSendablePrimitives_NullAndUnsupportedAreDropped() {
        let dictionary: [String: Any] = [
            "null": NSNull(),
            "object": NSObject()
        ]
        
        let result = dictionary.toSendablePrimitives()
        
        #expect(result.isEmpty)
    }
}
