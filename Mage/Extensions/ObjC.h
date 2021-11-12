//
//  ObjC.h
//  MAGE
//
//  Created by Daniel Barela on 11/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
