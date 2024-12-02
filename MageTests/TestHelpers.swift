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
    @MainActor
    public static func getKeyWindowVisibleMainActor() -> UIWindow {
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
            let mapCacheDirectory = documentsDirectory.appendingPathComponent("MapCache");
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
            
            do {
                try FileManager.default.removeItem(at: mapCacheDirectory);
            } catch {
                print("Failed to remove geopackages directory.  Moving on.")
            }
        }
        
    }
    
    static var coreDataStack: TestCoreDataStack?
    static var context: NSManagedObjectContext?
    
//    @discardableResult
//    public static func clearAndSetUpStack() -> [String: Bool] {
//        TestHelpers.clearDocuments();
//        TestHelpers.clearImageCache();
//        TestHelpers.resetUserDefaults();
//        return [:]
//    }
    
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
    
    static func setupValidToken() {
        MageSessionManager.shared().setToken("NewToken")
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        UserUtility.singleton.resetExpiration()
    }
    
    static func setupExpiredToken() {
        MageSessionManager.shared().setToken("NewToken")
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(-1000000)
        ]
        UserUtility.singleton.resetExpiration()
    }
    
    static func loadJsonFile(_ filename: String) -> [AnyHashable: Any]? {
        if let path = Bundle(for: TestHelpers.self).path(forResource: filename, ofType: "json") {
            let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            return jsonResult as? [AnyHashable: Any]
        }
        return nil
    }
    
    static func injectionSetup() {
        defaultObservationInjection()
        defaultImportantInjection()
        defaultObservationFavoriteInjection()
        defaultEventInjection()
        defaultUserInjection()
        defaultFormInjection()
        defaultAttachmentInjection()
        defaultRoleInjection()
        defaultLocationInjection()
        defaultObservationImageInjection()
        defaultStaticLayerInjection()
        defaultGeoPackageInjection()
        defaultFeedItemInjection()
        defaultObservationLocationInjection()
        defaultObservationIconInjection()
        defaultLayerInjection()
    }
    
    static func clearAndSetUpStack() {
        TestHelpers.clearDocuments();
        TestHelpers.clearImageCache();
        TestHelpers.resetUserDefaults();
    }
    
    static func defaultObservationInjection() {
        InjectedValues[\.observationLocalDataSource] = ObservationCoreDataDataSource()
        InjectedValues[\.observationRemoteDataSource] = ObservationRemoteDataSource()
        InjectedValues[\.observationRepository] = ObservationRepositoryImpl()
    }
    
    static func defaultImportantInjection() {
        InjectedValues[\.observationImportantLocalDataSource] = ObservationImportantCoreDataDataSource()
        InjectedValues[\.observationImportantRemoteDataSource] = ObservationImportantRemoteDataSource()
        InjectedValues[\.observationImportantRepository] = ObservationImportantRepositoryImpl()
    }
    
    static func defaultObservationFavoriteInjection() {
        InjectedValues[\.observationFavoriteLocalDataSource] = ObservationFavoriteCoreDataDataSource()
        InjectedValues[\.observationFavoriteRemoteDataSource] = ObservationFavoriteRemoteDataSource()
        InjectedValues[\.observationFavoriteRepository] = ObservationFavoriteRepositoryImpl()
    }
    
    static func defaultEventInjection() {
        InjectedValues[\.eventLocalDataSource] = EventCoreDataDataSource()
        InjectedValues[\.eventRepository] = EventRepositoryImpl()
    }
    
    static func defaultUserInjection() {
        InjectedValues[\.userLocalDataSource] = UserCoreDataDataSource()
        InjectedValues[\.userRemoteDataSource] = UserRemoteDataSourceImpl()
        InjectedValues[\.userRepository] = UserRepositoryImpl()
    }
    
    static func defaultFormInjection() {
        InjectedValues[\.formRepository] = FormRepositoryImpl()
        InjectedValues[\.formLocalDataSource] = FormCoreDataDataSource()
    }
    
    static func defaultAttachmentInjection() {
        InjectedValues[\.attachmentLocalDataSource] = AttachmentCoreDataDataSource()
        InjectedValues[\.attachmentRepository] = AttachmentRepositoryImpl()
    }
    
    static func defaultRoleInjection() {
        InjectedValues[\.roleLocalDataSource] = RoleCoreDataDataSource()
        InjectedValues[\.roleRepository] = RoleRepositoryImpl()
    }
    
    static func defaultLocationInjection() {
        InjectedValues[\.locationLocalDataSource] = LocationCoreDataDataSource()
        InjectedValues[\.locationRepository] = LocationRepositoryImpl()
    }
    
    static func defaultObservationImageInjection() {
        InjectedValues[\.observationImageRepository] = ObservationImageRepositoryImpl()
    }
    
    static func defaultStaticLayerInjection() {
        InjectedValues[\.staticLayerLocalDataSource] = StaticLayerCoreDataDataSource()
        InjectedValues[\.staticLayerRepository] = StaticLayerRepository()
    }
    
    static func defaultLayerInjection() {
        InjectedValues[\.layerLocalDataSource] = LayerLocalCoreDataDataSource()
        InjectedValues[\.layerRepository] = LayerRepositoryImpl()
    }
    
    static func defaultGeoPackageInjection() {
        if !(InjectedValues[\.geoPackageRepository] is GeoPackageRepositoryImpl) {
            InjectedValues[\.geoPackageRepository] = GeoPackageRepositoryImpl()
        }
    }
    
    static func defaultFeedItemInjection() {
        InjectedValues[\.feedItemRepository] = FeedItemRepositoryImpl()
        InjectedValues[\.feedItemLocalDataSource] = FeedItemStaticLocalDataSource()
    }
    
    static func defaultObservationLocationInjection() {
        InjectedValues[\.observationLocationLocalDataSource] = ObservationLocationCoreDataDataSource()
        InjectedValues[\.observationLocationRepository] = ObservationLocationRepositoryImpl()
    }
    
    static func defaultObservationIconInjection() {
        InjectedValues[\.observationIconLocalDataSource] = ObservationIconCoreDataDataSource()
        InjectedValues[\.observationIconRepository] = ObservationIconRepository()
    }
}
