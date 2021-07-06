//
//  Canary+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 8/2/18.
//  Copyright © 2018 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Canary+CoreDataProperties.h"

@implementation Canary (CoreDataProperties)

+ (NSFetchRequest<Canary *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"Canary"];
}

@dynamic launchDate;

@end
