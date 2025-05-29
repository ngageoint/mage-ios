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

class FeedTests: MageCoreDataTestCase {
    
    override open func setUp() {
        super.setUp()
        let emptyFeeds: [String]? = nil
        UserDefaults.standard.set(emptyFeeds, forKey: "selectedFeeds-1");
        UserDefaults.standard.baseServerUrl = "https://magetest";
        
        Server.setCurrentEventId(1);
            
        MageCoreDataFixtures.addEvent();
    }
    
    override open func tearDown() {
        super.tearDown()
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
     
    func testShouldPopulateFeedsFromJsonAllNew() {
//            it("should populate feeds from json all new") {
        let feeds = loadFeedsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeeds(feeds: feeds as! [[AnyHashable : Any]], eventId: 1, context: localContext)
            expect(remoteIds) == ["0","1","2","3"];
        })
        let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
        expect(selectedFeeds) == ["0","1","2","3"];
    }
            
    
    func testShouldPopulateFeedsFromJsonRemovingOldFeeds() {
//            it("should populate feeds from json removing old feeds") {
        UserDefaults.standard.set(["6","7"], forKey: "selectedFeeds");
        let feeds = loadFeedsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeeds(feeds: feeds as! [[AnyHashable : Any]], eventId: 1, context: localContext)
            expect(remoteIds) == ["0","1","2","3"];
        })
        let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
        expect(selectedFeeds) == ["0","1","2","3"];
    }
            
    func testShouldPopulateFeedsFromJsonAddingNewFeeds() {
//            it("should populate feeds from json adding new feeds") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed2", primaryProperty: "primary", secondaryProperty: "secondary")
        
        UserDefaults.standard.set(["1","2"], forKey: "selectedFeeds-1");
        let feeds = loadFeedsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeeds(feeds: feeds as! [[AnyHashable :Any]], eventId: 1, context: localContext)
            expect(remoteIds) == ["0","1","2","3"];
        })
        let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
        expect(selectedFeeds) == ["1","2","0","3"];
    }
            
    func testShouldPopulateFeedsFromJsonAddingNewFeedsWithOldFeedsNotSelected() {
//            it("should populate feeds from json adding new feeds with old feeds not selected") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed2", primaryProperty: "primary", secondaryProperty: "secondary")
        
        UserDefaults.standard.setValue([], forKey: "selectedFeeds-1");

        let feeds = loadFeedsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: localContext)
            expect(remoteIds) == ["0","1","2","3"];
        })
        let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
        expect(selectedFeeds) == ["0","3"];
    }
            
    
    func testShouldPopulateFeedsFromJsonAddingNewFeedsWithSomeOldFeedsNotSelected() {
//            it("should populate feeds from json adding new feeds with some old feeds not selected") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed2", primaryProperty: "primary", secondaryProperty: "secondary")

        UserDefaults.standard.set(["2"], forKey: "selectedFeeds-1");
        let feeds = loadFeedsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: localContext)
            expect(remoteIds) == ["0","1","2","3"];
        })
        let selectedFeeds: [String] = UserDefaults.standard.object(forKey: "selectedFeeds-1") as! [String];
        expect(selectedFeeds) == ["2","0","3"];
    }
            
    func testShouldPopulateFeedItemsFromJsonAllNew() {
//            it("should populate feed items from json all new") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        var feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

        let feedItems = loadFeedItemsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeedItems(feedItems: feedItems as! [[AnyHashable:Any]], feedId: "1", eventId: 1, context: localContext)
            print("Remote ids \(remoteIds)")
            expect(remoteIds) == feedItemIds;
        })

        for feedItem: FeedItem in FeedItem.mr_findAll()! as! [FeedItem] {
            expect(feedItemIds as NMBContainer).to(contain(feedItem.remoteId));
            feedItemIds.remove(at: feedItemIds.lastIndex(of: feedItem.remoteId!)!);
        }

        expect(feedItemIds.isEmpty) == true;
    }
            
    func testShouldPopulateFeedItemsFromJsonRemovingOld() {
//            it("should populate feed items from json removing old") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])

        var feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

        let feedItems = loadFeedItemsJson();
        MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeedItems(feedItems: feedItems as! [[AnyHashable:Any]], feedId: "1", eventId: 1, context: localContext)
            expect(remoteIds) == feedItemIds;
        })

        for feedItem: FeedItem in FeedItem.mr_findAll()! as! [FeedItem] {
            expect(feedItemIds as NMBContainer).to(contain(feedItem.remoteId));
            feedItemIds.remove(at: feedItemIds.lastIndex(of: feedItem.remoteId!)!);
        }

        expect(feedItemIds.isEmpty) == true;
    }
            
    func testShouldGetFeedItemsForFeed() {
//            it("should get feed items for feed") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "2", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593441445])

        var feedItemIds: [String] = ["1","2"];

        for feedItem: FeedItemAnnotation in FeedItem.getFeedItems(feedId: "1", eventId: 1)! {
            expect(feedItemIds as NMBContainer).to(contain(feedItem.remoteId));
            feedItemIds.remove(at: feedItemIds.lastIndex(of: feedItem.remoteId!)!);
        }

        expect(feedItemIds.isEmpty) == true;
    }
}
