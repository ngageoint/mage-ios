//
//  MageRootViewController.m
//  Mage
//
//

#import "MageRootViewController.h"
#import <Mage.h>
#import "MageOfflineObservationManager.h"

@interface MageRootViewController()<OfflineObservationDelegate>
@property (weak, nonatomic) UITabBarItem *profileTabBarItem;
@property (strong, nonatomic) MageOfflineObservationManager *offlineObservationManager;
@end

@implementation MageRootViewController

- (void) viewDidLoad {
    [[Mage singleton] startServicesAsInitial:YES];
	
	[super viewDidLoad];
    
    self.profileTabBarItem = [[self.tabBar items] objectAtIndex:3];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.offlineObservationManager = [[MageOfflineObservationManager alloc] initWithDelegate:self];
    [self.offlineObservationManager start];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.offlineObservationManager stop];
}

- (void) offlineObservationsDidChangeCount:(NSInteger)count {
    if (count > 0) {
        self.profileTabBarItem.badgeValue = [NSString stringWithFormat:@"%@", count > 99 ? @"99+": @(count)];
    } else {
        self.profileTabBarItem.badgeValue = nil;
    }
}

@end
