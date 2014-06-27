//
//  LocationResource.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LocationResource : NSObject

+ (void) fetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context;

@end
