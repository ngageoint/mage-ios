//
//  ObservationImportant+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationImportant+CoreDataProperties.h"

@implementation ObservationImportant (CoreDataProperties)

+ (NSFetchRequest<ObservationImportant *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ObservationImportant"];
}

@dynamic dirty;
@dynamic important;
@dynamic timestamp;
@dynamic userId;
@dynamic reason;
@dynamic observation;

@end
