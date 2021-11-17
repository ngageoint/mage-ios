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
//import Nimble_Snapshots
import Kingfisher

@testable import MAGE

class TestHelpers {
    
    public static func getKeyWindowVisible() -> UIWindow {
        var window: UIWindow;
        if (UIApplication.shared.windows.count == 0) {
            window = UIWindow(forAutoLayout: ());
            window.autoSetDimensions(to: UIScreen.main.bounds.size);
        } else {
            NSLog("There are \(UIApplication.shared.windows.count) windows");
            if (UIApplication.shared.windows.count != 1) {
                NSLog("Windows are \(UIApplication.shared.windows)")
            }
            window = UIApplication.shared.windows[0];
        }
        window.backgroundColor = .systemBackground;
        window.makeKeyAndVisible();
        return window;
    }
    
    public static func createGradientImage(startColor: UIColor, endColor: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = rect
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return UIImage() }
        return UIImage(cgImage: cgImage)
    }

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
            print("window \(window)")
            labelArray += getAllAccessibilityLabels(window as! UIWindow )
        }
        
        return labelArray
    }
    
    public static func printAllAccessibilityLabelsInWindows() {
        let labelArray = TestHelpers.getAllAccessibilityLabelsInWindows();
        NSLog("labelArray = \(labelArray)")
    }
    
    public static func clearImageCache() {
        ImageCache.default.clearCache();
    }
    
    public static func resetUserDefaults() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!);
        UserDefaults.standard.synchronize();
        MageInitializer.initializePreferences();
    }
    
    public static func clearDocuments() {
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
        
    }
    
    @discardableResult
    public static func clearAndSetUpStack() -> [String: Bool] {
        TestHelpers.clearDocuments();
        TestHelpers.clearImageCache();
        TestHelpers.resetUserDefaults();
        return MageCoreDataFixtures.clearAllData();
//        MagicalRecord.cleanUp();
        
//        MagicalRecord.deleteAndSetupMageCoreDataStack();
//        MagicalRecord.setupCoreDataStack();
//        MagicalRecord.setupCoreDataStackWithInMemoryStore();
//        MagicalRecord.setLoggingLevel(.verbose);
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
