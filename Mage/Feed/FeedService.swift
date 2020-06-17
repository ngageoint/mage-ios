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
    var feedTimers: [Feed:Timer] = [:];
    let interval: TimeInterval;
        
    private override init() {
        self.interval = TimeInterval(exactly: 300)!;
    }
    
    @objc public func restart() {
        stop();
        start();
    }
    
    @objc public func stop() {
        for (_, t) in feedTimers {
            t.invalidate();
        }
    }
    
    @objc public func start() {
        let fetchRequest: NSFetchRequest<Feed> = Feed.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "eventId = %@", Server.currentEventId());
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let feedFetchedResultsController = NSFetchedResultsController<Feed>(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        feedFetchedResultsController.delegate = self
        do {
            try feedFetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        for feed: Feed in feedFetchedResultsController.fetchedObjects! {
            scheduleTimerToPullFeedItems(feed: feed);
        }
    }
    
    func scheduleTimerToPullFeedItems(feed: Feed) {
        let context = ["feed": feed];
        let timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(fireTimer), userInfo: context, repeats: false)
        feedTimers[feed] = timer;
    }
    
    func stopPullingFeedItems(feed: Feed) {
        let timer = feedTimers[feed];
        timer?.invalidate();
    }
        
    @objc func fireTimer(timer: Timer) {
        guard let context = timer.userInfo as? [String: Feed] else { return }
        if let feed = context["feed"] {
            Feed.pullFeedItems(forFeed: feed.id!, inEvent: feed.eventId!, success: {
                self.scheduleTimerToPullFeedItems(feed: feed);
            }) { (Error) in
                self.scheduleTimerToPullFeedItems(feed: feed);
            }
        }
    }
}

extension FeedService: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let feed: Feed = anObject as? Feed {
            switch type {
            case .insert:
                scheduleTimerToPullFeedItems(feed: feed)
            case .delete:
                stopPullingFeedItems(feed: feed);
            case .update:
                stopPullingFeedItems(feed: feed);
                scheduleTimerToPullFeedItems(feed: feed)
            case .move:
                print("...")
            @unknown default:
                print("...")
            }
        }
    }
}
