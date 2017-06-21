//
//  MapViewController_iPad.m
//  MAGE
//
//

#import "MapViewController_iPad.h"
#import "ObservationEditViewController.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import <Location.h>
#import <Event.h>
#import "TimeFilter.h"
#import "SettingsViewController.h"
#import "WKBPoint.h"
#import "MeViewController.h"
#import "MageOfflineObservationManager.h"

@interface MapViewController_iPad ()<OfflineObservationDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *profileButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBadge;
@property (strong, nonatomic) IBOutlet UILabel *badgeCount;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBadgeTrailingSpacer;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBadgeLeadingSpacer;
@property (strong, nonatomic) MageOfflineObservationManager *offlineObservationManager;
@end

@implementation MapViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];

    self.profileBadgeLeadingSpacer.width = -8;
    self.profileBadgeTrailingSpacer.width = -2;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController.navigationBar setTranslucent:NO];

//    UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
//    lblTitle.backgroundColor = [UIColor clearColor];
//    lblTitle.textColor = [UIColor whiteColor];
//    lblTitle.font = [UIFont boldSystemFontOfSize:18];
//    lblTitle.textAlignment = NSTextAlignmentLeft;
//    lblTitle.text = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name;
//    [lblTitle sizeToFit];
//
//    [self.eventNameItem setCustomView:lblTitle];

    self.offlineObservationManager = [[MageOfflineObservationManager alloc] initWithDelegate:self];
    [self.offlineObservationManager start];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.offlineObservationManager stop];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO];
}

- (void) setNavBarTitle: (NSString *) title andSubtitle: (NSString *) subtitle {

    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.text = title;
    [titleLabel sizeToFit];
    
    if ([subtitle length] == 0) {
        [self.eventNameItem setCustomView:titleLabel];
        return;
    }
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 0, 0)];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.textColor = [UIColor whiteColor];
    subtitleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    subtitleLabel.text = subtitle;
    [subtitleLabel sizeToFit];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(titleLabel.frame.size.width, subtitleLabel.frame.size.width), 30)];
    [titleView addSubview:titleLabel];
    [titleView addSubview:subtitleLabel];
    
    // Center title or subtitle on screen (depending on which is larger)
    if (titleLabel.frame.size.width >= subtitleLabel.frame.size.width) {
        CGRect adjustment = subtitleLabel.frame;
        adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.size.width/2) - (subtitleLabel.frame.size.width/2);
        subtitleLabel.frame = adjustment;
    } else {
        CGRect adjustment = titleLabel.frame;
        adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.size.width/2) - (titleLabel.frame.size.width/2);
        titleLabel.frame = adjustment;
    }
    
    [self.eventNameItem setCustomView:titleView];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;

        CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.mapView centerCoordinate].latitude longitude:[self.mapView centerCoordinate].longitude];
        WKBPoint *point = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];

        [editViewController setLocation:point];
    } else if ([[segue identifier] isEqualToString:@"SettingsSegue"]) {
        SettingsViewController *settingsViewController = segue.destinationViewController;
        settingsViewController.dismissable = YES;
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self selectedUser:(User *) calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self observationDetailSelected:(Observation *) calloutItem];
    }
}


- (void)selectedObservation:(Observation *) observation {
    [self.mapDelegate selectedObservation:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    [self.mapDelegate selectedObservation:observation region:region];
}

- (void)observationDetailSelected:(Observation *)observation {
    [self.mapDelegate observationDetailSelected:observation];
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void) selectedUser:(User *) user {
    [self.mapDelegate selectedUser:user];
}

- (void) selectedUser:(User *)user region:(MKCoordinateRegion)region {
    [self.mapDelegate selectedUser:user region:region];
}

- (void) userDetailSelected:(User *) user {
    [self.mapDelegate selectedUser:user];
    [self performSegueWithIdentifier:@"DisplayPersonSegue" sender:user];
}

- (IBAction)moreTapped:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Log out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"unwindToInitial" sender:self];
    }]];

    alert.popoverPresentationController.barButtonItem = self.moreButton;

    [self presentViewController:alert animated:YES completion:nil];
}

-(void) offlineObservationsDidChangeCount:(NSInteger) count {
    if (count > 0) {
        [self updateProfileBadgeWithCount:count];
    } else {
        [self removeProfileBadge];
    }
}

- (void) updateProfileBadgeWithCount:(NSInteger) count {
    NSMutableArray *items = [[self.toolbar items] mutableCopy];
    if (![items containsObject:self.profileBadge]) {
        [items insertObject:self.profileBadgeLeadingSpacer atIndex:9];
        [items insertObject:self.profileBadge atIndex:10];
        [items insertObject:self.profileBadgeTrailingSpacer atIndex:11];
        self.toolbar.items = items;
    }

    if (count != [self.badgeCount.text integerValue]) {
        self.badgeCount.text = [NSString stringWithFormat:@"%@", count > 99 ? @"99+": @(count)];

        CGSize textSize = [self.badgeCount.text sizeWithAttributes:@{NSFontAttributeName:[self.badgeCount font]}];
        UIView *view = [self.profileBadge customView];
        CGRect frame = view.frame;
        frame.size = CGSizeMake(textSize.width + 8, textSize.height + 10);
        view.frame = frame;

        self.badgeCount.center = view.center;
        self.badgeCount.layer.cornerRadius = textSize.height / 2;
    }

}

- (void) removeProfileBadge {
    NSMutableArray *items = [[self.toolbar items] mutableCopy];
    [items removeObject:self.profileBadge];
    [items removeObject:self.profileBadgeLeadingSpacer];
    [items removeObject:self.profileBadgeTrailingSpacer];

    self.toolbar.items = items;
}

@end
