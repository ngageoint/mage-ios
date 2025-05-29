//
//  FormPickerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/30/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import OHHTTPStubs
import MaterialComponents.MaterialBottomSheet

@testable import MAGE

class MockFormPickerDelegate: FormPickedDelegate {
    var formPickedCalled = true;
    var pickedForm: Form?;
    var cancelSelectionCalled = false;
    
    func formPicked(form: Form) {
        formPickedCalled = true;
        pickedForm = form;
    }
    
    func cancelSelection() {
        cancelSelectionCalled = true;
    }
}

class FormPickerTests: AsyncMageCoreDataTestCase {

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        window = TestHelpers.getKeyWindowVisible()
    }

    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        formPicker.dismiss(animated: false, completion: nil)
        window.rootViewController = nil
        formPicker = nil
        Server.removeCurrentEventId()
    }

    var formPicker: FormPickerViewController!
    var window: UIWindow!;

    @MainActor
    func testInitialized() {
        formPicker = FormPickerViewController(scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        
//                expect(formPicker.view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testOneForm() {
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2
        ]]
        
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)
        
        formPicker = FormPickerViewController(forms: forms, scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        
//                expect(formPicker.view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testMultipleForms() {
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2
        ], [
            "name": "Vehicle",
            "description": "Information about a vehicle",
            "color": "#7852A2",
            "id": 3
        ], [
            "name": "Evidence",
            "description": "Evidence form",
            "color": "#52A278",
            "id": 0
        ], [
            "name": "Witness",
            "description": "Information gathered from a witness",
            "color": "#A25278",
            "id": 1
        ], [
            "name": "Location",
            "description": "Detailed information about the scene",
            "id": 4
        ]]
        
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)

        formPicker = FormPickerViewController(forms: forms, scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        
//                expect(formPicker.view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testAsASheet() {
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Vehicle",
            "description": "Information about a vehicle",
            "color": "#7852A2",
            "id": 3
        ], [
            "name": "Evidence",
            "description": "Evidence form",
            "color": "#52A278",
            "id": 0
        ], [
            "name": "Witness",
            "description": "Information gathered from a witness",
            "color": "#A25278",
            "id": 1
        ], [
            "name": "Location",
            "description": "Detailed information about the scene",
            "color": "#78A252",
            "id": 4
        ],[
            "name": "Suspect2",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2
        ], [
            "name": "Vehicle2",
            "description": "Information about a vehicle",
            "color": "#7852A2",
            "id": 3
        ], [
            "name": "Evidence2",
            "description": "Evidence form",
            "color": "#52A278",
            "id": 0
        ], [
            "name": "Witness2",
            "description": "Information gathered from a witness",
            "color": "#A25278",
            "id": 1
        ], [
            "name": "Location2",
            "description": "Detailed information about the scene",
            "color": "#78A252",
            "id": 4
        ], [
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2
        ]]
        let delegate = MockFormPickerDelegate();
        
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)

        formPicker = FormPickerViewController(delegate: delegate, forms: forms, scheme: MAGEScheme.scheme());
        
        let container = UIViewController();
        
        window.rootViewController = container;
        
        let bottomSheet: MDCBottomSheetController = MDCBottomSheetController(contentViewController: formPicker);
        container.present(bottomSheet, animated: true, completion: {
            TestHelpers.printAllAccessibilityLabelsInWindows();
        });
        tester().waitForView(withAccessibilityLabel: "Add A Form Table");
        tester().tapItem(at: IndexPath(row: forms.count - 1, section: 0), inCollectionViewWithAccessibilityIdentifier: "Add A Form Table")
        
        expect(delegate.formPickedCalled).to(beTrue());
        expect(delegate.pickedForm).to(equal(forms[9]));
        
        bottomSheet.dismiss(animated: false)

//                expect(formPicker.view).to(haveValidSnapshot());
    }
    // check constraints here
    @MainActor
    func testShouldTriggerTheDelegate() {
        
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2
        ], [
            "name": "Vehicle",
            "description": "Information about a vehicle",
            "color": "#7852A2",
            "id": 3
        ], [
            "name": "Evidence",
            "description": "Evidence form",
            "color": "#52A278",
            "id": 0
        ], [
            "name": "Witness",
            "description": "Information gathered from a witness",
            "color": "#A25278",
            "id": 1
        ], [
            "name": "Location",
            "description": "Detailed information about the scene",
            "color": "#78A252",
            "id": 4
        ]]
        
        let delegate = MockFormPickerDelegate();
        
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)

        formPicker = FormPickerViewController(delegate: delegate, forms: forms, scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        tester().waitForAnimationsToFinish()
        tester().waitForTappableView(withAccessibilityLabel: "Cancel");
        tester().tapView(withAccessibilityLabel: "Cancel");
        
        expect(delegate.cancelSelectionCalled).to(beTrue());
    }
    
    @MainActor
    func testCancelButtonCancels() {
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2
        ]]
        
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)

        formPicker = FormPickerViewController(forms: forms, scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        
//                expect(formPicker.view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testShouldDisableFormsAtOrExceedingMax() {
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2,
            "max": 1
        ], [
            "name": "Vehicle",
            "description": "Information about a vehicle",
            "color": "#7852A2",
            "id": 3
        ], [
            "name": "Evidence",
            "description": "Evidence form",
            "color": "#52A278",
            "id": 0
        ], [
            "name": "Witness",
            "description": "Information gathered from a witness",
            "color": "#A25278",
            "id": 1
        ], [
            "name": "Location",
            "description": "Detailed information about the scene",
            "color": "#78A252",
            "id": 4
        ]]
        
        let delegate = MockFormPickerDelegate();
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)
        
        Server.setCurrentEventId(1)
        
        var baseObservationJson: [AnyHashable : Any] = [:]
        baseObservationJson["important"] = nil;
        baseObservationJson["favoriteUserIds"] = nil;
        baseObservationJson["attachments"] = nil;
        baseObservationJson["lastModified"] = nil;
        baseObservationJson["createdAt"] = nil;
        baseObservationJson["eventId"] = 1;
        baseObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
        baseObservationJson["state"] = [
            "name": "active"
        ]
        baseObservationJson["geometry"] = [
            "coordinates": [-1.1, 2.1],
            "type": "Point"
        ]
        baseObservationJson["properties"] = [
            "timestamp": "2020-06-05T17:21:46.969Z",
            "forms": [[
                "formId":2
            ]]
        ];
        
        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
        let observations = Observation.mr_findAll();
        expect(observations?.count).to(equal(1));
        let observation: Observation = observations![0] as! Observation;
        
        formPicker = FormPickerViewController(delegate: delegate, forms: forms, observation: observation, scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        tester().waitForAnimationsToFinish()
        tester().waitForTappableView(withAccessibilityLabel: "Cancel");
        tester().tapItem(at: IndexPath(row: 0, section: 0), inCollectionViewWithAccessibilityIdentifier: "Add A Form Table")
        tester().waitForView(withAccessibilityLabel: "Suspect form cannot be included in an observation more than 1 time")

    }
    
    @MainActor
    func testShouldIndicateRequiredForms() {
        let formsJson: [[String: AnyHashable]] = [[
            "name": "Suspect",
            "description": "Information about a suspect",
            "color": "#5278A2",
            "id": 2,
            "min": 1
        ], [
            "name": "Vehicle",
            "description": "Information about a vehicle",
            "color": "#7852A2",
            "id": 3
        ], [
            "name": "Evidence",
            "description": "Evidence form",
            "color": "#52A278",
            "id": 0
        ], [
            "name": "Witness",
            "description": "Information gathered from a witness",
            "color": "#A25278",
            "id": 1
        ], [
            "name": "Location",
            "description": "Detailed information about the scene",
            "color": "#78A252",
            "id": 4
        ]]
        
        let delegate = MockFormPickerDelegate();
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: self.context)
        
        Server.setCurrentEventId(1)
        
        var baseObservationJson: [AnyHashable : Any] = [:]
        baseObservationJson["important"] = nil;
        baseObservationJson["favoriteUserIds"] = nil;
        baseObservationJson["attachments"] = nil;
        baseObservationJson["lastModified"] = nil;
        baseObservationJson["createdAt"] = nil;
        baseObservationJson["eventId"] = 1;
        baseObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
        baseObservationJson["state"] = [
            "name": "active"
        ]
        baseObservationJson["geometry"] = [
            "coordinates": [-1.1, 2.1],
            "type": "Point"
        ]
        baseObservationJson["properties"] = [
            "timestamp": "2020-06-05T17:21:46.969Z",
            "forms": []
        ];
        
        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
        let observations = self.context.fetchAll(Observation.self)
        expect(observations?.count).to(equal(1));
        let observation: Observation = observations![0] as! Observation;
        
        formPicker = FormPickerViewController(delegate: delegate, forms: forms, observation: observation, scheme: MAGEScheme.scheme());
        
        window.rootViewController = formPicker;
        
        tester().waitForAnimationsToFinish()
        tester().waitForView(withAccessibilityLabel: "Suspect*");
    }
}
