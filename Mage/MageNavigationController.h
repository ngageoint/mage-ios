//
//  MageNavigationController.h
//  Mage
//
//  Created by Billy Newman on 7/11/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MageNavigationController : UINavigationController

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
