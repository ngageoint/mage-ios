//
//  SettingsDataSource.m
//  MAGE
//
//  Created by William Newman on 1/28/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SettingsDataSource.h"
#import "Authentication.h"
#import "AuthenticationCoordinator.h"
#import <CoreLocation/CoreLocation.h>
#import "LocationService.h"
#import "MageServer.h"
#import "ObservationTableHeaderView.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"
#import "UITableViewCell+Setting.h"

@interface SettingsDataSource ()

@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@property (strong, nonatomic) Event* event;
@property (strong, nonatomic) NSArray<Event *>* recentEvents;
@property (strong, nonatomic) NSMutableArray* sections;

@end

@implementation SettingsDataSource

static const NSInteger CONNECTION_SECTION = 0;
static const NSInteger SERVICES_SECTION = 1;
static const NSInteger CURRENT_EVENT_SECTION = 2;
static const NSInteger CHANGE_EVENT_SECTION = 3;
static const NSInteger DISPLAY_SECTION = 4;
static const NSInteger MEDIA_SECTION = 5;
static const NSInteger SETTINGS_SECTION = 6;
static const NSInteger ABOUT_SECTION = 7;
static const NSInteger LEGAL_SECTION = 8;

- (instancetype) init {
    self = [super init];
    
    if (self) {
        self.event = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]];
        
        User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        NSArray *recentEventIds = [user.recentEventIds filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", self.event.remoteId]];

        NSFetchRequest *recentRequest = [Event MR_requestAllInContext:[NSManagedObjectContext MR_defaultContext]];
        [recentRequest setPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", recentEventIds]];
        [recentRequest setIncludesSubentities:NO];
        NSSortDescriptor* sortBy = [NSSortDescriptor sortDescriptorWithKey:@"recentSortOrder" ascending:YES];
        [recentRequest setSortDescriptors:[NSArray arrayWithObject:sortBy]];
        
        NSError *error = nil;
        self.recentEvents = [[NSManagedObjectContext MR_defaultContext] executeFetchRequest:recentRequest error:&error];
        if (error != nil) {
            self.recentEvents = [[NSArray alloc] init];
        }
        
        [self initDatasource];
    }
    
    return self;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return self.sections.count;
}

- (NSInteger) tableView:(nonnull UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    return [[[self.sections objectAtIndex:section] valueForKeyPath:@"rows"] count];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    if (indexPath.section == ABOUT_SECTION && indexPath.row == 2) {
        self.versionCellSelectionCount++;

        if (self.versionCellSelectionCount == 5) {
            [self initDatasource];
            [tableView reloadData];
        }
        
        return;
     }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.type) {
        [self.delegate settingTapped:[cell.type integerValue] info:cell.info];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *details = [[[self.sections objectAtIndex:indexPath.section] objectForKey:@"rows"] objectAtIndex:indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:[[details objectForKey:@"style"] integerValue] reuseIdentifier:nil];
    cell.backgroundColor = [UIColor background];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.imageView.tintColor = [UIColor activeIcon];
    
    cell.type = [details objectForKey:@"type"];
    cell.info = [details objectForKey:@"info"];

    NSString *image = [details objectForKey:@"image"];
    if (image) {
        cell.imageView.image = [UIImage imageNamed:image];
    }
    
    NSString *textLabel = [details objectForKey:@"textLabel"];
    if (textLabel) {
        cell.textLabel.text = textLabel;
    }
    
    NSString *detailTextLabel = [details objectForKey:@"detailTextLabel"];
    if (detailTextLabel) {
        cell.detailTextLabel.text = detailTextLabel;
    }
    
    NSNumber *accessoryType = [details objectForKey:@"accessoryType"];
    if (accessoryType) {
        if ([accessoryType integerValue] == UITableViewCellAccessoryDisclosureIndicator && self.showDisclosureIndicator) {
            cell.accessoryType = [accessoryType integerValue];
        }
    }
    
    UIView *accessoryView = [details objectForKey:@"accessoryView"];
    if (accessoryView) {
        cell.accessoryView = accessoryView;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
    NSInteger rows = [[[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"rows"] count];
    return rows > 0 ? [[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"header"] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSInteger rows = [[[self.sections objectAtIndex:section] valueForKeyPath:@"rows"] count];
    id header = [[self.sections objectAtIndex:section] valueForKeyPath:@"header"];
    return rows > 0 && header != nil ? 45.0 : CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [UIColor brand];
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)sectionIndex {
    NSInteger rows = [[[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"rows"] count];
    return rows > 0 ? [[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"footer"] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSInteger rows = [[[self.sections objectAtIndex:section] valueForKeyPath:@"rows"] count];
    id footer = [[self.sections objectAtIndex:section] valueForKeyPath:@"footer"];
    return rows > 0 && footer != nil ? UITableViewAutomaticDimension : CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *) view;
        footer.textLabel.textColor = [UIColor brand];
    }
}

- (void) reloadData {
    [self initDatasource];
}

- (void) initDatasource {
    NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:self.sections.count];
    
    [sections setObject:[self offlineSection] atIndexedSubscript:CONNECTION_SECTION];
    [sections setObject:[self servicesSection] atIndexedSubscript:SERVICES_SECTION];
    [sections setObject:[self currentEventSection] atIndexedSubscript:CURRENT_EVENT_SECTION];
    [sections setObject:[self changeEventSection] atIndexedSubscript:CHANGE_EVENT_SECTION];
    [sections setObject:[self displaySection] atIndexedSubscript:DISPLAY_SECTION];
    [sections setObject:[self mediaSection] atIndexedSubscript:MEDIA_SECTION];
    [sections setObject:[self setttingsSection] atIndexedSubscript:SETTINGS_SECTION];
    [sections setObject:[self aboutSection] atIndexedSubscript:ABOUT_SECTION];
    [sections setObject:[self legalSection] atIndexedSubscript:LEGAL_SECTION];
    
    self.sections = sections;
}

- (NSDictionary *) offlineSection {
    UILabel *offlineLabel = [[UILabel alloc] init];
    offlineLabel.font = [UIFont systemFontOfSize:14];
    offlineLabel.textAlignment = NSTextAlignmentCenter;
    offlineLabel.textColor = [UIColor whiteColor];
    offlineLabel.backgroundColor = [UIColor orangeColor];
    offlineLabel.text = @"!";
    [offlineLabel sizeToFit];
    
    // Adjust frame to be square for single digits or elliptical for numbers > 9
    CGRect frame = offlineLabel.frame;
    frame.size.height += (int)(0.4*14);
    frame.size.width = frame.size.height;
    offlineLabel.frame = frame;
    
    // Set radius and clip to bounds
    offlineLabel.layer.cornerRadius = frame.size.height/2.0;
    offlineLabel.clipsToBounds = true;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isLocalLogin = [[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]];
    NSArray *connectionRows = isLocalLogin ? @[
                                               @{
                                                   @"type": [NSNumber numberWithInteger:kConnection],
                                                   @"style": [NSNumber numberWithInteger:UITableViewCellStyleDefault],
                                                   @"image": @"wifi_off",
                                                   @"textLabel": @"Work Online",
                                                   @"accessoryView": offlineLabel
                                                   }
                                               ] : @[];
    
    return [@{
             @"header": @"Connection Status",
             @"footer": @"You are currently logged in offline. You are not receiving updates from, nor pushing your location or observations to the server. When you regain network connectivity, please log in again to reconnect to the server and work online.",
             @"rows": connectionRows
             } mutableCopy];
}

- (NSDictionary *) servicesSection {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *locationServicesLabel = nil;
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        locationServicesLabel = [defaults boolForKey:kReportLocationKey] ? @"On" : @"Off";
    } else {
        locationServicesLabel =  @"Disabled";
    }

    return [@{
      @"header": @"Data Synchronization",
      @"rows": @[@{
                     @"type": [NSNumber numberWithInteger:kLocationServices],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
                     @"image": @"people",
                     @"textLabel": @"Locations",
                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator],
//                     @"detailTextLabel": locationServicesLabel
                     },
                 @{
                     @"type": [NSNumber numberWithInteger:kObservationServices],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
                     @"image": @"observations",
                     @"textLabel": @"Observations",
                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                     },
                 @{
                     @"type": [NSNumber numberWithInteger:kDataSynchronization],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
                     @"image": @"wifi",
                     @"textLabel": @"Network Sync Settings",
                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                     }
//                 ,
//                 @{
//                     @"type": [NSNumber numberWithInteger:kDataFetching],
//                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
//                     @"image": @"cached",
//                     @"textLabel": @"Data Fetching",
//                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator],
//                     @"detailTextLabel": [defaults boolForKey:@"dataFetchEnabled"] ? @"On" : @"Off"
//                     },
//                 @{
//                     @"type": [NSNumber numberWithInteger:kDataPushing],
//                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
//                     @"image": @"cached",
//                     @"textLabel": @"Data Pushing",
//                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator],
//                     @"detailTextLabel": [defaults boolForKey:@"dataPushEnabled"] ? @"On" : @"Off"
//                     }
      ]
      } mutableCopy];
}

- (NSDictionary *) currentEventSection {
    return [@{
      @"header": @"Event Information",
      @"rows": @[@{
                     @"type": [NSNumber numberWithInteger:kEventInfo],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
                     @"image": @"event_available",
                     @"textLabel": self.event.name,
                     @"info": self.event,
                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                     }]
      } mutableCopy];
}

- (NSDictionary *) changeEventSection {
    NSMutableArray *eventRows = [NSMutableArray array];
    for (Event *event in self.recentEvents) {
        [eventRows addObject:@{
                               @"type": [NSNumber numberWithInteger:kChangeEvent],
                               @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
                               @"image": @"history",
                               @"textLabel": event.name,
                               @"info": event,
                               @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                               }];
    }
    [eventRows addObject:@{
                           @"type": [NSNumber numberWithInteger:kMoreEvents],
                           @"style": [NSNumber numberWithInteger:UITableViewCellStyleValue1],
                           @"image": @"event_note",
                           @"textLabel": @"More Events",
                           @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                           }];
    
    return [@{
              @"header": @"Change Event",
              @"rows": eventRows
              } mutableCopy];
}

- (NSDictionary *) displaySection {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [@{
        @"header": @"Display Settings",
        @"rows": @[@{
                       @"type": [NSNumber numberWithInteger:kTimeDisplay],
                       @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                       @"image": @"access_time",
                       @"textLabel": @"Time",
                       @"detailTextLabel": [NSDate isDisplayGMT] ? @"GMT Time" : [NSString stringWithFormat:@"Local Time %@", [[NSTimeZone systemTimeZone] name]],
                       @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                       },
                   @{
                       @"type": [NSNumber numberWithInteger:kLocationDisplay],
                       @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                       @"image": @"location_arrow_on",
                       @"textLabel": @"Location",
                       @"detailTextLabel": [[defaults objectForKey:@"showMGRS"] boolValue] ? @"MGRS" : @"Latitude, Longitude",
                       @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                       }]
        
        } mutableCopy];
}

- (NSDictionary *) mediaSection {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *imagePreferences = [defaults dictionaryForKey:@"imageUploadSizes"];
    NSNumber *imagePreference = [defaults valueForKey:[imagePreferences valueForKey:@"preferenceKey"]];
    NSInteger imagePreferenceIndex = [[imagePreferences objectForKey:@"values"] indexOfObject:imagePreference];
    NSString *imagePrefereceLabel = [[imagePreferences objectForKey:@"labels"] objectAtIndex:imagePreferenceIndex];

    NSDictionary *videoPreferences = [defaults dictionaryForKey:@"videoUploadQualities"];
    NSNumber *videoPreference = [defaults valueForKey:[videoPreferences valueForKey:@"preferenceKey"]];
    NSInteger videoPreferenceIndex = [[videoPreferences objectForKey:@"values"] indexOfObject:videoPreference];
    NSString *videoPrefereceLabel = [[videoPreferences objectForKey:@"labels"] objectAtIndex:videoPreferenceIndex];
    
    return [@{
              @"header": @"Media",
              @"rows": @[@{
                             @"type": [NSNumber numberWithInteger:kMediaPhoto],
                             @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                             @"image": @"photo",
                             @"textLabel": @"Photo Upload Size",
                             @"detailTextLabel": imagePrefereceLabel,
                             @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                             },
                         @{
                             @"type": [NSNumber numberWithInteger:kMediaVideo],
                             @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                             @"image": @"movie",
                             @"textLabel": @"Video Upload Quality",
                             @"detailTextLabel": videoPrefereceLabel,
                             @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                             }]
              
              } mutableCopy];
}


- (NSDictionary *) setttingsSection {
    return [@{
      @"header": @"Settings",
      @"rows": @[@{
                     @"type": [NSNumber numberWithInteger:kTheme],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                     @"image": @"brightness_medium",
                     @"textLabel": @"Theme",
                     @"detailTextLabel": [[[ThemeManager sharedManager] curentThemeDefinition] displayName],
                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                     },
                 @{
                     @"type": [NSNumber numberWithInteger:kChangePassword],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                     @"image": @"lock",
                     @"textLabel": @"Change Password",
                     @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                     },
                 @{
                     @"type": [NSNumber numberWithInteger:kLogout],
                     @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                     @"image": @"power",
                     @"textLabel": @"Log Out"
                     }]
      
      } mutableCopy];
}

- (NSDictionary *) aboutSection {
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    return [@{
              @"header": @"About",
              @"rows": @[@{
                             @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                             @"textLabel": @"URL",
                             @"detailTextLabel": [[MageServer baseURL] absoluteString]
                             },
                         @{
                             @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                             @"textLabel": @"User",
                             @"detailTextLabel": user.name
                             },
                         @{
                             @"style": [NSNumber numberWithInteger:UITableViewCellStyleSubtitle],
                             @"textLabel": @"Version",
                             @"detailTextLabel": self.versionCellSelectionCount >= 5 ? [NSString stringWithFormat:@"%@ (%@)", versionString, buildString] : versionString
                             }]
              } mutableCopy];
}

- (NSDictionary *) legalSection {
    NSMutableArray *legalRows = [NSMutableArray array];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL showDisclaimer = [defaults objectForKey:@"showDisclaimer"] != nil && [[defaults objectForKey:@"showDisclaimer"] boolValue];

    if (showDisclaimer) {
        [legalRows addObject:@{
                               @"type": [NSNumber numberWithInteger:kDisclaimer],
                               @"style": [NSNumber numberWithInteger:UITableViewCellStyleDefault],
                               @"textLabel": @"Disclaimer",
                               @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                               }];
    }
    
    [legalRows addObject:@{
                           @"type": [NSNumber numberWithInteger:kAttributions],
                           @"style": [NSNumber numberWithInteger:UITableViewCellStyleDefault],
                           @"textLabel": @"Attributions",
                           @"accessoryType": [NSNumber numberWithInteger:UITableViewCellAccessoryDisclosureIndicator]
                           }];
    
    return [@{
              @"header": @"Legal",
              @"rows": legalRows
              } mutableCopy];
}

@end
