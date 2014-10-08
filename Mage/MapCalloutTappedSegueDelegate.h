//
//  MapCalloutTappedDelegate_iPhone.h
//  MAGE
//
//  Created by William Newman on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapCalloutTapped.h"

@interface MapCalloutTappedSegueDelegate : NSObject<MapCalloutTapped>

@property(nonatomic, weak) IBOutlet UIViewController *viewController;
@property(nonatomic, weak) NSString *segueIdentifier;

@end
