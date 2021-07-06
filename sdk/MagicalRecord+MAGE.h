//
//  MagicalRecord+MAGE.h
//  mage-ios-sdk
//
//  Created by William Newman on 11/17/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <MagicalRecord/MagicalRecord.h>

@interface MagicalRecord (MAGE)

+(void) setupMageCoreDataStack;
+(void) deleteAndSetupMageCoreDataStack;

@end
