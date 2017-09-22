//
//  SettingsViewController.m
//  Mage
//
//

#import "SettingsTableViewController.h"
#import "User.h"
#import "LocationService.h"
#import "MageServer.h"
#import "EventChooserController.h"
#import "Event.h"
#import "NSDate+display.h"
#import "AppDelegate.h"
#import "EventChooserCoordinator.h"

@interface SettingsTableViewController ()<UITableViewDelegate>

    @property (weak, nonatomic) IBOutlet UILabel *locationServicesStatus;
    @property (weak, nonatomic) IBOutlet UILabel *dataFetchStatus;
    @property (weak, nonatomic) IBOutlet UILabel *imageUploadSizeLabel;
    @property (weak, nonatomic) IBOutlet UILabel *user;
    @property (weak, nonatomic) IBOutlet UILabel *baseServerUrlLabel;
    @property (weak, nonatomic) IBOutlet UILabel *versionLabel;
    @property (strong, nonatomic) CLLocationManager *locationManager;
    @property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
    @property (nonatomic, assign) BOOL showDisclaimer;
    @property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;
    @property (assign, nonatomic) NSInteger versionCellSelectionCount;
    @property (weak, nonatomic) IBOutlet UITableViewCell *timeZoneSelectionCell;
    @property (weak, nonatomic) IBOutlet UITableViewCell *logoutCell;
    @property (weak, nonatomic) IBOutlet UITableViewCell *eventCell;

@end

@implementation SettingsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    } else {
        // Fallback on earlier versions
    }
    
    self.versionCellSelectionCount = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.showDisclaimer = [defaults objectForKey:@"showDisclaimer"] != nil && [[defaults objectForKey:@"showDisclaimer"] boolValue];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFromDetail:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    self.user.text = user.name;
    
    Event *e = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]];
    self.eventNameLabel.text = e.name;

    [self setPreferenceDisplayLabel:self.imageUploadSizeLabel forPreference:@"imageUploadSizes"];
    [self populateSettingsTable];
}

- (void) updateFromDetail: (NSNotification *) notification {
    [self populateSettingsTable];
}

- (void) populateSettingsTable {
    [self setLocationServicesLabel];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.baseServerUrlLabel.text = [[MageServer baseURL] absoluteString];
    
    if ([[defaults objectForKey:@"dataFetchEnabled"] boolValue]) {
        [self.dataFetchStatus setText:@"On"];
    } else {
        [self.dataFetchStatus setText:@"Off"];
    }
    
    if (![NSDate isDisplayGMT]) {
        self.timeZoneSelectionCell.textLabel.text = @"Local Time";
        self.timeZoneSelectionCell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSTimeZone systemTimeZone] name]];
    } else {
        self.timeZoneSelectionCell.textLabel.text = @"GMT Time";
        self.timeZoneSelectionCell.detailTextLabel.text = @"";
    }
}

- (void) setLocationServicesLabel {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    CLAuthorizationStatus authorizationStatus =[CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if ([defaults boolForKey:kReportLocationKey]) {
            [self.locationServicesStatus setText:@"On"];
        } else {
            [self.locationServicesStatus setText:@"Off"];
        }
    } else {
        [self.locationServicesStatus setText:@"Disabled"];
    }
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    NSDictionary *frequencyDictionary = [defaults dictionaryForKey:prefValuesKey];
    NSArray *labels = [frequencyDictionary valueForKey:@"labels"];
    NSArray *values = [frequencyDictionary valueForKey:@"values"];
    
    NSNumber *frequency = [defaults valueForKey:[frequencyDictionary valueForKey:@"preferenceKey"]];
    
    for (int i = 0; i < values.count; i++) {
        if ([frequency integerValue] == [[values objectAtIndex:i] integerValue]) {
            [label setText:[labels objectAtIndex:i]];
            break;
        }
    }
    
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setLocationServicesLabel];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.logoutCell) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate logout];
    } else if (cell == self.versionCell) {
        self.versionCellSelectionCount++;
        
        if (self.versionCellSelectionCount == 5) {
            [tableView reloadData];
        }
    } else if (cell == self.eventCell) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate chooseEvent];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 3 && [indexPath row] == 0) {
        cell.hidden = !self.showDisclaimer;
    } else if (cell == self.versionCell) {
        NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *buildString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        if (self.versionCellSelectionCount == 5) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", versionString, buildString];
        } else {
            cell.detailTextLabel.text = versionString;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 3 && [indexPath row] == 0 && !self.showDisclaimer) {
        return 0;
    }
                                     
    return UITableViewAutomaticDimension;
}

@end
