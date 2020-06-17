//
//  MageRootViewController.m
//  Mage
//

#import "MageRootViewController.h"
#import "Mage.h"
#import "MageOfflineObservationManager.h"
#import "Authentication.h"
#import "Theme+UIResponder.h"
#import "Feed.h"
#import "SettingsTableViewController.h"
#import "MAGE-Swift.h"

@interface MageRootViewController()<OfflineObservationDelegate, UITabBarControllerDelegate>
@property (weak, nonatomic) UITabBarItem *profileTabBarItem;
@property (weak, nonatomic) UITabBarItem *moreTabBarItem;
@property (strong, nonatomic) MageOfflineObservationManager *offlineObservationManager;
@end

@implementation MageRootViewController

- (void) viewDidLoad {
    [[Mage singleton] startServicesAsInitial:YES];
    self.delegate = self;
	[super viewDidLoad];
    
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.tabBarItem.tag == 3) {
            self.profileTabBarItem = viewController.tabBarItem;
        } else if (viewController.tabBarItem.tag == 4) {
            self.moreTabBarItem = viewController.tabBarItem;
        }
    }
    
    [self createSettingsTabItem];
    
    NSArray *feeds = [Feed MR_findAll];
    
    for (Feed *feed in feeds) {
        [self createFeedViewController:feed];
    }
    
    [self registerForThemeChanges];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSLog(@"selected the tab %@", item);
}

- (void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSLog(@"did select %@", viewController);

}

- (bool) tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSLog(@"should select %@", viewController);

//    if ([viewController isKindOfClass:[SettingsViewController class]]) {
//        return false;
//    }
    return true;
}

- (void) createSettingsTabItem {
    SettingsTableViewController *svc = [[SettingsTableViewController alloc] init];
    svc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"settings_tab"] tag:4];
    self.viewControllers = [self.viewControllers arrayByAddingObject:svc];
}

- (void) createFeedViewController: (Feed *) feed {
    FeedItemsViewController *view = [[FeedItemsViewController alloc] initWithFeed: feed];
//    UILabel *label = [[UILabel alloc] init];
//    label.text = feed.title;
//    view.view = label;
    view.tabBarItem = [[UITabBarItem alloc] initWithTitle:feed.title image:nil tag:5 + feed.id.intValue];
    self.viewControllers = [self.viewControllers arrayByAddingObject:view];
}

- (void) themeDidChange:(MageTheme)theme {
    self.tabBar.barTintColor = [UIColor tabBarTint];
    self.tabBar.tintColor = [UIColor activeTabIcon];
    self.tabBar.unselectedItemTintColor = [UIColor inactiveTabIcon];
    
    self.moreNavigationController.navigationBar.translucent = NO;
    self.moreNavigationController.navigationBar.barTintColor = [UIColor primary];
    self.moreNavigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    self.moreNavigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor navBarPrimaryText]};
    self.moreNavigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor navBarPrimaryText]};
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor navBarPrimaryText],
            NSBackgroundColorAttributeName: [UIColor primary]
        };
        appearance.largeTitleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor navBarPrimaryText],
            NSBackgroundColorAttributeName: [UIColor primary]
        };

        self.moreNavigationController.navigationBar.standardAppearance = appearance;
        self.moreNavigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.moreNavigationController.navigationBar.standardAppearance.backgroundColor = [UIColor primary];
        self.moreNavigationController.navigationBar.scrollEdgeAppearance.backgroundColor = [UIColor primary];
        [self.moreNavigationController.navigationBar setPrefersLargeTitles:YES];

        self.moreNavigationController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    } else {
        // Fallback on earlier versions
    }
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
