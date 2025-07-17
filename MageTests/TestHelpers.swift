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
import OSLog

import XCTest
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
    public static func setupAuthenticatedSession() {
        MageSessionManager.shared()?.setToken("TOKEN")
        StoredPassword.persistToken(toKeyChain: "TOKEN")
        UserDefaults.standard.set("https://magetest", forKey: "baseServerUrl")
        UserDefaults.standard.set(true, forKey: "deviceRegistered")
    }
    
    @MainActor
    public static func setupNavigationController() -> UINavigationController {
        let navigationController = UINavigationController()
        let window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = navigationController
        return navigationController
    }
    
    @MainActor
    public static func setupTestSession() {
        setupAuthenticatedSession()
        MockMageServer.stubAPIResponses()
    }
    
    @MainActor
    public static func initializeTestNavigation() -> UINavigationController {
        return setupNavigationController()
    }

//    @MainActor
//    public static func executeTestLogin(coordinator: AuthenticationCoordinator, expectation: XCTestExpectation? = nil) {
//        let loginDelegate = coordinator as! LoginDelegate
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": "6.0.0"
//        ]
//
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS, "Authentication failed")
//            expectation?.fulfill()
//        }
//    }

    
    @MainActor
    public static func handleDisclaimerAcceptance(coordinator: AuthenticationCoordinator, navigationController: UINavigationController) async {
        await waitForCondition({
            navigationController.topViewController is DisclaimerViewController
        }, timeout: 2, message: "Disclaimer screen never appeared")

        let disclaimerDelegate = coordinator as! DisclaimerDelegate
        disclaimerDelegate.disclaimerAgree()
    }

    @MainActor
    public static func waitForAuthenticationSuccess(delegate: MockAuthenticationCoordinatorDelegate) async {
        await waitForCondition({
            delegate.authenticationSuccessfulCalled
        }, timeout: 2, message: "authenticationSuccessful was never called")
    }

    
    @MainActor
    public static func getKeyWindowVisibleMainActor() -> UIWindow {
        var window: UIWindow;
        if (UIApplication.shared.windows.count == 0) {
            window = UIWindow(forAutoLayout: ());
            window.autoSetDimensions(to: UIScreen.main.bounds.size);
        } else {
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
            labelArray += getAllAccessibilityLabels(window as! UIWindow )
        }
        
        return labelArray
    }
    
    public static func printAllAccessibilityLabelsInWindows() {
        let labelArray = TestHelpers.getAllAccessibilityLabelsInWindows();
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
                os_log("Failed to remove attachments directory.  Moving on.")
            }
            
            do {
                try FileManager.default.removeItem(at: eventsDirectory);
            } catch {
                os_log("Failed to remove events directory.  Moving on.")
            }
            
            do {
                try FileManager.default.removeItem(at: geopackagesDirectory);
            } catch {
                os_log("Failed to remove geopackages directory.  Moving on.")
            }
            
            do {
                try FileManager.default.removeItem(at: mapCacheDirectory);
            } catch {
                os_log("Failed to remove geopackages directory.  Moving on.")
            }
        }
        
    }
    
    static var coreDataStack: TestCoreDataStack?
    static var context: NSManagedObjectContext?
    
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

extension TestHelpers {
    @MainActor
    static func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval, message: String) async {
        let startTime = Date()
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail(message)
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
        }
    }

    @MainActor
    static func awaitBlockTrue(block: @escaping () -> Bool, timeout: TimeInterval) async {
        let startTime = Date()
        
        while !block() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timeout waiting for condition to be true")
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds delay
        }
    }

    @MainActor
    static func waitForLoginScreen(navigationController: UINavigationController, timeout: TimeInterval = 2) async {
        await awaitBlockTrue(block: {
            navigationController.topViewController is LoginViewController
        }, timeout: timeout)
    }

    static func getTestServer() async -> MageServer {
        let url = MageServer.baseURL()
        return await withCheckedContinuation { continuation in
            MageServer.server(url: url) { server in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail("Failed to create test MageServer instance")
            }
        }
    }
}

//extension TestHelpers {
//    static func executeTestLoginForRegistration(coordinator: AuthenticationCoordinator, expectation: XCTestExpectation) {
//        let loginDelegate = coordinator as! LoginDelegate
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": "6.0.0"
//        ]
//
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.REGISTRATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
//            expectation.fulfill()
//        }
//    }
//}

extension TestHelpers {
    @MainActor
    static func waitForDisclaimerScreen(navigationController: UINavigationController) async {
        await waitForCondition({
            navigationController.topViewController is DisclaimerViewController
        }, timeout: 2, message: "Disclaimer screen never appeared")

        await waitForCondition({
            guard let topView = navigationController.topViewController?.view else { return false }
            return viewHasAccessibilityLabel(topView, label: "disclaimer title") &&
                   viewHasAccessibilityLabel(topView, label: "disclaimer text")
        }, timeout: 2, message: "Disclaimer text/title not found")
    }

    private static func viewHasAccessibilityLabel(_ view: UIView, label: String) -> Bool {
        if view.accessibilityLabel == label {
            return true
        }
        for subview in view.subviews {
            if viewHasAccessibilityLabel(subview, label: label) {
                return true
            }
        }
        return false
    }
}

extension TestHelpers {
    static func defaultLoginParameters(username: String = "test", password: String = "test") -> [String: Any] {
        return [
            "username": username,
            "password": password,
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
    }
}
