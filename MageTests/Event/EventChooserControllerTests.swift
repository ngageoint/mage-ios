//
//  EventChooserControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 4/13/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import MAGE

class MockEventSelectionDelegate: NSObject, EventSelectionDelegate {
    var didSelectCalled = false
    var eventSelected: Event?
    var actionButtonTappedCalled = false
    func didSelect(_ event: Event!) {
        didSelectCalled = true
        eventSelected = event
    }
    
    func actionButtonTapped() {
        actionButtonTappedCalled = true
    }
}

class EventChooserControllerTests : KIFSpec {
    override func spec() {
        
        describe("EventChooserControllerTests") {
            
            var window: UIWindow?;
            var view: EventChooserController?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                navigationController = UINavigationController();
                
                window = TestHelpers.getKeyWindowVisible();
                window!.rootViewController = navigationController;
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                TestHelpers.clearAndSetUpStack();
            }
            
            it("Should load the event chooser with no events") {
                let eventDataSource = EventTableDataSource(scheme: MAGEScheme.scheme())
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(dataSource: eventDataSource, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                tester().wait(forTimeInterval: 5)
                TestHelpers.printAllAccessibilityLabelsInWindows()
            }
        }
    }
}
