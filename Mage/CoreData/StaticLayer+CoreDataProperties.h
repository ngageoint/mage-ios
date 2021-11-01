//
//  StaticLayer+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StaticLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface StaticLayer (CoreDataProperties)

@property (nullable, nonatomic, retain) id data;

@end

NS_ASSUME_NONNULL_END
