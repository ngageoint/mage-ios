//
//  FeedTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import MagicalRecord

@testable import MAGE

@available(iOS 13.0, *)
class FeedTests: KIFSpec {
    
    override func spec() {
        
        describe("FeedTests") {
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                
                waitUntil { done in
                    clearAndSetUpStack();
//                    MageCoreDataFixtures.quietLogging();
                    UserDefaults.standard.set(nil, forKey: "selectedFeeds");
                    UserDefaults.standard.set("https://magetest", forKey: "baseServerUrl");
                    UserDefaults.standard.synchronize();
                    
                    Server.setCurrentEventId(1);
                    
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        done();
                    }
                }
            }
            
            afterEach {
                clearAndSetUpStack();
            }
            
            func loadFeedsJson() -> NSArray {
                guard let pathString = Bundle(for: type(of: self)).path(forResource: "feeds", ofType: "json") else {
                    fatalError("UnitTestData.json not found")
                }
                
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert UnitTestData.json to String")
                }
                                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert UnitTestData.json to Data")
                }
                
                guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
                    fatalError("Unable to convert UnitTestData.json to JSON dictionary")
                }
                
                return jsonDictionary;
            }
            
            it("should populate feeds from json all new") {
//                waitUntil { done in
//                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
//                        done();
//                    }
//                }
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext)
                        expect(remoteIds) == [0,1,2,3];
                    }) { (success, error) in
                        print("success \(success)");
                        print("error \(String(describing: error))");
                        done();
                    }
                }
                let selectedFeeds: [String: [Int]] = UserDefaults.standard.object(forKey: "selectedFeeds") as! [String : [Int]];
                expect(selectedFeeds) == ["1":[0,1,2,3]];
                print("Selected feeds \(selectedFeeds)");
            }
        }
    }
}
