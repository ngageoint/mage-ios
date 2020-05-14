//
//  ObservationLocationTableViewCell.h
//  MAGE
//
//  Created by William Newman on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObservationHeaderTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationLocationTableViewCell : ObservationHeaderTableViewCell

- (NSString *) getLocationText:(Observation *) observation;

@end

NS_ASSUME_NONNULL_END
