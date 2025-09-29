//
//  TestingAppDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 9/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import GeoPackage

@objc(TestingAppDelegate)
class TestingAppDelegate: AppDelegate {
    @objc dynamic var logoutCalled = false
    
    private var backgroundOverlay: BaseMapOverlay?
    private var darkBackgroundOverlay: BaseMapOverlay?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        MageInitializer.initializePreferences()
        backgroundOverlay = MageInitializer.getBaseMap()
        darkBackgroundOverlay = MageInitializer.getDarkBaseMap()
        
        // Ensure a key window exists for KIF/UIKit assumptions
        let win = UIWindow(frame: UIScreen.main.bounds)
        win.rootViewController = UIViewController()
        win.makeKeyAndVisible()
        self.window = win
        
        return true
    }
    
    // No-ops to match the old Obj-C stubs (kept for parity)
    override func applicationDidBecomeActive(_ application: UIApplication) {}
    override func applicationWillEnterForeground(_ application: UIApplication) {}
    override func applicationDidEnterBackground(_ application: UIApplication) {}
    override func applicationWillResignActive(_ application: UIApplication) {}
    override func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {}
    override func applicationWillTerminate(_ application: UIApplication) {}
    
    // Test hooks
    @objc override func logout() { logoutCalled = true }
    @objc override func getBaseMap() -> BaseMapOverlay! { MageInitializer.getBaseMap() }
    @objc override func getDarkBaseMap() -> BaseMapOverlay! { MageInitializer.getDarkBaseMap() }
}

@objc(ViewLoaderAppDelegate)
final class ViewLoaderAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        // Provide a simple view host if you need it
        win.rootViewController = UIViewController()
        win.makeKeyAndVisible()
        window = win
        return true
    }
}
