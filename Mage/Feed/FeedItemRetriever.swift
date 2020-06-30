//
//  FeedItemFetchedResultsController.swift
//  MAGE
//
//  Created by Daniel Barela on 6/15/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

@objc protocol FeedItemDelegate {

    @objc func addFeedItem(feedItem: FeedItem);
    @objc func removeFeedItem(feedItem: FeedItem);

}

@objc class FeedItemRetriever : NSObject {
    
    @objc public static func setAnnotationImage(feedItem: FeedItem, annotationView: MKAnnotationView) {
        if let url: URL = feedItem.iconURL {
            let size = 24;
            
            let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
            KingfisherManager.shared.retrieveImage(with: url, options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ]) { result in
                switch result {
                case .success(let value):
                    
                    let image: UIImage = value.image.resized(to: CGSize(width: size, height: size));
                    annotationView.image = image;
                case .failure(let error):
                    print(error);
                }
            }
        } else {
            annotationView.image = nil;
        }
    }
    
    @objc public static func createFeedItemRetrievers(delegate: FeedItemDelegate) -> [FeedItemRetriever] {
        var feedRetrievers: [FeedItemRetriever] = [];
        if let feeds: [Feed] = Feed.mr_findAll() as? [Feed] {
        
            for feed: Feed in feeds {
                let retriever = FeedItemRetriever(feed: feed, delegate: delegate);
                feedRetrievers.append(retriever);
            }
        }
        return feedRetrievers;
    }

    let feed: Feed;
    let delegate: FeedItemDelegate;
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<FeedItem> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "feed = %@", self.feed);
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    init(feed: Feed, delegate: FeedItemDelegate) {
        self.feed = feed;
        self.delegate = delegate;
    }
    
    @objc public func startRetriever() -> [FeedItem]? {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        return fetchedResultsController.fetchedObjects;
    }
    
}

extension FeedItemRetriever : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            delegate.addFeedItem(feedItem: anObject as! FeedItem);
        case .delete:
            delegate.removeFeedItem(feedItem: anObject as! FeedItem)
        case .update:
            delegate.removeFeedItem(feedItem: anObject as! FeedItem)
            delegate.addFeedItem(feedItem: anObject as! FeedItem);
        case .move:
            print("...")
        @unknown default:
            print("...")
        }
    }
}

