//
//  ObservationImageTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/19/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs
import MagicalRecord

@testable import MAGE

class ObservationImageTests: KIFSpec {
    
    override func spec() {
        describe("ObservationImage Tests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                Server.setCurrentEventId(1);
                NSManagedObject.mr_setDefaultBatchSize(0);
            }
            
            afterEach {
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
            }
            
            func getDocumentsDirectory() -> String {
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0]
                return documentsDirectory as String
            }
            
            func getFormsJsonWithExtraFields() -> [[AnyHashable: Any]] {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                var fields = (formsJson[0]["fields"] as! [[AnyHashable: Any]])
                
                fields.append([
                    "name": "testfield",
                    "type": "textfield",
                    "title": "Test Field",
                    "id": 100
                ])
                fields.append([
                    "name": "secondary",
                    "type": "textfield",
                    "title": "secondary Field",
                    "id": 101
                ])
                
                formsJson[0]["fields"] = fields;
                return formsJson
            }
            
            it("should get the image name with primary field") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()
                
                formsJson[0]["primaryField"] = "testfield";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(equal(iconPath))
            }
            
            it("should get the image name with primary and secondary field") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/turtle/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["variantField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(equal(iconPath))
            }
            
            it("should get the image name with no primary or secondary field") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(equal(iconPath))
            }
            
            it("should get the image name with primary and secondary but no icons") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(equal(iconPath))
            }
            
            it("should get the image name with primary and secondary but only primary icon") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                var fields = (formsJson[0]["fields"] as! [[AnyHashable: Any]])
                
                fields.append([
                    "name": "testfield",
                    "type": "textfield",
                    "title": "Test Field",
                    "id": 100
                ])
                fields.append([
                    "name": "secondary",
                    "type": "textfield",
                    "title": "secondary Field",
                    "id": 101
                ])
                
                formsJson[0]["fields"] = fields;
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(equal(iconPath))
            }
            
            it("should get the image name with primary and secondary but only event icon") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(equal(iconPath))
            }
            
            it("should get the nil for the image name with primary and secondary but no icons") {
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(beNil())
            }
            
            it("should get the nil for the image name with primary and secondary directory exists but no icon.png") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let imageName = ObservationImage.imageName(observation: observation);
                expect(imageName).to(beNil())
            }
            
            it("should get the defaultMarker image with primary and secondary directory exists but no icon.png") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["secondaryField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let image = ObservationImage.image(observation: observation)
                expect(image).to(equal(UIImage(named:"defaultMarker")))
            }
            
            it("should get the image with primary and secondary field") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/turtle/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["variantField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let image = ObservationImage.image(observation: observation);
                expect(image).toNot(beNil());
                expect(image).toNot(equal(UIImage(named:"defaultMarker")));
            }
            
            it("should get the image with primary and secondary field from the cache") {
                let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/turtle/icon.png"
                
                do {
                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    let image: UIImage = UIImage(named: "marker")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                var formsJson = getFormsJsonWithExtraFields()

                formsJson[0]["primaryField"] = "testfield";
                formsJson[0]["variantField"] = "secondary"
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi",
                        "secondary": "turtle"
                    ]
                ]
                
                let image = ObservationImage.image(observation: observation);
                expect(image).toNot(beNil());
                expect(image).toNot(equal(UIImage(named:"defaultMarker")));
                
                // this is to verify it is from the cache and not this other icon
                // if there is no file at the location, the default marker will be returned so a file must exist
                do {
                    try FileManager.default.removeItem(atPath: iconPath);
                    let image: UIImage = UIImage(systemName: "location.north.fill")!
                    FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
                }
                
                let image2 = ObservationImage.image(observation: observation);
                expect(image2).toNot(beNil());
                expect(image2).to(equal(image))
            }
        }
    }
}
