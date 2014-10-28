//
//  ManagedObjectContextHolder.m
//  MAGE
//
//  Created by Dan Barela on 9/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ManagedObjectContextHolder.h"
#import "AppDelegate.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation ManagedObjectContextHolder

- (NSManagedObjectContext *) managedObjectContext {
    return [NSManagedObjectContext defaultManagedObjectContext];
}

@end
