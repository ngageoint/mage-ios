//
//  MapDelegate.h
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapDelegate : NSObject <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet UIViewController *viewController;

@end
