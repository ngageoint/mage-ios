//
//  StaticLayer.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/22/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Layer.h"


@interface StaticLayer : Layer

@property (nonatomic, retain) id data;

@end
