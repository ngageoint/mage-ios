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
import Kingfisher

@testable import MAGE

class TestCoreDataStack: NSObject {
    // this is static to only load one model because even when the data store is reset
    // it keeps the model around :shrug: but resetting does clear all data
    static let momd = NSManagedObjectModel.mergedModel(from: [.main])
    var managedObjectModel: NSManagedObjectModel?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.shouldAddStoreAsynchronously = false
        let bundle: Bundle = .main
        let container = NSPersistentContainer(name: "mage-ios-sdk", managedObjectModel: TestCoreDataStack.momd!)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    func reset() {
        do {
            for currentStore in persistentContainer.persistentStoreCoordinator.persistentStores {
                try persistentContainer.persistentStoreCoordinator.remove(currentStore)
                if let currentStoreURL = currentStore.url {
                    try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: currentStoreURL, type: .sqlite)
                    
                }
            }
        } catch {
            print("Exception destroying \(error)")
        }
    }
}

extension XCTestCase {
    /// Creates an expectation for monitoring the given condition.
    /// - Parameters:
    ///   - condition: The condition to evaluate to be `true`.
    ///   - description: A string to display in the test log for this expectation, to help diagnose failures.
    /// - Returns: The expectation for matching the condition.
    func expectation(for condition: @autoclosure @escaping () -> Bool, description: String = "") -> XCTestExpectation {
        let predicate = NSPredicate { _, _ in
            return condition()
        }
        
        return XCTNSPredicateExpectation(predicate: predicate, object: nil)
    }
}

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
        NSLog("labelArray = \(labelArray ?? [])")
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
            let geopackagesDirectory = documentsDirectory.appendingPathComponent("geopackages");
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
            
            do {
                try FileManager.default.removeItem(at: geopackagesDirectory);
            } catch {
                print("Failed to remove geopackages directory.  Moving on.")
            }
        }
        
    }
    
    static var coreDataStack: TestCoreDataStack?
    static var context: NSManagedObjectContext?
    
    @discardableResult
    public static func clearAndSetUpStack() -> [String: Bool] {
        TestHelpers.clearDocuments();
        TestHelpers.clearImageCache();
        TestHelpers.resetUserDefaults();
        return [:]
    }
    
    public static func cleanUpStack() {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments");
            let eventsDirectory = documentsDirectory.appendingPathComponent("events")
            let geopackagesDirectory = documentsDirectory.appendingPathComponent("geopackages");
            try? FileManager.default.removeItem(at: attachmentsDirectory);
            try? FileManager.default.removeItem(at: eventsDirectory);
            try? FileManager.default.removeItem(at: geopackagesDirectory)
        }
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!);
        MageInitializer.initializePreferences();
        InjectedValues[\.nsManagedObjectContext] = nil
        coreDataStack!.reset()
        
//        if (NSManagedObjectContext.mr_default() != nil) {
//            NSManagedObjectContext.mr_default().reset();
//        }
        MagicalRecord.cleanUp();
    }
}
