//
//  MapCalloutTappedDelegate.h
//  MAGE
//
//  Created by William Newman on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MapCalloutTapped <NSObject>

@required
-(void) calloutTapped:(id) calloutItem;

@end
