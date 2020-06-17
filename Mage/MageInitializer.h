//
//  MageInitializer.h
//  MAGE
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MageInitializer : NSObject

+ (void) initializePreferences;
+ (void) setupCoreData;
+ (void) clearAndSetupCoreData;

@end

NS_ASSUME_NONNULL_END
