//
//  MapSettings.m
//  MAGE
//
//  Created by William Newman on 10/31/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapSettings.h"

@interface MapSettings ()
    @property (nonatomic) BOOL shouldHideNavBar;
    @property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;
@end

@implementation MapSettings

bool originalNavBarHidden;

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    originalNavBarHidden = [self.navigationController isNavigationBarHidden];
    [self.navigationController setNavigationBarHidden:self.shouldHideNavBar animated:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mapTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"mapType"];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:originalNavBarHidden animated:animated];
}

- (IBAction)onMapTypeChanged:(UISegmentedControl *) segmentedControl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:segmentedControl.selectedSegmentIndex forKey:@"mapType"];
    [defaults synchronize];
}

@end
