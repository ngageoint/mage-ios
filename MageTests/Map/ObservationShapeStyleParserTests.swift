//
//  ObservationShapeStyleParserTests.swift
//  MAGETests
//

import Foundation
import Quick
import Nimble
import MagicalRecord
import Persistence

@testable import MAGE

class ObservationShapeStyleParserTests: KIFSpec {

    override func spec() {
        describe("ObservationShapeStyleParser Tests") {

            let formJson: [AnyHashable: Any] = [
                "id": 26,
                "name": "Wildlife",
                "primaryField": "type",
                "variantField": "color",
                "fields": [
                    [
                        "id": 1, "name": "type", "title": "Type", "type": "dropdown",
                        "choices": [["id": 0, "value": 0, "title": "Turtle"]]
                    ],
                    [
                        "id": 2, "name": "color", "title": "Color", "type": "dropdown",
                        "choices": [
                            ["id": 0, "value": 0, "title": "Red"],
                            ["id": 1, "value": 1, "title": "stroke"]
                        ]
                    ]
                ],
                "style": [
                    "stroke": "#000000",
                    "strokeOpacity": 1,
                    "strokeWidth": 2,
                    "Turtle": [
                        "stroke": "#214166",
                        "strokeOpacity": 1,
                        "strokeWidth": 4,
                        "Red": [
                            "stroke": "#ff0026",
                            "strokeOpacity": 1,
                            "strokeWidth": 6
                        ]
                    ]
                ]
            ]

            func lineObservation(type: String, color: String) -> Observation {
                let observation = ObservationBuilder.createLineObservation(eventId: 1)
                observation.properties!["forms"] = [
                    ["formId": 26, "type": type, "color": color]
                ]
                return observation
            }

            beforeEach {
                TestHelpers.clearAndSetUpStack()
                Server.setCurrentEventId(1)
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: [formJson])
            }

            afterEach {
                TestHelpers.clearAndSetUpStack()
            }

            it("should use the variant style") {
                let style = ObservationShapeStyleParser.style(ofObservation: lineObservation(type: "Turtle", color: "Red"))
                expect(style?.strokeColor.hex()).to(equal("#FF0026"))
                expect(style?.lineWidth).to(equal(6 / UIScreen.main.scale))
            }

            it("should use the type style when the variant is named like a style property") {
                let style = ObservationShapeStyleParser.style(ofObservation: lineObservation(type: "Turtle", color: "stroke"))
                expect(style?.strokeColor.hex()).to(equal("#214166"))
                expect(style?.lineWidth).to(equal(4 / UIScreen.main.scale))
            }
        }
    }
}
