//
//  LocationProperty+helper.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocationProperty.h"

@interface LocationProperty (helper)

- (id) populateFromJson: (NSDictionary *) json;

+ (id) initWithKey: (NSString*) key andValue: (NSString*) value inManagedObjectContext: (NSManagedObjectContext *) context;

@end
