//
//  SettingsLocalDataSourceTests.swift
//  MAGETests
//
//

import XCTest

@testable import MAGE

final class SettingsLocalDataSourceTests: MageCoreDataTestCase {

    func testGetSettings() async {
        let localDataSource: SettingsLocalDataSource = SettingsLocalDataSourceImpl()
        var settings = await localDataSource.getSettings()
        XCTAssertNil(settings)
        
        context.performAndWait {
            let newSettings = Settings(context: self.context)
            newSettings.mapSearchType = .native
            newSettings.mapSearchUrl = "https://magetest/search"
            
            try? context.obtainPermanentIDs(for: [newSettings])
            try? context.save()
        }
        
        settings = await localDataSource.getSettings()
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.mapSearchType, .native)
        XCTAssertEqual(settings?.mapSearchUrl, "https://magetest/search")
    }
    
    func testObserveSettings() async {
        let localDataSource: SettingsLocalDataSource = SettingsLocalDataSourceImpl()
        var settingsModel: SettingsModel?
        
        let expectNilSettings = expectation(description: "Settings should be nil")
        let expectNotNilSettings = expectation(description: "Settings should not be nil")
        _ = localDataSource.getSettingsPublisher().sink { settings in
            settingsModel = settings
            if settings != nil {
                expectNotNilSettings.fulfill()
            } else {
                expectNilSettings.fulfill()
            }
        }
        
        await fulfillment(of: [expectNilSettings])
        
        context.performAndWait {
            let newSettings = Settings(context: self.context)
            newSettings.mapSearchType = .native
            newSettings.mapSearchUrl = "https://magetest/search"
            
            try? context.obtainPermanentIDs(for: [newSettings])
            try? context.save()
        }
        
        await fulfillment(of: [expectNotNilSettings])
        XCTAssertNotNil(settingsModel)
        XCTAssertEqual(settingsModel?.mapSearchType, .native)
        XCTAssertEqual(settingsModel?.mapSearchUrl, "https://magetest/search")
    }
    
    func testObserveSettingsWithExistingValue() async {
        context.performAndWait {
            let newSettings = Settings(context: self.context)
            newSettings.mapSearchType = .native
            newSettings.mapSearchUrl = "https://magetest/search"
            
            try? context.obtainPermanentIDs(for: [newSettings])
            try? context.save()
        }
        
        let localDataSource: SettingsLocalDataSource = SettingsLocalDataSourceImpl()
        var settingsModel: SettingsModel?
        
        let expectNativeSearchSettings = expectation(description: "Settings search should be native")
        let expectNominatimSearchSettings = expectation(description: "Settings search should be nominatim")
        
        _ = localDataSource.getSettingsPublisher().sink { settings in
            settingsModel = settings
            if let settings {
                if settings.mapSearchType == .native {
                    expectNativeSearchSettings.fulfill()
                } else if settings.mapSearchType == .nominatim {
                    expectNominatimSearchSettings.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectNativeSearchSettings])
        XCTAssertNotNil(settingsModel)
        XCTAssertEqual(settingsModel?.mapSearchType, .native)
        XCTAssertEqual(settingsModel?.mapSearchUrl, "https://magetest/search")
        
        context.performAndWait {
            let settings = try? context.fetchFirst(Settings.self)
            settings?.mapSearchType = .nominatim
            settings?.mapSearchUrl = "https://magetest/nominatim"
            
            try? context.save()
        }
        
        await fulfillment(of: [expectNominatimSearchSettings])
        XCTAssertNotNil(settingsModel)
        XCTAssertEqual(settingsModel?.mapSearchType, .nominatim)
        XCTAssertEqual(settingsModel?.mapSearchUrl, "https://magetest/nominatim")
    }
    
    func testObserveSettingsDeletingAValue() async {
        context.performAndWait {
            let newSettings = Settings(context: self.context)
            newSettings.mapSearchType = .native
            newSettings.mapSearchUrl = "https://magetest/search"
            
            try? context.obtainPermanentIDs(for: [newSettings])
            try? context.save()
        }
        
        let localDataSource: SettingsLocalDataSource = SettingsLocalDataSourceImpl()
        var settingsModel: SettingsModel?
        
        let expectNilSettings = expectation(description: "Settings should be nil")
        let expectNotNilSettings = expectation(description: "Settings should not be nil")
        _ = localDataSource.getSettingsPublisher().sink { settings in
            settingsModel = settings
            if settings != nil {
                expectNotNilSettings.fulfill()
            } else {
                expectNilSettings.fulfill()
            }
        }
        
        await fulfillment(of: [expectNotNilSettings])
        
        XCTAssertNotNil(settingsModel)
        XCTAssertEqual(settingsModel?.mapSearchType, .native)
        XCTAssertEqual(settingsModel?.mapSearchUrl, "https://magetest/search")
        
        context.performAndWait {
            if let settings = try? context.fetchFirst(Settings.self) {
                context.delete(settings)
            }
            
            try? context.save()
        }
        
        await fulfillment(of: [expectNilSettings])
        XCTAssertNil(settingsModel)
    }
}
