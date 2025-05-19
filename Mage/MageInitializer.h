//
//  MageInitializer.h
//  MAGE
//
//  Created by James McDougall on 3/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface MageInitializer : NSObject

+ (NSManagedObjectContext *)setupCoreData;
+ (NSManagedObjectContext *)clearAndSetupCoreData;
+ (NSDictionary *)clearServerSpecificData;

@end

NS_ASSUME_NONNULL_END 