//
//  MageEnums.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/24/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "MageEnums.h"

@implementation NSString (MageEnums)

- (State)StateEnumFromString{
    
    NSDictionary *states = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInteger:Active], @"active",
                            [NSNumber numberWithInteger:Archive], @"archive",
                            nil
                            ];
    
    return (State)[[states objectForKey:self] intValue];
}

- (int)IntFromStateEnum {
    NSDictionary *states = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInteger:Active], @"active",
                            [NSNumber numberWithInteger:Archive], @"archive",
                            nil
                            ];
    return [[states objectForKey:self] intValue];
}


@end
