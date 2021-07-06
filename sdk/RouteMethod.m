//
//  RouteMethod.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "RouteMethod.h"

@implementation RouteMethod

- (NSURL *) routeURL {
    return [NSURL URLWithString:self.route];
}

@end
