//
//  PersonIcon.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PersonImage : NSObject

+ (NSString *) imageNameForTimestamp:(NSDate *) timestamp;
+ (UIImage *) imageForTimestamp:(NSDate *) timestamp;

@end
