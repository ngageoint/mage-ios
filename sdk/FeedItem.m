//
//  FeedItem+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "FeedItem.h"
#import "SFGeometryUtils.h"
#import "GeometryDeserializer.h"

@implementation FeedItem

+ (NSArray<FeedItem*> *) getFeedItemsForFeed: (NSString *) feedId andEvent: (NSNumber *) eventId {
    Feed *feed = [Feed MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", feedId, eventId]];
    return [FeedItem MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(feed == %@)", feed]];
}

- (id) populateObjectFromJson: (NSDictionary *) json withFeed: (Feed *) feed {
    [self setRemoteId:[json objectForKey:@"id"]];
    @try {
        SFGeometry * geometry = [GeometryDeserializer parseGeometry:[json valueForKeyPath:@"geometry"]];
        [self setSimpleFeature:geometry];
    }
    @catch (NSException *e){
        NSLog(@"Problem parsing geometry %@", e);
    }
    [self setProperties:[json objectForKey: @"properties"]];
    [self setFeed:feed];
        
    return self;
}

+ (NSString *) feedItemIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

- (BOOL) hasContent {
    return self.primaryValue || self.secondaryValue || ([self isTemporal] && self.timestamp != nil);
}

- (SFGeometry *) simpleFeature {
    return [SFGeometryUtils decodeGeometry:self.geometry];
}

- (void) setSimpleFeature:(SFGeometry *)simpleFeature {
    self.geometry = [SFGeometryUtils encodeGeometry:simpleFeature];
}

- (nullable NSString *) valueForKey:(NSString *) key {
    id value = self.properties[key];
    if (value == nil) {
        return nil;
    }
    NSString *valueString = [value stringValue];
    if (self.feed != nil && self.feed.itemPropertiesSchema != nil && self.feed.itemPropertiesSchema[@"properties"] != nil && self.feed.itemPropertiesSchema[@"properties"][key] != nil) {
        NSDictionary *keySchema = self.feed.itemPropertiesSchema[@"properties"][key];
        if ([keySchema valueForKey:@"type"] != nil) {
            NSString *type = [keySchema valueForKey:@"type"];
            if ([type isEqualToString:@"number"]) {
                if ([keySchema valueForKey:@"format"] != nil) {
                    NSString *format = [keySchema valueForKey:@"format"];
                    if ([format isEqualToString:@"date"]) {
                        NSDateFormatter *dateDisplayFormatter = [[NSDateFormatter alloc] init];
                        dateDisplayFormatter.dateFormat = @"yyyy-MM-dd";
                        dateDisplayFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
                        valueString = [dateDisplayFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[value doubleValue]/1000.0]];
                    }
                }
            }
        }
    }
    return valueString;
}

- (nullable NSString *) primaryValue {
    if (self.feed.itemPrimaryProperty == nil) {
        return nil;
    }
    return [self valueForKey:self.feed.itemPrimaryProperty];
}

- (nullable NSString *) secondaryValue {
    if (self.feed.itemSecondaryProperty == nil) {
        return nil;
    }
    return [self valueForKey:self.feed.itemSecondaryProperty];
}

- (nullable NSURL *) iconURL {
    return self.feed.iconURL;
}

- (nullable NSDate *) timestamp {
    NSNumber *epochTime = [((NSDictionary *)self.properties) valueForKey:self.feed.itemTemporalProperty];
    if (epochTime == nil) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970: epochTime.doubleValue / 1000.0];
}

- (NSString *) title {
    if (self.primaryValue == nil) {
        return @" ";
    }
    return self.primaryValue;
}

- (nullable NSString *) subtitle {
    return self.secondaryValue;
}

- (CLLocationCoordinate2D) coordinate {
    SFPoint *centroid = [self.simpleFeature centroid];
    return CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]);
}

- (BOOL) isMappable {
    return self.geometry != nil;
}

- (BOOL) isTemporal {
    return self.feed.itemTemporalProperty != nil;
}

@end
