//
//  FeedService.swift
//  MAGE
//
//  Created by Daniel Barela on 6/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public class FeedService : NSObject {
    
    @objc public static let shared = FeedService();
    var feedTimers: [NSNumber:Timer] = [:];
    let interval: TimeInterval;
    var feedFetchedResultsController: NSFetchedResultsController<Feed>?;
    let defaultPullFrequency: NSNumber = 600;
        
    private override init() {
        self.interval = TimeInterval(exactly: 300)!;
    }
    
    @objc public func restart() {
        stop();
        start();
    }
    
    @objc public func stop() {
        for (key, _) in feedTimers {
            stopPullingFeedItems(feedId: key);
        }
    }
    
    @objc public func start() {
        let fetchRequest: NSFetchRequest<Feed> = Feed.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "eventId = %@", Server.currentEventId());
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        feedFetchedResultsController = NSFetchedResultsController<Feed>(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        feedFetchedResultsController?.delegate = self
        do {
            try feedFetchedResultsController?.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        for feed: Feed in feedFetchedResultsController!.fetchedObjects! {
            scheduleTimerToPullFeedItems(feedId: feed.id!, eventId: feed.eventId!, pullFrequency: feed.pullFrequency ?? defaultPullFrequency);
        }
    }
    
    func scheduleTimerToPullFeedItems(feedId: NSNumber, eventId: NSNumber, pullFrequency: NSNumber) {
        print("Scheduling timer for feed", feedId);
        let context = ["feedId": feedId, "eventId": eventId];
        let timer = Timer.scheduledTimer(timeInterval: TimeInterval(exactly: pullFrequency)!, target: self, selector: #selector(fireTimer), userInfo: context, repeats: false)
        feedTimers[feedId] = timer;
    }
    
    func stopPullingFeedItems(feedId: NSNumber) {
        print("Stopping timer for feed", feedId);
        let timer = feedTimers[feedId];
        feedTimers[feedId] = nil;
        timer?.invalidate();
    }
    
    @objc func fireTimer(timer: Timer) {
        guard let context = timer.userInfo as? [String: NSNumber] else { return }
        if let feedId: NSNumber = context["feedId"] {
            if (feedTimers[feedId] == nil) { return }
            if let eventId: NSNumber = context["eventId"] {
                print("Pulling feed items for feed", feedId);
                Feed.pullFeedItems(forFeed: feedId, inEvent: eventId, success: {
                    self.scheduleTimerToPullFeedItems(feedId: feedId, eventId: eventId, pullFrequency: context["pullFrequency"] ?? self.defaultPullFrequency);
                }) { (Error) in
                    self.scheduleTimerToPullFeedItems(feedId: feedId, eventId: eventId, pullFrequency: context["pullFrequency"] ?? self.defaultPullFrequency);
                }
            }
        }
    }
}

extension FeedService: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("fetched results controller fired");
        if let feed: Feed = anObject as? Feed {
            switch type {
            case .insert:
                scheduleTimerToPullFeedItems(feedId: feed.id!, eventId: feed.eventId!, pullFrequency: feed.pullFrequency ?? defaultPullFrequency);
            case .delete:
                stopPullingFeedItems(feedId: feed.id!);
            case .update:
                stopPullingFeedItems(feedId: feed.id!);
                scheduleTimerToPullFeedItems(feedId: feed.id!, eventId: feed.eventId!, pullFrequency: feed.pullFrequency ?? defaultPullFrequency);
            case .move:
                print("...")
            @unknown default:
                print("...")
            }
        }
    }
}
