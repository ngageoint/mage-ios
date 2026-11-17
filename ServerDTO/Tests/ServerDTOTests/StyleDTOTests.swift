import Testing
import Foundation
@testable import ServerDTO

@Suite struct StyleDTOTests {
    let json: [String: Any] = [
        "fill": "#5278A2",
        "fillOpacity": 0.2,
        "stroke": "#5278A2",
        "strokeOpacity": 1,
        "strokeWidth": 2,
        "Turtle": [
            "fill": "#5278a2",
            "fillOpacity": 0.3,
            "stroke": "#214166",
            "strokeOpacity": 0.8,
            "strokeWidth": 4,
            "Red": [
                "fill": "#ff0033",
                "fillOpacity": 0.5,
                "stroke": "#ff0026",
                "strokeOpacity": 0.6,
                "strokeWidth": 6
            ]
        ]
    ]

    @Test func encodingKeepsTypeAndVariantStyles() throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        let style = try JSONDecoder().decode(StyleDTO.self, from: data)

        let encoded = try encode(style)
        #expect(encoded["stroke"] as? String == "#5278A2")
        #expect(encoded["strokeWidth"] as? Double == 2)

        let turtle = try #require(encoded["Turtle"] as? [String: Any])
        #expect(turtle["fill"] as? String == "#5278a2")
        #expect(turtle["fillOpacity"] as? Double == 0.3)
        #expect(turtle["stroke"] as? String == "#214166")
        #expect(turtle["strokeOpacity"] as? Double == 0.8)
        #expect(turtle["strokeWidth"] as? Double == 4)

        let red = try #require(turtle["Red"] as? [String: Any])
        #expect(red["stroke"] as? String == "#ff0026")
        #expect(red["fillOpacity"] as? Double == 0.5)
        #expect(red["strokeWidth"] as? Double == 6)
    }

    @Test func encodingTopLevelOnlyStyle() throws {
        let topLevel: [String: Any] = [
            "fill": "#000000",
            "fillOpacity": 0.5,
            "stroke": "#ffffff",
            "strokeOpacity": 1,
            "strokeWidth": 40
        ]
        let data = try JSONSerialization.data(withJSONObject: topLevel)
        let style = try JSONDecoder().decode(StyleDTO.self, from: data)

        let encoded = try encode(style)
        #expect(encoded.count == 5)
        #expect(encoded["fill"] as? String == "#000000")
        #expect(encoded["fillOpacity"] as? Double == 0.5)
        #expect(encoded["stroke"] as? String == "#ffffff")
        #expect(encoded["strokeOpacity"] as? Double == 1)
        #expect(encoded["strokeWidth"] as? Double == 40)
    }

    @Test func encodingIgnoresFieldStylesNamedLikeBuiltInKeys() throws {
        let style = StyleDTO(
            stroke: "#ffffff",
            fill: "#000000",
            fieldStyles: [
                "fill": StyleDTO(fill: "#ff0000"),
                "Turtle": StyleDTO(stroke: "#00ff00")
            ]
        )

        let encoded = try encode(style)
        #expect(encoded["fill"] as? String == "#000000")
        #expect(encoded["stroke"] as? String == "#ffffff")
        let turtle = try #require(encoded["Turtle"] as? [String: Any])
        #expect(turtle["stroke"] as? String == "#00ff00")
    }

    @Test func formEncodingKeepsTypeStyles() throws {
        let formJSON: [String: Any] = ["id": 1, "style": json]
        let data = try JSONSerialization.data(withJSONObject: formJSON)
        let form = try JSONDecoder().decode(EventFormDTO.self, from: data)

        let encoded = try encode(form)
        let style = try #require(encoded["style"] as? [String: Any])
        let turtle = try #require(style["Turtle"] as? [String: Any])
        #expect(turtle["stroke"] as? String == "#214166")
    }

    private func encode(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
