//
//  ObservationImportantDelegate.h
//  MAGE
//
//  Created by William Newman on 10/27/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ObservationImportantDelegate <NSObject>

@required
- (void) flagObservationImportant;
- (void) removeObservationImportant;


@end
