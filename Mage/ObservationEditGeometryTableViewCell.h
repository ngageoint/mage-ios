//
//  ObservationEditGeometryTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import <GeoPoint.h>

@interface ObservationEditGeometryTableViewCell : ObservationEditTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (strong, nonatomic) GeoPoint *geoPoint;

@end
