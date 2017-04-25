//
//  Observation+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation+CoreDataProperties.h"

@implementation Observation (CoreDataProperties)

+ (NSFetchRequest<Observation *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Observation"];
}

@dynamic deviceId;
@dynamic dirty;
@dynamic eventId;
@dynamic geometryData;
@dynamic lastModified;
@dynamic properties;
@dynamic remoteId;
@dynamic state;
@dynamic timestamp;
@dynamic url;
@dynamic userId;
@dynamic attribute;
@dynamic attachments;
@dynamic observationImportant;
@dynamic user;
@dynamic favorites;

@end
