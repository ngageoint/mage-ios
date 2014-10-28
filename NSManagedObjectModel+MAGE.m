//
//  NSManagedObjectModel+MAGE.m
//  mage-ios-sdk
//
//  Created by William Newman on 10/25/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "NSManagedObjectModel+MAGE.h"

NSManagedObjectModel *defaultManagedObjectModel = nil;

@implementation NSManagedObjectModel (MAGE)

+ (void) setDefaultManagedObjectModel:(NSManagedObjectModel *) mangedMobjectModel {
    defaultManagedObjectModel = mangedMobjectModel;
}

+ (NSManagedObjectModel *) defaultManagedObjectModel {
    if (defaultManagedObjectModel == nil) {
        defaultManagedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return defaultManagedObjectModel;
}

@end
