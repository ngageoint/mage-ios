//
//  ObservationViewerViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RESideMenu.h"
#import <MapKit/MapKit.h>

@interface ObservationViewerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet MKMapView *map;

@end
