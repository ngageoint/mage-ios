//
//  ObservationActionsDelegate.h
//  MAGE
//
//  Created by William Newman on 11/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ObservationActionsDelegate <NSObject>

@required
- (void) observationFavoriteTapped:(id) sender;
- (void) observationShareTapped:(id) sender;

@end
