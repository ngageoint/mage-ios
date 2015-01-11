//
//  MKAnnotationView+PersonIcon.h
//  MAGE
//
//  Created by William Newman on 1/10/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "User.h"

@interface MKAnnotationView (PersonIcon)

- (void) setImageForUser:(User *) user;
@end
