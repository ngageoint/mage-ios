//
//  LocationFetchService.h
//  mage-ios-sdk
//
//  Created by William Newman on 8/14/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationFetchService : NSObject
- (id) initWithManagedObjcetContext:(NSManagedObjectContext *) managedObjectContext;

- (void) start;
- (void) stop;

@end
