//
//  EventTableViewCell.h
//  MAGE
//
//  Created by William Newman on 5/24/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface EventTableViewCell : UITableViewCell

- (void) populateCellWithEvent:(Event *) event offlineObservationCount:(NSUInteger) count;

@end
