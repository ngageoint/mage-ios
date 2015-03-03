//
//  MageRootViewController.m
//  Mage
//
//  Created by Dan Barela on 4/28/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MageRootViewController.h"
#import <Mage.h>

@implementation MageRootViewController

- (void) viewDidLoad {
    [[Mage singleton] startServices];
	
	[super viewDidLoad];
}

@end
