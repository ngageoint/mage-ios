//
//  ObservationEditListener.h
//  Mage
//
//  Created by Dan Barela on 8/22/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ObservationEditListener <NSObject>

@required
- (void) observationField: (id) field valueChangedTo: (id) value;

@end
