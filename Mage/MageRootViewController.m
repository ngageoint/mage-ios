//
//  MageRootViewController.m
//  Mage
//
//

#import "MageRootViewController.h"
#import <Mage.h>
#import "MageOfflineObservationManager.h"
#import <Authentication.h>
#import "Theme+UIResponder.h"

@interface MageRootViewController()<OfflineObservationDelegate>
@property (weak, nonatomic) UITabBarItem *profileTabBarItem;
@property (weak, nonatomic) UITabBarItem *moreTabBarItem;
@property (strong, nonatomic) MageOfflineObservationManager *offlineObservationManager;
@end

@implementation MageRootViewController

- (void) viewDidLoad {
    [[Mage singleton] startServicesAsInitial:YES];
	
	[super viewDidLoad];
    
    [self registerForThemeChanges];
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.tabBarItem.tag == 3) {
            self.profileTabBarItem = viewController.tabBarItem;
        } else if (viewController.tabBarItem.tag == 4) {
            self.moreTabBarItem = viewController.tabBarItem;
        }
    }
}

- (void) themeDidChange:(MageTheme)theme {
    self.tabBar.barTintColor = [UIColor tabBarTint];
    self.tabBar.tintColor = [UIColor activeTabIcon];
    self.tabBar.unselectedItemTintColor = [UIColor inactiveTabIcon];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.offlineObservationManager = [[MageOfflineObservationManager alloc] initWithDelegate:self];
    [self.offlineObservationManager start];
    [self setServerConnectionStatus];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"loginType" options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    [self setServerConnectionStatus];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.offlineObservationManager stop];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"loginType" context:NULL];
}

- (void) offlineObservationsDidChangeCount:(NSInteger)count {
    if (count > 0) {
        self.profileTabBarItem.badgeValue = [NSString stringWithFormat:@"%@", count > 99 ? @"99+": @(count)];
    } else {
        self.profileTabBarItem.badgeValue = nil;
    }
}

- (void) setServerConnectionStatus {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
        self.moreTabBarItem.badgeValue = @"!";
        self.moreTabBarItem.badgeColor = [UIColor orangeColor];
    } else {
        self.moreTabBarItem.badgeValue = nil;
        self.moreTabBarItem.badgeColor = nil;
    }
}

@end
