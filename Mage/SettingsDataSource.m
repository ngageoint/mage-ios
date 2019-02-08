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

@property (assign, nonatomic) BOOL showDisclaimer;
@property (assign, nonatomic) NSInteger versionCellSelectionCount;
@property (strong, nonatomic) Event* event;
@property (strong, nonatomic) NSArray<Event *>* recentEvents;
@property (strong, nonatomic) NSArray* sections;

@end

@implementation SettingsDataSource

static const NSInteger CONNECTION_SECTION = 0;
static const NSInteger SERVICES_SECION = 1;
static const NSInteger CURRENT_EVENT_SECTION = 2;
static const NSInteger CHANGE_EVENT_SECTION = 3;
static const NSInteger DISPLAY_SECTION = 4;
static const NSInteger SETTINGS_SECTION = 5;
static const NSInteger ABOUT_SECTION = 6;
static const NSInteger LEGAL_SECTION = 7;

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

- (void) initDatasource {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isLocalLogin = [[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]];
    self.showDisclaimer = [defaults objectForKey:@"showDisclaimer"] != nil && [[defaults objectForKey:@"showDisclaimer"] boolValue];

    NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:self.sections.count];
    
    [sections setObject:@{
                          @"header": @"Connection Status",
                          @"footer": @"You are currently logged in offline. You are not receiving updates from, nor pushing your location or observations to the server. When you regain network connectivity, please log in again to reconnect to the server and work online.",
                          @"rows": [NSNumber numberWithInt:isLocalLogin ? 1 : 0]
                          }
     atIndexedSubscript:CONNECTION_SECTION];
    
    [sections setObject:@{
                          @"header": @"Services",
                          @"rows": [NSNumber numberWithInt:2]
                          }
     atIndexedSubscript:SERVICES_SECION];
    
    [sections setObject:@{
                          @"header": @"Event Information",
                          @"rows": [NSNumber numberWithInteger:1]
                          }
     atIndexedSubscript:CURRENT_EVENT_SECTION];

    [sections setObject:@{
                          @"header": @"Change Event",
                          @"rows": [NSNumber numberWithLong:self.recentEvents.count + 1]
                          }
     atIndexedSubscript:CHANGE_EVENT_SECTION];

    [sections setObject:@{
                          @"header": @"Display Settings",
                          @"rows": [NSNumber numberWithInt:2]
                          }
     atIndexedSubscript:DISPLAY_SECTION];

    [sections setObject:@{
                          @"header": @"Settings",
                          @"rows": [NSNumber numberWithInt:3]
                          }
     atIndexedSubscript:SETTINGS_SECTION];

    [sections setObject:@{
                          @"header": @"About",
                          @"rows": [NSNumber numberWithInt:3]
                          }
     atIndexedSubscript:ABOUT_SECTION];

    [sections setObject:@{
                          @"header": @"Legal",
                          @"rows": [NSNumber numberWithInt:self.showDisclaimer ? 2 : 1]
                          }
     atIndexedSubscript:LEGAL_SECTION];
    
    self.sections = sections;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return self.sections.count;
}

- (NSInteger) tableView:(nonnull UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    return [[[self.sections objectAtIndex:section] valueForKeyPath:@"rows"] integerValue];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath.section == ABOUT_SECTION && indexPath.row == 1) {
        self.versionCellSelectionCount++;

        if (self.versionCellSelectionCount == 5) {
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
    UITableViewCell *cell = nil;

    switch ([indexPath section]) {
        case CONNECTION_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"connectionCell" forIndexPath:indexPath];
            cell.type = [NSNumber numberWithInteger:kConnection];
            
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
            
            // Show label in accessory view and remove disclosure
            cell.accessoryView = offlineLabel;
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            break;
        }
        case SERVICES_SECION: {
            switch ([indexPath row]) {
                case 0: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"locationServicesCell" forIndexPath:indexPath];

                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    CLAuthorizationStatus authorizationStatus =[CLLocationManager authorizationStatus];
                    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
                        cell.detailTextLabel.text = [defaults boolForKey:kReportLocationKey] ? @"On" : @"Off";
                    } else {
                        cell.detailTextLabel.text = @"Disabled";
                    }
                    
                    break;
                }
                case 1: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"dataFetchingCell" forIndexPath:indexPath];
                    cell.textLabel.textColor = [UIColor primaryText];
                    cell.detailTextLabel.textColor = [UIColor primaryText];

                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    cell.detailTextLabel.text = [defaults boolForKey:@"dataFetchEnabled"] ? @"On" : @"Off";
                    
                    break;
                }
            }
            
            break;
        }
        case CURRENT_EVENT_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"currentEventCell" forIndexPath:indexPath];
            cell.textLabel.textColor = [UIColor primaryText];
            cell.textLabel.text = self.event.name;
            cell.imageView.tintColor = [UIColor brightButton];
            cell.type = [NSNumber numberWithInteger:kEventInfo];
            cell.info = self.event;
            
            break;
        }
        case CHANGE_EVENT_SECTION: {
            if (indexPath.row < self.recentEvents.count) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"recentEventCell" forIndexPath:indexPath];
                cell.textLabel.text = [self.recentEvents objectAtIndex:[indexPath row]].name;
                cell.type = [NSNumber numberWithInteger:kChangeEvent];
                cell.info = [self.recentEvents objectAtIndex:indexPath.row];
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"moreEventsCell" forIndexPath:indexPath];
                cell.type = [NSNumber numberWithInteger:kMoreEvents];
            }
            
            break;
        }
        case DISPLAY_SECTION: {
            switch ([indexPath row]) {
                case 0: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"timeDisplayCell" forIndexPath:indexPath];

                    if ([NSDate isDisplayGMT]) {
                        cell.detailTextLabel.text = @"GMT Time";
                    } else {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"Local Time %@", [[NSTimeZone systemTimeZone] name]];
                    }
                    
                    break;
                }
                case 1: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"locationDisplayCell" forIndexPath:indexPath];

                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    cell.detailTextLabel.text = [[defaults objectForKey:@"showMGRS"] boolValue] ? @"MGRS" : @"Latitude, Longitude";
                    break;
                }
            }
            
            break;
        }
        case SETTINGS_SECTION: {
            switch ([indexPath row]) {
                case 0: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"themeCell" forIndexPath:indexPath];
                    cell.detailTextLabel.text = [[[ThemeManager sharedManager] curentThemeDefinition] displayName];
                    cell.type = [NSNumber numberWithInteger:kTheme];
                    break;
                }
                case 1: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"changePasswordCell" forIndexPath:indexPath];
                    cell.type = [NSNumber numberWithInteger:kChangePassword];
                    break;
                }
                case 2: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"logoutCell" forIndexPath:indexPath];
                    cell.type = [NSNumber numberWithInteger:kLogout];
                    break;
                }
            }
            
            break;
        }
        case ABOUT_SECTION: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"aboutCell" forIndexPath:indexPath];
            
            switch ([indexPath row]) {
                case 0: {
                    [cell setUserInteractionEnabled:NO];
                    
                    cell.textLabel.text = @"Server URL";
                    cell.detailTextLabel.text = [[MageServer baseURL] absoluteString];
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Server Version";
                    
                    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                    NSString *buildString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
                    
                    if (self.versionCellSelectionCount == 5) {
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", versionString, buildString];
                    } else {
                        cell.detailTextLabel.text = versionString;
                    }
                    
                    break;
                }
                case 2: {
                    [cell setUserInteractionEnabled:NO];
                    
                    cell.textLabel.text = @"User";
                    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
                    cell.detailTextLabel.text = user.name;
                    
                    break;
                }
            }
            
            break;
        }
        case LEGAL_SECTION: {
            if ([indexPath row] == 0 && self.showDisclaimer) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"disclaimerCell" forIndexPath:indexPath];
                cell.type = [NSNumber numberWithInteger:kDisclaimer];
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"attributionsCell" forIndexPath:indexPath];
                cell.type = [NSNumber numberWithInteger:kAttributions];
            }
            
            break;
        }
        default:
            return nil;
    }
    
    cell.backgroundColor = [UIColor background];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor primaryText];
    cell.imageView.tintColor = [UIColor activeIcon];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
    NSInteger rows = [[[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"rows"] integerValue];
    return rows > 0 ? [[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"header"] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSInteger rows = [[[self.sections objectAtIndex:section] valueForKeyPath:@"rows"] integerValue];
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
    NSInteger rows = [[[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"rows"] integerValue];
    return rows > 0 ? [[self.sections objectAtIndex:sectionIndex] valueForKeyPath:@"footer"] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSInteger rows = [[[self.sections objectAtIndex:section] valueForKeyPath:@"rows"] integerValue];
    id footer = [[self.sections objectAtIndex:section] valueForKeyPath:@"footer"];
    return rows > 0 && footer != nil ? UITableViewAutomaticDimension : CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *) view;
        footer.textLabel.textColor = [UIColor brand];
    }
}

@end
