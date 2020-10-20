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
                    MageCoreDataFixtures.quietLogging();
                    UserDefaults.standard.set(nil, forKey: "selectedFeeds-1");
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
                    fatalError("feeds.json not found")
                }
                
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert feeds.json to String")
                }
                                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert feeds.json to Data")
                }
                
                guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
                    fatalError("Unable to convert feeds.json to JSON dictionary")
                }
                
                return jsonDictionary;
            }
            
            func loadFeedItemsJson() -> Array<Any> {
                guard let pathString = Bundle(for: type(of: self)).path(forResource: "feedContent", ofType: "json") else {
                    fatalError("feedContent.json not found")
                }
                
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert feedContent.json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert feedContent.json to Data")
                }
                
                guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Dictionary<String, Any> else {
                    fatalError("Unable to convert feedContent.json to JSON dictionary")
                }
                                
                return (jsonDictionary["items"] as! Dictionary<String, Any>)["features"] as! Array<Any>;
            }
            
            it("should populate feeds from json all new") {
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext)
                        expect(remoteIds) == ["0","1","2","3"];
                    }) { (success, error) in
                        done();
                    }
                }
                let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
                expect(selectedFeeds) == ["0","1","2","3"];
            }
            
            it("should populate feeds from json removing old feeds") {
                UserDefaults.standard.set(["6","7"], forKey: "selectedFeeds");
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext)
                        expect(remoteIds) == ["0","1","2","3"];
                    }) { (success, error) in
                        done();
                    }
                }
                let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
                expect(selectedFeeds) == ["0","1","2","3"];
            }
            
            it("should populate feeds from json adding new feeds") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed2", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                
                UserDefaults.standard.set(["1","2"], forKey: "selectedFeeds-1");
                waitUntil(timeout: DispatchTimeInterval.seconds(10000)) { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext)
                        expect(remoteIds) == ["0","1","2","3"];
                    }) { (success, error) in
                        done();
                    }
                }
                let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
                expect(selectedFeeds) == ["1","2","0","3"];
            }
            
            it("should populate feeds from json adding new feeds with old feeds not selected") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed2", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                
                UserDefaults.standard.setValue([], forKey: "selectedFeeds-1");

                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext)
                        expect(remoteIds) == ["0","1","2","3"];
                    }) { (success, error) in
                        done();
                    }
                }
                let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
                expect(selectedFeeds) == ["0","3"];
            }
            
            it("should populate feeds from json adding new feeds with some old feeds not selected") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed2", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }

                UserDefaults.standard.set(["2"], forKey: "selectedFeeds-1");
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext)
                        expect(remoteIds) == ["0","1","2","3"];
                    }) { (success, error) in
                        done();
                    }
                }
                let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
                expect(selectedFeeds) == ["2","0","3"];
            }
            
            it("should populate feed items from json all new") {
                var feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

                waitUntil { done in
                    let feedItems = loadFeedItemsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeedItems(fromJson: feedItems as! [Any], inFeedId: "1", in: localContext)
                        expect(remoteIds as? [String]) == feedItemIds;
                    }) { (success, error) in
                        done();
                    }
                }

                for feedItem: FeedItem in FeedItem.mr_findAll()! as! [FeedItem] {
                    expect(feedItemIds as NMBContainer).to(contain(feedItem.remoteId));
                    feedItemIds.remove(at: feedItemIds.lastIndex(of: feedItem.remoteId!)!);
                }

                expect(feedItemIds.isEmpty) == true;
            }
            
            it("should populate feed items from json removing old") {

                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445]) { (success: Bool, error: Error?) in
                        done();
                    }
                }

                var feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

                waitUntil { done in
                    let feedItems = loadFeedItemsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds = Feed.populateFeedItems(fromJson: feedItems as! [Any], inFeedId: "1", in: localContext)
                        expect(remoteIds as? [String]) == feedItemIds;
                    }) { (success, error) in
                        done();
                    }
                }

                for feedItem: FeedItem in FeedItem.mr_findAll()! as! [FeedItem] {
                    expect(feedItemIds as NMBContainer).to(contain(feedItem.remoteId));
                    feedItemIds.remove(at: feedItemIds.lastIndex(of: feedItem.remoteId!)!);
                }

                expect(feedItemIds.isEmpty) == true;
            }
            
            it("should get feed items for feed") {

                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445]) { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "2", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593441445]) { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }

                var feedItemIds: [String] = ["1","2"];

                for feedItem: FeedItem in FeedItem.getFeedItems(forFeed: 1) {
                    expect(feedItemIds as NMBContainer).to(contain(feedItem.remoteId));
                    feedItemIds.remove(at: feedItemIds.lastIndex(of: feedItem.remoteId!)!);
                }

                expect(feedItemIds.isEmpty) == true;
            }
        }
    }
}
