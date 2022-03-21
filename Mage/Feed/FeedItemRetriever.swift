//
//  FeedItemFetchedResultsController.swift
//  MAGE
//
//  Created by Daniel Barela on 6/15/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

extension UIImage {
    
    func colorized(color : UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height);
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0);
        let context = UIGraphicsGetCurrentContext();
        context!.translateBy(x: 0, y: self.size.height);
        context!.scaleBy(x: 1.0, y: -1.0);
        context!.draw(self.cgImage!, in: rect);
        context!.clip(to: rect, mask: self.cgImage!);
        context?.setFillColor(color.cgColor);
        context?.fill(rect);
        let colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return colorizedImage!;
    }
}

@objc class FeedItemRetriever : NSObject {
    
    @objc public static func setAnnotationImage(feedItem: FeedItem, annotationView: MKAnnotationView) {
        if let url: URL = feedItem.iconURL {
            let size = 35;
            
            KingfisherManager.shared.retrieveImage(with: url, options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ]) { result in
                switch result {
                case .success(let value):
                    
                    let image = value.image.aspectResize(to: CGSize(width: size, height: size))
                    annotationView.image = image;
                    annotationView.centerOffset = CGPoint(x: 0, y: -((annotationView.image?.size.height ?? 0.0)/2.0))
                    
                case .failure(_):
                    annotationView.image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
                    annotationView.centerOffset = CGPoint(x: 0, y: -((annotationView.image?.size.height ?? 0.0)/2.0))
                }
            }
        } else {
            annotationView.image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: globalContainerScheme().colorScheme.primaryColor);
            annotationView.centerOffset = CGPoint(x: 0, y: -((annotationView.image?.size.height ?? 0.0)/2.0))
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
    
    @objc public static func getMappableFeedRetriever(feedTag: NSNumber, eventId: NSNumber, delegate: FeedItemDelegate) -> FeedItemRetriever? {
        if let feed: Feed = Feed.mr_findFirst(byAttribute: "tag", withValue: feedTag) {
            return getMappableFeedRetriever(feedId: feed.remoteId!, eventId: eventId, delegate: delegate);
        }
        return nil;
    }
    
    @objc public static func getMappableFeedRetriever(feedId: String, eventId: NSNumber, delegate: FeedItemDelegate) -> FeedItemRetriever? {
        if let feed: Feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", feedId, eventId)) {
            if (feed.itemsHaveSpatialDimension) {
                return FeedItemRetriever(feed: feed, delegate: delegate);
            }
        }
        return nil;
    }
    
    @objc public static func createMappableFeedItemRetrievers(delegate: FeedItemDelegate) -> [FeedItemRetriever] {
        var feedRetrievers: [FeedItemRetriever] = [];
        if let feeds: [Feed] = Feed.mr_findAll() as? [Feed] {
            
            for feed: Feed in feeds {
                if (feed.itemsHaveSpatialDimension) {
                    let retriever = FeedItemRetriever(feed: feed, delegate: delegate);
                    feedRetrievers.append(retriever);
                }
            }
        }
        return feedRetrievers;
    }

    @objc public let feed: Feed;
    let delegate: FeedItemDelegate;
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<FeedItem> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "feed = %@", self.feed);
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "remoteId", ascending: true)]
        
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
            delegate.add(anObject as? FeedItem);
        case .delete:
            delegate.remove(anObject as? FeedItem)
        case .update:
            delegate.remove(anObject as? FeedItem)
            delegate.add(anObject as? FeedItem);
        case .move:
            print("...")
        @unknown default:
            print("...")
        }
    }
}

