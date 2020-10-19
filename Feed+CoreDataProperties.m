//
//  Feed+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "Feed+CoreDataProperties.h"

@implementation Feed (CoreDataProperties)

+ (NSFetchRequest<Feed *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Feed"];
}

@dynamic remoteId;
@dynamic title;
@dynamic tag;
@dynamic summary;
@dynamic itemsHaveIdentity;
@dynamic itemPrimaryProperty;
@dynamic itemSecondaryProperty;
@dynamic constantParams;
@dynamic variableParams;
@dynamic mapStyle;
@dynamic updateFrequency;
@dynamic pullFrequency;
@dynamic items;
@dynamic eventId;

@end
