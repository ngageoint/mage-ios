//
//  ManagedObjectContextHolder.h
//  MAGE
//
//  Created by Dan Barela on 9/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ManagedObjectContextHolder : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
