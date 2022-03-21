//
//  FeedItem+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc public class FeedItem: NSManagedObject, MKAnnotation, Navigable {
    
    var view: MKAnnotationView?
    
    static func fetchedResultsController(_ feedItem: FeedItem, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<FeedItem>? {
        guard let remoteId = feedItem.remoteId else {
            return nil
        }
        let fetchRequest = FeedItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteId = %@", remoteId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "temporalSortValue", ascending: true)]
        let feedItemFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        feedItemFetchedResultsController.delegate = delegate
        do {
            try feedItemFetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        return feedItemFetchedResultsController
    }
    
    @objc public var simpleFeature: SFGeometry? {
        get {
            if let geometry = self.geometry {
                return SFGeometryUtils.decodeGeometry(geometry);
            }
            return nil;
        }
        set {
            if let newValue = newValue {
                self.geometry = SFGeometryUtils.encode(newValue);
            }
        }
    }

    @objc public var primaryValue: String? {
        if let itemPrimaryProperty = self.feed?.itemPrimaryProperty {
            return self.valueForKey(key: itemPrimaryProperty);
        }
        return nil;
    }
    
    @objc public var secondaryValue: String? {
        if let itemSecondaryProperty = self.feed?.itemSecondaryProperty {
            return self.valueForKey(key: itemSecondaryProperty);
        }
        return nil;
    }
    
    @objc public var iconURL: URL? {
        return self.feed?.iconURL
    }
    
    @objc public var timestamp: Date? {
        if let epochTime = (self.properties as? [AnyHashable : Any])?[self.feed?.itemTemporalProperty] as? NSNumber {
            return Date(timeIntervalSince1970: epochTime.doubleValue / 1000.0)
        }
        
        return nil;
    }
    
    @objc public var isTemporal: Bool {
        return self.feed?.itemTemporalProperty != nil
    }
    
    @objc public var isMappable: Bool {
        return self.geometry != nil && CLLocationCoordinate2DIsValid(self.coordinate)
    }
    
    @objc public var title: String? {
        if let primaryValue = self.primaryValue {
            return primaryValue
        }
        return " ";
    }
    
    @objc public var subtitle: String? {
        return self.secondaryValue;
    }
    
    @objc public var coordinate: CLLocationCoordinate2D {
        if let centroid = self.simpleFeature?.centroid() {
            return CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue);
        }
        return kCLLocationCoordinate2DInvalid
    }

    @objc public static func getFeedItems(feedId: String, eventId: Int) -> [FeedItem]? {
        if let feed = Feed.mr_findFirst(with: NSPredicate(format: "(\(FeedKey.remoteId.key) == %@ AND \(FeedKey.eventId.key) == %d)", feedId, eventId)) {
            return FeedItem.mr_findAll(with: NSPredicate(format: "(feed == %@)", feed)) as? [FeedItem];
        }
        return [];
    }
    
    @objc public static func feedItemIdFromJson(json: [AnyHashable: Any]) -> String? {
        return json[FeedItemKey.id.key] as? String;
    }
    
    @objc public func populate(json: [AnyHashable : Any], feed: Feed) {
        self.remoteId = json[FeedItemKey.id.key] as? String
        
        let geometry = GeometryDeserializer.parseGeometry(json: json[FeedItemKey.geometry.key] as? [AnyHashable : Any])
        self.simpleFeature = geometry;
        self.properties = json[FeedItemKey.properties.key] as? [AnyHashable : Any]
        if let temporalProperty = feed.itemTemporalProperty, let temporalValue = (self.properties as? [AnyHashable : Any])?[temporalProperty] as? NSNumber {
            self.temporalSortValue = temporalValue
        }
        self.feed = feed
    }
    
    @objc public func hasContent() -> Bool {
        return self.primaryValue != nil || self.secondaryValue != nil || (self.isTemporal && self.timestamp != nil);
    }
    
    @objc public func valueForKey(key: String) -> String? {
        guard let value: Any = ((self.properties as? [AnyHashable : Any])?[key]) else {
            return nil;
        }
        
        if let feed = self.feed, let itemPropertiesSchema = feed.itemPropertiesSchema, let properties = itemPropertiesSchema[FeedItemPropertiesSchemaKey.properties.key] as? [AnyHashable : Any], let keySchema = properties[key] as? [AnyHashable : Any], let type = keySchema[FeedItemPropertiesSchemaKey.type.key] as? String {
            if (type == FeedItemPropertiesSchemaKey.number.key) {
                if let numberValue = value as? NSNumber, let format = keySchema[FeedItemPropertiesSchemaKey.format.key] as? String, format == FeedItemPropertiesSchemaKey.date.key {
                    let dateDisplayFormatter = DateFormatter();
                    dateDisplayFormatter.dateFormat = "yyyy-MM-dd";
                    dateDisplayFormatter.timeZone = TimeZone(secondsFromGMT: 0);
                    return dateDisplayFormatter.string(from: Date(timeIntervalSince1970: numberValue.doubleValue / 1000.0))
                }
            }
        }
        return String(describing: value);
    }
}
