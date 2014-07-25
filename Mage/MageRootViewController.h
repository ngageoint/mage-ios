//
//  MageRootViewController.h
//  Mage
//
//  Created by Dan Barela on 4/28/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "RESideMenu.h"

@interface MageRootViewController : RESideMenu <RESideMenuDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
