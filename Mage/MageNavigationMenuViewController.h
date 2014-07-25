//
//  MageNavigationMenuViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RESideMenu.h"

@interface MageNavigationMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RESideMenuDelegate>

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
