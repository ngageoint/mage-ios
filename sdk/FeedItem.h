//
//  FeedItem+CoreDataClass.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "SFGeometry.h"
#import "Feed.h"

@class Feed, NSObject;

NS_ASSUME_NONNULL_BEGIN

@interface FeedItem : NSManagedObject <MKAnnotation>

@property (nullable, nonatomic, retain) SFGeometry *simpleFeature;
@property (nullable, readonly) NSString *primaryValue;
@property (nullable, readonly) NSString *secondaryValue;
@property (nullable, readonly) NSURL *iconURL;
@property (nullable, readonly) NSDate *timestamp;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy, nullable) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *subtitle;
@property (readonly) BOOL isMappable;

+ (NSArray<FeedItem*> *) getFeedItemsForFeed: (NSNumber *) feedId;
+ (NSString *) feedItemIdFromJson:(NSDictionary *) json;
- (id) populateObjectFromJson: (NSDictionary *) json withFeed: (Feed *) feed;
- (BOOL) hasContent;

@end

NS_ASSUME_NONNULL_END

#import "FeedItem+CoreDataProperties.h"
