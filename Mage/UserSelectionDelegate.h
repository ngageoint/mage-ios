//
//  ObservationSelectionDelegate.h
//  MAGE
//
//  Created by William Newman on 9/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User+helper.h"
#import <MapKit/MapKit.h>

@protocol UserSelectionDelegate <NSObject>

@required
    -(void) selectedUser:(User *) user;
    -(void) selectedUser:(User *) user region:(MKCoordinateRegion) region;
-(void) userDetailSelected: (User *) user;

@end
