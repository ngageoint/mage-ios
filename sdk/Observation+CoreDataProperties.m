//
//  Observation+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/15/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation+CoreDataProperties.h"

@implementation Observation (CoreDataProperties)

+ (NSFetchRequest<Observation *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Observation"];
}

@dynamic deviceId;
@dynamic dirty;
@dynamic eventId;
@dynamic error;
@dynamic geometryData;
@dynamic lastModified;
@dynamic properties;
@dynamic remoteId;
@dynamic state;
@dynamic timestamp;
@dynamic url;
@dynamic userId;
@dynamic syncing;
@dynamic attachments;
@dynamic favorites;
@dynamic observationImportant;
@dynamic user;

@end
