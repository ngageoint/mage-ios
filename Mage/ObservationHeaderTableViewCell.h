//
//  ObservationHeaderTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Observation.h>

@interface ObservationHeaderTableViewCell : UITableViewCell

- (void) configureCellForObservation: (Observation *) observation;

@end
