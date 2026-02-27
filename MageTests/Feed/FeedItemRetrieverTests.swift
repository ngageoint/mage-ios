//
//  FeedItemRetrieverTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

/*  DISABLING TEST Because they are broken. Need to revisit later.
 
import Foundation
import Quick
import Nimble
import PureLayout
import MagicalRecord

@testable import MAGE

protocol FeedItemDelegate {
    func addFeedItem(_ feedItem: FeedItemAnnotation) //FeedItem)
    func removeFeedItem(_ feedItem: FeedItemAnnotation) //FeedItem)
}

class MockFeedItemDelegate: NSObject, FeedItemDelegate {
    
    var lastFeedItemAdded: FeedItemAnnotation?;
    var lastFeedItemRemoved: FeedItemAnnotation?;
    
    func addFeedItem(_ feedItem: FeedItemAnnotation) {
        lastFeedItemAdded = feedItem;
    }
    
    func removeFeedItem(_ feedItem: FeedItemAnnotation) {
        lastFeedItemRemoved = feedItem;
    }
}

class FeedItemRetrieverTests: MageCoreDataTestCase {
    
    override open func setUp() {
        super.setUp()
        
        let emptyFeeds: [String]? = nil
        UserDefaults.standard.set(emptyFeeds, forKey: "selectedFeeds");
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
    
//    override func spec() {
//        
//        describe("FeedItemRetrieverTests") {
//            
//            beforeEach {
//                let emptyFeeds: [String]? = nil
//                UserDefaults.standard.set(emptyFeeds, forKey: "selectedFeeds");
//                UserDefaults.standard.baseServerUrl = "https://magetest";
//                
//                Server.setCurrentEventId(1);
//                
//                MageCoreDataFixtures.addEvent();
//            }
//            

    func testShouldGetFeedItemRetrievers() {
//            it("should get feed item retrievers") {
        var feedIds: [String] = ["0","1","2","3"];
        let feeds = loadFeedsJson();
        guard let context = self.context else { return }
        
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
        let feedItemRetrievers: [FeedItemRetriever] = FeedItemRetriever.createFeedItemRetrievers();
        for retriever in feedItemRetrievers {
            expect(feedIds as NMBContainer).to(contain(retriever.feed.remoteId));
            feedIds.remove(at: feedIds.lastIndex(of: retriever.feed.remoteId!)!);
        }
        expect(feedIds.isEmpty) == true;
    }
            
    func testShouldGetMappableFeedItemRetrievers() {
//            it("should get mappable feed item retrievers") {
        var feedIds: [String] = ["0","1","2","3"];
        let feeds = loadFeedsJson();
        guard let context = self.context else { return }
        
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
        let feedItemRetrievers: [FeedItemRetriever] = FeedItemRetriever.createFeedItemRetrievers();
        for retriever in feedItemRetrievers {
            expect(feedIds as NMBContainer).to(contain(retriever.feed.remoteId));
            feedIds.remove(at: feedIds.lastIndex(of: retriever.feed.remoteId!)!);
        }
        expect(feedIds.isEmpty) == true;
        
        var mappableFeedIds: [String] = ["0","1"];
        let mappableFeedItemRetrievers: [FeedItemRetriever] = FeedItemRetriever.createMappableFeedItemRetrievers();
        for retriever in mappableFeedItemRetrievers {
            expect(mappableFeedIds as NMBContainer).to(contain(retriever.feed.remoteId));
            mappableFeedIds.remove(at: mappableFeedIds.lastIndex(of: retriever.feed.remoteId!)!);
        }
        expect(mappableFeedIds.isEmpty) == true;
    }
            
    func testShouldGetOneMappableFeedItemRetriever() {
//            it("should get one mappable feed item retriever") {
        let feedIds: [String] = ["0","1","2","3"];
        let feeds = loadFeedsJson();
        guard let context = self.context else { return }
        
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
        let feedItemRetriever: FeedItemRetriever? = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", eventId: 1);
        expect(feedItemRetriever).toNot(beNil());
        expect(feedItemRetriever?.feed.remoteId) == "1"
    }
            
    func testShouldReturnNilIfNoFeedExists() {
//            it("should return nil if no feed exists") {
        let feedItemRetriever: FeedItemRetriever? = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", eventId: 1);
        expect(feedItemRetriever).to(beNil());
    }
            
    func testShouldGetOneMappableFeedItemRetrieverAndStartItWithNoInitialItemsAddOne() {
//            it("should get one mappable feed item retriever and start it with no initial items add one") {
        let feedIds: [String] = ["0","1","2","3"];
        let feeds = loadFeedsJson();
        guard let context = self.context else { return }
        
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
        let feedItemRetriever: FeedItemRetriever? = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", eventId: 1);
        expect(feedItemRetriever).toNot(beNil());
        expect(feedItemRetriever?.feed.remoteId) == "1"
        
        let firstFeedItems: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever()
        
        expect(firstFeedItems).to(beEmpty());
        
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"])
        let updatedFeedItems: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever()
        expect(updatedFeedItems?.compactMap(\.remoteId)).to(contain("4"))
    }
            
    func testShouldGetOneMappableFeedItemRetrieverAndStartItWithNoInitialItemsAddOneRemoveOne() {
//            it("should get one mappable feed item retriever and start it with no initial items add one remove one") {
        let feedIds: [String] = ["0","1","2","3"];
        let feeds = loadFeedsJson();
        guard let context = self.context else { return }
        
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
        let feedItemRetriever: FeedItemRetriever? = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", eventId: 1);
        expect(feedItemRetriever).toNot(beNil());
        expect(feedItemRetriever?.feed.remoteId) == "1"
        
        let firstFeedItems: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever();
        expect(firstFeedItems).to(beEmpty());
        
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"])
        let addedFeedItems: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever();
        expect(addedFeedItems?.compactMap(\.remoteId)).to(contain("4"))
        guard let context = self.context else { return }
        
        context.performAndWait {
            let lastItem = context.fetchFirst(FeedItem.self, key: "remoteId", value: "4")
            do {
                context.delete(lastItem!)
            
                try context.save()
            } catch {
                print("XXX delete error \(error)")
            }
        }
        
        let feedItemsAfterDelete: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever();
        expect(feedItemsAfterDelete).to(beEmpty());
    }
            
    func testShouldGetOneMappableFeedItemRetrieverAndStartItWithNoInitialItemsAddOneThenUpdateIt() {
//            it("should get one mappable feed item retriever and start it with no initial items add one then update it") {
        let feedIds: [String] = ["0","1","2","3"];
        let feeds = loadFeedsJson();
        guard let context = self.context else { return }
        
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: feeds as! [[AnyHashable:Any]], eventId: 1, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
        let feedItemRetriever: FeedItemRetriever? = FeedItemRetriever.getMappableFeedRetriever(feedId: "1", eventId: 1);
        expect(feedItemRetriever).toNot(beNil());
        expect(feedItemRetriever?.feed.remoteId) == "1"
        
        let firstFeedItems: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever();
        expect(firstFeedItems).to(beEmpty());
        
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", itemId: "4", properties: ["primary": "Primary Value for item"])
        let addedFeedItems: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever();
        expect(addedFeedItems?.compactMap(\.remoteId)).to(contain("4"))
        
        context.performAndWait {
            let lastItem = context.fetchFirst(FeedItem.self, key: "remoteId", value: "4")
            do {
                lastItem!.geometry = nil
            
                try context.save()
            } catch {
                print("XXX delete error \(error)")
            }
        }
        let feedItemsAfterUpdate: [FeedItemAnnotation]? = feedItemRetriever?.startRetriever();
        expect(feedItemsAfterUpdate).to(beEmpty());
    }
}
*/
