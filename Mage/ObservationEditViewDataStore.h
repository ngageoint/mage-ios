//
//  ObservationEditViewDataStore.h
//  MAGE
//
//  Created by Dan Barela on 10/1/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Observation.h>
#import "ObservationEditListener.h"

@interface ObservationEditViewDataStore : NSObject <UITableViewDelegate, UITableViewDataSource, ObservationEditListener>

@property (strong, nonatomic) Observation *observation;
@property (weak, nonatomic) IBOutlet UITableView *editTable;

- (void) discaredChanges;

@end
