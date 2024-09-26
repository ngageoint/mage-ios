//
//  ObservationImageRepositoryTests.swift
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

class ObservationImageRepositoryTests: MageCoreDataTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.baseServerUrl = "https://magetest"
        
        Server.setCurrentEventId(1)
    }
    
    override func tearDown() {
        super.tearDown()
        TestHelpers.clearAndSetUpStack()
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

    func testShouldGetTheImageNameWithPrimaryField() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()
        
        formsJson[0]["primaryField"] = "testfield";
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(equal(iconPath))
        }
    }
    
    func tesstShouldGetTheImageWithPrimaryAndSecondaryField() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/turtle/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["variantField"] = "secondary"
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(equal(iconPath))
        }
    }
    
    func testShouldGetTheImageNameWithNoPrimaryOrSecondaryField() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["secondaryField"] = "secondary"
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(equal(iconPath))
        }
    }
    
    func testShouldGetTheImageNameWithPrimaryAndSecondaryButNoIcons() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["secondaryField"] = "secondary"
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(equal(iconPath))
        }
    }
    
    func testShouldGetTheImageNameWithPrimaryAndSecondaryButOnlyPrimaryIcon() throws {
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
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(equal(iconPath))
        }
    }
    
    func testShouldGetTheImageNameWithPrimaryAndSecondaryButOnlyEventIcon() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["secondaryField"] = "secondary"
        
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(equal(iconPath))
        }
    }
    
    func testShouldGetTheNilForTheImageNameWithPrimaryAndSecondaryButNoIcons() {
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["secondaryField"] = "secondary"
        
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(beNil())
        }
    }
    
    func testShouldGetNilForTheImageNameWithPrimaryAndSecondaryDirectoryExistsButNoIcon() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["secondaryField"] = "secondary"
        context.performAndWait {
            
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let imageName = imageRepository.imageName(observation: observation);
            expect(imageName).to(beNil())
        }
    }
    
    func testShouldGetTheDefaultMarkerImageWithPrimaryAndSecondaryDirectoryExistsButNoIcon() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["secondaryField"] = "secondary"
        
        context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let image = imageRepository.image(observation: observation)
            expect(image).to(equal(UIImage(named:"defaultMarker")))
        }
    }
    
    func testShouldGetTheImageWithPrimaryAndSecondaryField() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/turtle/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["variantField"] = "secondary"
        context.performAndWait {
            
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let image = imageRepository.image(observation: observation);
            expect(image).toNot(beNil());
            expect(image).toNot(equal(UIImage(named:"defaultMarker")));
        }
    }
    
    func testShouldGetTheImageWithPrimaryAndSecondaryFieldFromTheCache() throws {
        let iconPath = "\(getDocumentsDirectory())/events/icons-1/icons/26/Hi/turtle/icon.png"
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: iconPath).deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let image: UIImage = UIImage(named: "marker")!
            FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
        }
        
        var formsJson = getFormsJsonWithExtraFields()

        formsJson[0]["primaryField"] = "testfield";
        formsJson[0]["variantField"] = "secondary"
        
        try context.performAndWait {
            MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
            
            let observation = ObservationBuilder.createBlankObservation(1);
            observation.properties!["forms"] = [
                [
                    "formId": 26,
                    "testfield": "Hi",
                    "secondary": "turtle"
                ]
            ]
            let imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl()
            
            let image = imageRepository.image(observation: observation);
            expect(image).toNot(beNil());
            expect(image).toNot(equal(UIImage(named:"defaultMarker")));
            
            // this is to verify it is from the cache and not this other icon
            // if there is no file at the location, the default marker will be returned so a file must exist
            do {
                try FileManager.default.removeItem(atPath: iconPath);
                let image: UIImage = UIImage(systemName: "location.north.fill")!
                FileManager.default.createFile(atPath: iconPath, contents: image.pngData()!, attributes: nil)
            }
            
            let image2 = imageRepository.image(observation: observation);
            expect(image2).toNot(beNil());
            expect(image2).to(equal(image))
        }
    }
}
