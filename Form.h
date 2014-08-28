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

+ (NSOperation *) operationToPullFormWithManagedObjectContext: (NSManagedObjectContext *) context complete:(void (^) (BOOL success)) complete;

@end
