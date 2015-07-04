//
//  LocationContainerViewController.h
//  MAGE
//
//  Created by William Newman on 7/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserSelectionDelegate.h"

@interface PeopleContainerViewController : UIViewController

@property (strong, nonatomic) id<UserSelectionDelegate> delegate;

@end
