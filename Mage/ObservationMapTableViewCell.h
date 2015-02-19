//
//  ObservationMapTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"
#import <MapKit/MapKit.h>

@interface ObservationMapTableViewCell : ObservationHeaderTableViewCell

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
