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
    var feedTimers: [String:Timer?] = [:];
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
        feedFetchedResultsController = nil;
    }
    
    public func isStopped() -> Bool {
        return feedTimers.allSatisfy { (key: String, value: Timer?) in
            return value == nil;
        }
    }
    
    @objc public func start() {
        guard let currentEventId = Server.currentEventId() else {
            return;
        }
        let fetchRequest: NSFetchRequest<Feed> = Feed.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "eventId = %@", currentEventId);
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "remoteId", ascending: true)]
        feedFetchedResultsController = NSFetchedResultsController<Feed>(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        feedFetchedResultsController?.delegate = self
        do {
            try feedFetchedResultsController?.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        print("starting feed service with objects \(feedFetchedResultsController!.fetchedObjects!)")
        for feed: Feed in feedFetchedResultsController!.fetchedObjects! {
            print("Pulling feed items for feed \(feed.remoteId ?? "nil") in event \(feed.eventId ?? -1)");
            if let remoteId = feed.remoteId, let eventId = feed.eventId {
                Feed.pullFeedItems(feedId: remoteId, eventId: eventId, success: {_,_ in
                    self.scheduleTimerToPullFeedItems(feedId: remoteId, eventId: eventId, pullFrequency: feed.pullFrequency ?? self.defaultPullFrequency);
                    
                }) { (task, error) in
                    self.scheduleTimerToPullFeedItems(feedId: remoteId, eventId: eventId, pullFrequency: feed.pullFrequency ?? self.defaultPullFrequency);
                    
                }
            }
        }
    }
    
    func scheduleTimerToPullFeedItems(feedId: String, eventId: NSNumber, pullFrequency: NSNumber) {
        // cancel any previously scheduled pull
        stopPullingFeedItems(feedId: feedId)
        let context = ["feedId": feedId, "eventId": eventId, "pullFrequency": pullFrequency] as [String : Any];
        let timer = Timer.scheduledTimer(timeInterval: TimeInterval(exactly: pullFrequency)!, target: self, selector: #selector(fireTimer(timer: )), userInfo: context, repeats: false)
        feedTimers[feedId] = timer;
    }
    
    func stopPullingFeedItems(feedId: String) {
        let timer: Timer? = (feedTimers[feedId] ?? nil) as Timer?;
        feedTimers[feedId] = nil;
        timer?.invalidate();
    }
    
    @objc func fireTimer(timer: Timer) {
        guard let context = timer.userInfo as? [String: Any] else { return }
        if let feedId: String = context["feedId"] as? String {
            if (feedTimers[feedId] == nil) { return }
            if let eventId: NSNumber = context["eventId"] as? NSNumber {
                print("Pulling feed items for feed", feedId);
                Feed.pullFeedItems(feedId: feedId, eventId: eventId, success: {_,_ in
                    self.scheduleTimerToPullFeedItems(feedId: feedId, eventId: eventId, pullFrequency: context["pullFrequency"] as? NSNumber ?? self.defaultPullFrequency);
                }) { (task, error) in
                    self.scheduleTimerToPullFeedItems(feedId: feedId, eventId: eventId, pullFrequency: context["pullFrequency"] as? NSNumber ?? self.defaultPullFrequency);
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
                scheduleTimerToPullFeedItems(feedId: feed.remoteId!, eventId: feed.eventId!, pullFrequency: feed.pullFrequency ?? defaultPullFrequency);
            case .delete:
                stopPullingFeedItems(feedId: feed.remoteId!);
            case .update:
                scheduleTimerToPullFeedItems(feedId: feed.remoteId!, eventId: feed.eventId!, pullFrequency: feed.pullFrequency ?? defaultPullFrequency);
            case .move:
                print("...")
            @unknown default:
                print("...")
            }
        }
    }
}
