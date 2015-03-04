//
//  EventChooserController.m
//  MAGE
//
//  Created by Dan Barela on 3/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventChooserController.h"
#import <Event+helper.h>
#import <Mage.h>

@implementation EventChooserController

- (void) viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
    [[Mage singleton] initiateDataPull];
}

- (void) eventsFetched: (NSNotification *) notification {
    NSLog(@"Events were fetched");
    [self.eventDataSource startFetchController];
}

@end
