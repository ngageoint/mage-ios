//
//  MapCalloutTappedDelegate_iPhone.h
//  MAGE
//
//  Created by William Newman on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapCalloutTappedSegueDelegate.h"

@interface MapCalloutTappedDelegate_iPhone : NSObject<MapCalloutTapped>

@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *userMapCalloutTappedDelegate;
@property(nonatomic, weak) IBOutlet MapCalloutTappedSegueDelegate *observationMapCalloutTappedDelegate;

@end
