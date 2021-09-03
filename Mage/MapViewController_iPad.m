//
//  MapViewController_iPad.m
//  MAGE
//
//

#import "MapViewController_iPad.h"
#import "SettingsViewController.h"
#import "MageOfflineObservationManager.h"
#import "AppDelegate.h"
#import "MapSettingsCoordinator.h"
#import <PureLayout.h>
#import "MAGE-Swift.h"

@interface MapViewController_iPad ()<OfflineObservationDelegate, MapSettingsCoordinatorDelegate>
@property (strong, nonatomic) UIButton *profileButton;
@property (strong, nonatomic) UILabel *badge;
@property (strong, nonatomic) MageOfflineObservationManager *offlineObservationManager;
@end

@implementation MapViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];
    self.badge = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.badge.translatesAutoresizingMaskIntoConstraints = false;
    self.badge.layer.cornerRadius = self.badge.bounds.size.height / 2;
    [self.badge setTextAlignment:NSTextAlignmentCenter];
    self.badge.layer.masksToBounds = true;
    self.badge.textColor = [UIColor whiteColor];
    [self.badge setFont:[UIFont boldSystemFontOfSize:14]];
    [self.badge setBackgroundColor:[UIColor redColor]];
}

- (void) setupNavigationBar {
    self.profileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.profileButton setTitle:@"Profile" forState:UIControlStateNormal];
    [self.profileButton addTarget:self action:@selector(profileButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *profileButton2 = [[UIBarButtonItem alloc] initWithCustomView:self.profileButton];
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter"  style:UIBarButtonItemStylePlain target:self action:@selector(filterTapped:)];
    UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(moreTapped:)];
    
    [self.navigationItem setRightBarButtonItems: [NSArray arrayWithObjects: moreButton, [self createSeparator], profileButton2, [self createSeparator], filterButton, nil]];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController.navigationBar setTranslucent:NO];

    self.offlineObservationManager = [[MageOfflineObservationManager alloc] initWithDelegate:self];
    [self.offlineObservationManager start];
    [self.createFab setHidden:true];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.offlineObservationManager stop];
}

- (UIBarButtonItem *) createSeparator {
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(self.navigationController.navigationBar.frame.size.height * 0.166, 0, 1, self.navigationController.navigationBar.frame.size.height * 0.66 )];
    separator.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.13];
    UIBarButtonItem *separatorItem = [[UIBarButtonItem alloc] initWithCustomView:separator];
    return separatorItem;
}

- (IBAction)profileButtonTapped:(id)sender {
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    UserViewController *uc = [[UserViewController alloc] initWithUser:user scheme:self.scheme];
    [self.navigationController pushViewController:uc animated:YES];
}

- (IBAction) mapSettingsTapped:(id)sender {
    MapSettingsCoordinator *settingsCoordinator = [[MapSettingsCoordinator alloc] initWithRootViewController:self.navigationController andSourceView:sender scheme:self.scheme];
    settingsCoordinator.delegate = self;
    [self.childCoordinators addObject:settingsCoordinator];
    [settingsCoordinator start];
}

- (IBAction)moreTapped:(id)sender {
    __weak typeof(self) weakSelf = self;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithScheme:self.scheme] ;
        settingsViewController.dismissable = YES;
        [weakSelf presentViewController:settingsViewController animated:YES completion:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Log out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate logout];
    }]];

    alert.popoverPresentationController.barButtonItem = sender;

    [self presentViewController:alert animated:YES completion:nil];
}

-(void) offlineObservationsDidChangeCount:(NSInteger) count {
    [self.badge setText:[NSString stringWithFormat:@"%@", count > 99 ? @"99+": @(count)]];
    
    [self.profileButton addSubview:self.badge];
    [self.badge autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.profileButton withOffset:-4];
    if (count <= 0) {
        [self.badge autoSetDimensionsToSize:CGSizeMake(0, 0)];
    } else if (count < 10) {
        [self.badge autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.profileButton withOffset:14];
        [self.badge autoSetDimensionsToSize:CGSizeMake(20, 20)];
    } else if (count < 100) {
        [self.badge autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.profileButton withOffset:24];
        [self.badge autoSetDimensionsToSize:CGSizeMake(30, 20)];
    } else {
        [self.badge autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.profileButton withOffset:34];
        [self.badge autoSetDimensionsToSize:CGSizeMake(40, 20)];
    }
}

#pragma mark - Map Settings Coordinator Delegate

- (void) mapSettingsComplete:(NSObject *) coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void)observationDetailSelected:(Observation *)observation {
    ObservationViewCardCollectionViewController *ovc = [[ObservationViewCardCollectionViewController alloc] initWithObservation:observation scheme:self.scheme];
    [self.navigationController pushViewController:ovc animated:YES];
}

- (void)selectedObservation:(Observation *)observation {
    
}

- (void)selectedObservation:(Observation *)observation region:(MKCoordinateRegion)region {
    
}

- (void)selectedUser:(User *)user {
    
}

- (void)selectedUser:(User *)user region:(MKCoordinateRegion)region {
    
}

- (void)userDetailSelected:(User *)user {
    UserViewController *uc = [[UserViewController alloc] initWithUser:user scheme:self.scheme];
    [self.navigationController pushViewController:uc animated:YES];
}

- (void)calloutTapped:(id)calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self userDetailSelected:(User *) calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self observationDetailSelected:(Observation *) calloutItem];
    } else if ([calloutItem isKindOfClass:[FeedItem class]]) {
        [self feedItemSelected:(FeedItem *) calloutItem];
    }
}

- (void)feedItemSelected:(nonnull FeedItem *)feedItem {
    FeedItemViewController *fivc = [[FeedItemViewController alloc] initWithFeedItem:feedItem scheme:self.scheme];
    [self.navigationController pushViewController:fivc animated:YES];
}

@end
