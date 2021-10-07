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

@objc public class FeedItem: NSManagedObject, MKAnnotation {
    @objc public var simpleFeature: SFGeometry? {
        get {
            SFGeometryUtils.decodeGeometry(self.geometry);
        }
        set {
            self.geometry = SFGeometryUtils.encode(newValue);
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
        if let feed = Feed.mr_findFirst(with: NSPredicate(format: "(remoteId == %@ AND eventId == %@", feedId, eventId)) {
            return FeedItem.mr_findAll(with: NSPredicate(format: "(feed == %@)", feed)) as? [FeedItem];
        }
        return [];
    }
    
    @objc public static func feedItemIdFromJson(json: [AnyHashable: Any]) -> String? {
        return json["id"] as? String;
    }
    
    @objc public func populate(json: [AnyHashable : Any], feed: Feed) {
        self.remoteId = json["id"] as? String
        
        let geometry = GeometryDeserializer.parseGeometry(json["geometry"] as? [AnyHashable : Any])
        self.simpleFeature = geometry;
        self.properties = json["properties"] as? [AnyHashable : Any]
        self.feed = feed
    }
    
    @objc public func hasContent() -> Bool {
        return self.primaryValue != nil || self.secondaryValue != nil || (self.isTemporal && self.timestamp != nil);
    }
    
    @objc public func valueForKey(key: String) -> String? {
        guard let value: Any = ((self.properties as? [AnyHashable : Any])?[key]) else {
            return nil;
        }
        
        if let feed = self.feed, let itemPropertiesSchema = feed.itemPropertiesSchema as? [AnyHashable : Any], let properties = itemPropertiesSchema["properties"] as? [AnyHashable : Any], let keySchema = properties[key] as? [AnyHashable : Any], let type = keySchema["type"] as? String {
            if (type == "number") {
                if let numberValue = value as? NSNumber, let format = keySchema["format"] as? String, format == "date" {
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
