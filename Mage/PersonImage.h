//
//  PersonIcon.h
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Location+helper.h"

@interface PersonImage : NSObject

+ (UIImage *) imageForLocation:(Location *) location;

@end
