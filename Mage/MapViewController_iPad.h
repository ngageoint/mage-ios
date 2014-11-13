//
//  MapViewController_iPad.h
//  MAGE
//
//  Created by William Newman on 9/30/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapViewController.h"

@interface MapViewController_iPad : MapViewController <UISplitViewControllerDelegate>

@property(nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end
