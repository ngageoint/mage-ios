//
//  ObservationFormReorderTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/24/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

@testable import MAGE

class ObservationFormReorderTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationFormReorder") {
            var observationFormReorder: ObservationFormReorder?
            var window: UIWindow!;
            var stackSetup = false;
            var eventForm: Form!
            
            beforeEach {
                if (!stackSetup) {
                    TestHelpers.clearAndSetUpStack();
                    stackSetup = true;
                }
                
                MageCoreDataFixtures.clearAllData();
                TestHelpers.resetUserDefaults();
                window = TestHelpers.getKeyWindowVisible();
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "allFieldTypesForm")
                
                eventForm = FormBuilder.createFormWithAllFieldTypes();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
                
                observationFormReorder?.dismiss(animated: false);
                
//                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots();
            }
            
            afterEach {
                observationFormReorder?.dismiss(animated: false);
                observationFormReorder = nil;
                window.rootViewController = nil;
            }
            
            it("observation for reorder primary and variant") {
                let observation = ObservationBuilder.createPointObservation(eventId: 1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : "At Venue",
                    "field9": "text"
                ]);
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : "Parade Event",
                    "field9": "hello"
                ]);

                let delegate: MockObservationFormReorderDelegate = MockObservationFormReorderDelegate();
                observationFormReorder = ObservationFormReorder(observation: observation, delegate: delegate, containerScheme: MAGEScheme.scheme());
                let nav = UINavigationController(rootViewController: observationFormReorder!);
                window.rootViewController = nav;
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "Reorder Forms");
                tester().waitForAnimationsToFinish();
//                expect(window).to(haveValidSnapshot(usesDrawRect: true));
            }
            
            it("observation for reorder primary only") {
                let observation = ObservationBuilder.createPointObservation(eventId: 1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : "At Venue",
                    "field9": nil
                ]);
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : "Parade Event",
                    "field9": nil
                ]);
                
                let delegate: MockObservationFormReorderDelegate = MockObservationFormReorderDelegate();
                observationFormReorder = ObservationFormReorder(observation: observation, delegate: delegate, containerScheme: MAGEScheme.scheme());
                let nav = UINavigationController(rootViewController: observationFormReorder!);
                window.rootViewController = nav;
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "Reorder Forms");
                tester().waitForAnimationsToFinish();
//                expect(window).to(haveValidSnapshot(usesDrawRect: true));
            }
            
            it("observation for reorder variant only") {
                let observation = ObservationBuilder.createPointObservation(eventId: 1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : nil,
                    "field9": "hello"
                ]);
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : nil,
                    "field9": "hello"
                ]);
                
                let delegate: MockObservationFormReorderDelegate = MockObservationFormReorderDelegate();
                observationFormReorder = ObservationFormReorder(observation: observation, delegate: delegate, containerScheme: MAGEScheme.scheme());
                let nav = UINavigationController(rootViewController: observationFormReorder!);
                window.rootViewController = nav;
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "Reorder Forms");
                tester().waitForAnimationsToFinish();
//                expect(window).to(haveValidSnapshot(usesDrawRect: true));
            }
            
            it("observation for reorder form name only") {
                let observation = ObservationBuilder.createPointObservation(eventId: 1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : nil,
                    "field9": nil
                ]);
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm, values: [
                    "type" : nil,
                    "field9": nil
                ]);
                
                let delegate: MockObservationFormReorderDelegate = MockObservationFormReorderDelegate();
                observationFormReorder = ObservationFormReorder(observation: observation, delegate: delegate, containerScheme: MAGEScheme.scheme());
                let nav = UINavigationController(rootViewController: observationFormReorder!);
                window.rootViewController = nav;
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "Reorder Forms");
                tester().waitForAnimationsToFinish();
//                expect(window).to(haveValidSnapshot(usesDrawRect: true));
            }
        }
    }
}
