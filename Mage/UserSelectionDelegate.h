//
//  ObservationSelectionDelegate.h
//  MAGE
//
//  Created by William Newman on 9/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User+helper.h"

@protocol UserSelectionDelegate <NSObject>

@required
    -(void) selectedUser:(User *) user;

@end
