//
//  MageInitialViewController.h
//  Mage
//
//  Created by Dan Barela on 7/15/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationFetchService.h"

@interface MageInitialViewController : UIViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) LocationFetchService *locationFetchService;

@end
