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
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
            let eventsDirectory = documentsDirectory.appendingPathComponent("events");
            do {
                try FileManager.default.removeItem(at: attachmentsDirectory);
            } catch {
                print("Failed to remove attachments directory.  Moving on.")
            }
            
            do {
                try FileManager.default.removeItem(at: eventsDirectory);
            } catch {
                print("Failed to remove events directory.  Moving on.")
            }
        }
        
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!);
        UserDefaults.standard.synchronize();
        MageInitializer.initializePreferences();
        MagicalRecord.cleanUp();
        
//        MagicalRecord.deleteAndSetupMageCoreDataStack();
//        MagicalRecord.setupCoreDataStack();
        MagicalRecord.setupCoreDataStackWithInMemoryStore();
        MagicalRecord.setLoggingLevel(.verbose);
    }
    
    public static func cleanUpStack() {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
            let eventsDirectory = documentsDirectory.appendingPathComponent("events");
            do {
                try FileManager.default.removeItem(at: attachmentsDirectory);
                try FileManager.default.removeItem(at: eventsDirectory);
            } catch {
                print("Failed to remove events or attachments directory.  Moving on.")
            }
        }
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!);
        MageInitializer.initializePreferences();
        
//        if (NSManagedObjectContext.mr_default() != nil) {
//            NSManagedObjectContext.mr_default().reset();
//        }
        MagicalRecord.cleanUp();
    }
}
