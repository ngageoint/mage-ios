//
//  ObservationImportant+CoreDataClass.h
//  mage-ios-sdk
//
//  Created by William Newman on 9/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObservationImportant : NSManagedObject

+ (ObservationImportant *) importantForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;
- (void) updateImportantForJson: (NSDictionary *) json;

@end

NS_ASSUME_NONNULL_END

#import "ObservationImportant+CoreDataProperties.h"
