//
//  TestHelpers.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MagicalRecord
import Nimble
import Nimble_Snapshots

class TestHelpers {

    public static func getAllAccessibilityLabels(_ viewRoot: UIView) -> [String]! {
        var array = [String]()
        for view in viewRoot.subviews {
            if let lbl = view.accessibilityLabel {
                array += [lbl]
            }
            
            array += getAllAccessibilityLabels(view)
        }
        
        return array
    }

    public static func getAllAccessibilityLabelsInWindows() -> [String]! {
        var labelArray = [String]()
        for  window in UIApplication.shared.windowsWithKeyWindow() {
            labelArray += getAllAccessibilityLabels(window as! UIWindow )
        }
        
        return labelArray
    }
    
    public static func printAllAccessibilityLabelsInWindows() {
        let labelArray = TestHelpers.getAllAccessibilityLabelsInWindows();
        print("labelArray = \(labelArray)")
    }
    
    public static func clearAndSetUpStack() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!);
        MageInitializer.initializePreferences();
        MagicalRecord.cleanUp();
        MagicalRecord.setupCoreDataStackWithInMemoryStore();
    }
    
    public static func cleanUpStack() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!);
        MageInitializer.initializePreferences();
        MagicalRecord.cleanUp();
    }
}
