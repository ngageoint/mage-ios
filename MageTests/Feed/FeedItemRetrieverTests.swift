//
//  FeedItemRetrieverTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import MagicalRecord

@testable import MAGE

class MockFeedItemDelegate: NSObject, FeedItemDelegate {
    var lastFeedItemAdded: FeedItem?;
    var lastFeedItemRemoved: FeedItem?;
    
    func addFeedItem(feedItem: FeedItem) {
        lastFeedItemAdded = feedItem;
    }
    func removeFeedItem(feedItem: FeedItem) {
        lastFeedItemRemoved = feedItem;
    }
}

@available(iOS 13.0, *)
class FeedItemRetrieverTests: KIFSpec {
    
    override func spec() {
        
        describe("FeedItemRetrieverTests") {
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                
                waitUntil { done in
                    clearAndSetUpStack();
                    MageCoreDataFixtures.quietLogging();
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
            
            it("should get feed item retrievers") {
                var feedIds: [String] = ["0","1","2","3"];
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext) as! [String]
                        expect(remoteIds) == feedIds;
                    }) { (success, error) in
                        done();
                    }
                }
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetrievers: [FeedItemRetriever] = FeedItemRetriever.createFeedItemRetrievers(delegate: feedItemDelegate);
                for retriever in feedItemRetrievers {
                    expect(feedIds).to(contain(retriever.feed.remoteId));
                    feedIds.remove(at: feedIds.lastIndex(of: retriever.feed.remoteId!)!);
                }
                expect(feedIds.isEmpty) == true;
            }
            
            it("should get mappable feed item retrievers") {
                var feedIds: [String] = ["0","1","2","3"];
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext) as! [String]
                        expect(remoteIds) == feedIds;
                    }) { (success, error) in
                        done();
                    }
                }
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetrievers: [FeedItemRetriever] = FeedItemRetriever.createFeedItemRetrievers(delegate: feedItemDelegate);
                for retriever in feedItemRetrievers {
                    expect(feedIds).to(contain(retriever.feed.remoteId));
                    feedIds.remove(at: feedIds.lastIndex(of: retriever.feed.remoteId!)!);
                }
                expect(feedIds.isEmpty) == true;
                
                var mappableFeedIds: [String] = ["0","1"];
                let mappableFeedItemRetrievers: [FeedItemRetriever] = FeedItemRetriever.createMappableFeedItemRetrievers(delegate: feedItemDelegate);
                for retriever in mappableFeedItemRetrievers {
                    expect(mappableFeedIds).to(contain(retriever.feed.remoteId));
                    mappableFeedIds.remove(at: mappableFeedIds.lastIndex(of: retriever.feed.remoteId!)!);
                }
                expect(mappableFeedIds.isEmpty) == true;
            }
            
            it("should get one mappable feed item retriever") {
                let feedIds: [String] = ["0","1","2","3"];
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext) as! [String]
                        expect(remoteIds) == feedIds;
                    }) { (success, error) in
                        done();
                    }
                }
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetriever: FeedItemRetriever = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", delegate: feedItemDelegate)!;
                expect(feedItemRetriever.feed.remoteId) == "1"
            }
            
            it("should return nil if no feed exists") {
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetriever: FeedItemRetriever? = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", delegate: feedItemDelegate);
                expect(feedItemRetriever).to(beNil());
            }
            
            it("should get one mappable feed item retriever and start it with no initial items add one") {
                let feedIds: [String] = ["0","1","2","3"];
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext) as! [String]
                        expect(remoteIds) == feedIds;
                    }) { (success, error) in
                        done();
                    }
                }
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetriever: FeedItemRetriever = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", delegate: feedItemDelegate)!;
                expect(feedItemRetriever.feed.remoteId) == "1"
                
                let firstFeedItems: [FeedItem]? = feedItemRetriever.startRetriever();
                expect(firstFeedItems).to(beEmpty());
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                expect(feedItemDelegate.lastFeedItemAdded?.remoteId) == "4";
                expect(feedItemDelegate.lastFeedItemRemoved).to(beNil());
            }
            
            it("should get one mappable feed item retriever and start it with no initial items add one remove one") {
                let feedIds: [String] = ["0","1","2","3"];
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext) as! [String]
                        expect(remoteIds) == feedIds;
                    }) { (success, error) in
                        done();
                    }
                }
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetriever: FeedItemRetriever = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", delegate: feedItemDelegate)!;
                expect(feedItemRetriever.feed.remoteId) == "1"
                
                let firstFeedItems: [FeedItem]? = feedItemRetriever.startRetriever();
                expect(firstFeedItems).to(beEmpty());
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                expect(feedItemDelegate.lastFeedItemAdded?.remoteId) == "4";
                expect(feedItemDelegate.lastFeedItemRemoved).to(beNil());
                waitUntil { done in
                MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                    let deleted = feedItemDelegate.lastFeedItemAdded!.mr_deleteEntity();
                    expect(deleted) == true;
                }, completion: { (success: Bool, error: Error?) in
                    done();
                });
                }
                
                expect(feedItemDelegate.lastFeedItemAdded?.remoteId) == "4";
                expect(feedItemDelegate.lastFeedItemRemoved?.remoteId) == "4";
            }
            
            it("should get one mappable feed item retriever and start it with no initial items add one then update it") {
                let feedIds: [String] = ["0","1","2","3"];
                waitUntil { done in
                    let feeds = loadFeedsJson();
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let remoteIds: [String] = Feed.populateFeeds(fromJson: feeds as! [Any], inEventId: 1, in: localContext) as! [String]
                        expect(remoteIds) == feedIds;
                    }) { (success, error) in
                        done();
                    }
                }
                let feedItemDelegate = MockFeedItemDelegate();
                
                let feedItemRetriever: FeedItemRetriever = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", delegate: feedItemDelegate)!;
                expect(feedItemRetriever.feed.remoteId) == "1"
                
                let firstFeedItems: [FeedItem]? = feedItemRetriever.startRetriever();
                expect(firstFeedItems).to(beEmpty());
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                expect(feedItemDelegate.lastFeedItemAdded?.remoteId) == "4";
                expect(feedItemDelegate.lastFeedItemRemoved).to(beNil());
                waitUntil { done in
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        feedItemDelegate.lastFeedItemAdded!.geometry = nil;
                    }, completion: { (success: Bool, error: Error?) in
                        done();
                    });
                }
                
                expect(feedItemDelegate.lastFeedItemAdded?.remoteId) == "4";
                expect(feedItemDelegate.lastFeedItemRemoved?.remoteId) == "4";
            }
        }
    }
}
