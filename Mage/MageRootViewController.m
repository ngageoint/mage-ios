//
//  MageRootViewController.m
//  Mage
//
//

#import "MageRootViewController.h"
#import <Mage.h>

@implementation MageRootViewController

- (void) viewDidLoad {
    [[Mage singleton] startServices];
	
	[super viewDidLoad];
}

@end
