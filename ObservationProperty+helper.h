//
//  ObservationProperty+helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/9/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObservationProperty.h"

@interface ObservationProperty (ObservationProperty_helper)

- (id) populateObjectFromJson: (NSDictionary *) json;

+ (ObservationProperty*) initWithJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;

@end
