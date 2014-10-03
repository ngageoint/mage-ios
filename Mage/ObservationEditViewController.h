//
//  ObservationEditViewController.h
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "ObservationEditListener.h"

@interface ObservationEditViewController : UIViewController

@property (strong, nonatomic) Observation *observation;

@end
