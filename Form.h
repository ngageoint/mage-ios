//
//  Form.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectContext+Extra.h"

@interface Form : NSObject

//- (id) populateObjectFromJson: (NSDictionary *) json;
//
//+ (Form *) formForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;
//
//+ (void) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context;

+ (NSOperation *) fetchFormInUseOperation;

@end
