//
//  MageEnums.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/24/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum state {
    Archive = 0,
    Active = 1
} State;

@interface NSString (MageEnums)

- (State)StateEnumFromString;

@end
