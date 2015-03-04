//
//  EventChooserController.h
//  MAGE
//
//  Created by Dan Barela on 3/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventTableDataSource.h"

@interface EventChooserController : UIViewController

@property (strong, nonatomic) IBOutlet EventTableDataSource *eventDataSource;

@end
