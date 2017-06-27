//
//  ObservationEditViewController.h
//  MAGE
//
//  Created by William Newman on 6/26/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Observation.h"
#import "GeoPoint.h"

@interface ObservationEditViewController : UIViewController
@property (strong, nonatomic) Observation *observation;
@property (strong, nonatomic) GeoPoint *location;
@end
