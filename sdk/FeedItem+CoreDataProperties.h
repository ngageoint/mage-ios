//
//  FeedItem+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "FeedItem.h"


NS_ASSUME_NONNULL_BEGIN

@interface FeedItem (CoreDataProperties)

+ (NSFetchRequest<FeedItem *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSString* remoteId;
@property (nullable, nonatomic, retain) NSData *geometry;
@property (nullable, nonatomic, retain) id properties;
@property (nullable, nonatomic, retain) Feed *feed;

@end

NS_ASSUME_NONNULL_END
