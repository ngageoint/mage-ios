//
//  RouteMethod.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RouteMethod : NSObject

@property (strong, nonatomic) NSString *route;
@property (strong, nonatomic) NSString *method;
@property (strong, nonatomic) NSDictionary *parameters;
@property (readonly) NSURL *routeURL;

@end

NS_ASSUME_NONNULL_END
