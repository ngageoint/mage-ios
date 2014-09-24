//
//  MapViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ManagedObjectContextHolder.h"

@interface MapViewController : UIViewController
@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
