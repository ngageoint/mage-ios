//
//  ObservationPushService.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/31/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObservationPushService : NSObject

- (id) initWithManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;

- (void) start;
- (void) stop;

@end
