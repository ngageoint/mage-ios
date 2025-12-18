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
    
    @objc public static func setAnnotationImage(feedItem: FeedItemAnnotation, annotationView: MKAnnotationView) {
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
    
    public static func createFeedItemRetrievers() -> [FeedItemRetriever] {
        var feedRetrievers: [FeedItemRetriever] = [];
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return [] }
        
        return context.performAndWait {
            if let feeds: [Feed] = context.fetchAll(Feed.self) {
            
                for feed: Feed in feeds {
                    let retriever = FeedItemRetriever(feed: feed);
                    feedRetrievers.append(retriever);
                }
            }
            return feedRetrievers;
        }
    }
    
    public static func getMappableFeedRetriever(feedTag: NSNumber, eventId: NSNumber) -> FeedItemRetriever? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        return context.performAndWait {
            if let feed: Feed = context.fetchFirst(Feed.self, key: "tag", value: feedTag) {
                return getMappableFeedRetriever(feedId: feed.remoteId!, eventId: eventId);
            }
            return nil
        }
    }
    
    public static func getMappableFeedRetriever(feedId: String, eventId: NSNumber) -> FeedItemRetriever? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        return context.performAndWait {
            if let feed: Feed = try? context.fetchFirst(Feed.self, predicate: NSPredicate(format: "remoteId == %@ AND eventId == %@", feedId, eventId)) {
                if (feed.itemsHaveSpatialDimension) {
                    return FeedItemRetriever(feed: feed);
                }
            }
            return nil
        }
    }
    
    public static func createMappableFeedItemRetrievers() -> [FeedItemRetriever] {
        var feedRetrievers: [FeedItemRetriever] = [];
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return [] }
        
        return context.performAndWait {
            if let feeds: [Feed] = context.fetchAll(Feed.self) {
                
                for feed: Feed in feeds {
                    if (feed.itemsHaveSpatialDimension) {
                        let retriever = FeedItemRetriever(feed: feed);
                        feedRetrievers.append(retriever);
                    }
                }
            }
            return feedRetrievers
        }
    }

    @objc public let feed: Feed;
    
    var fetchedResultsController: NSFetchedResultsController<FeedItem>?
    
    func createFetchedResultsController() {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "feed = %@", self.feed);
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "remoteId", ascending: true)]
        
        // Create Fetched Results Controller
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return }
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    init(feed: Feed) {
        self.feed = feed;
    }
    
    @objc public func startRetriever() -> [FeedItemAnnotation]? {
        createFetchedResultsController()
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            let fetchError = error as NSError
            MageLogger.misc.error("Unable to Perform Fetch Request")
            MageLogger.misc.error("\(fetchError), \(fetchError.localizedDescription)")
        }
        return fetchedResultsController?.fetchedObjects?.compactMap({ feedItem in
            if feedItem.isMappable {
                return FeedItemAnnotation(feedItem: feedItem)
            }
            return nil
        });
    }
    
}
