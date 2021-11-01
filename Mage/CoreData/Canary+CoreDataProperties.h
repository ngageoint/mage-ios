//
//  Canary+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 8/2/18.
//  Copyright © 2018 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Canary.h"

NS_ASSUME_NONNULL_BEGIN

@interface Canary (CoreDataProperties)

+ (NSFetchRequest<Canary *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *launchDate;

@end

NS_ASSUME_NONNULL_END
