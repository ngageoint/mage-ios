//
//  MAGEMasterSelectionDelegate.h
//  MAGE
//
//  Created by Dan Barela on 2/10/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Observation.h>
#import <User.h>

@protocol MAGEMasterSelectionDelegate <NSObject>

@required

-(void) selectedObservation: (Observation *) observation;
-(void) selectedUser: (User *) user;

@end
