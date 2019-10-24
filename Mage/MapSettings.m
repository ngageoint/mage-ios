//
//  MapSettings.m
//  MAGE
//
//

#import "MapSettings.h"
#import "MapTypeTableViewCell.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"

@interface MapSettings () <UITableViewDelegate, UITableViewDataSource, MapTypeDelegate>
    @property (strong) id<MapSettingsDelegate> delegate;
@end

@implementation MapSettings

static const NSInteger TOTAL_SECTIONS = 3;

static const NSInteger LAYERS_SECTION = 0;
static const NSInteger MAGE_SECTION = 1;
static const NSInteger EXTERNAL_SECTION = 2;

static const NSInteger LAYERS_ROW_MAP_TYPE = 0;
static const NSInteger LAYERS_ROW_TRAFFIC = 1;
static const NSInteger LAYERS_ROW_DOWNLOADABLE = 2;
static const NSInteger LAYERS_ROW_ONLINE = 3;

static const NSInteger MAGE_ROW_OBSERVATIONS = 0;
static const NSInteger MAGE_ROW_PEOPLE = 1;

static NSString *LAYERS_SECTION_NAME = @"Layers";
static NSString *MAGE_SECTION_NAME = @"MAGE";
static NSString *EXTERNAL_SECTION_NAME = @"External Data";

- (void) themeDidChange:(MageTheme)theme {
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor navBarPrimaryText] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.translucent = NO;
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

- (instancetype) initWithDelegate: (id<MapSettingsDelegate>) delegate {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.delegate = delegate;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self registerForThemeChanges];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MapTypeCell" bundle:nil] forCellReuseIdentifier:@"MapTypeCell"];
}

- (void) setMapsToDownloadCount:(NSUInteger)mapsToDownloadCount {
    _mapsToDownloadCount = mapsToDownloadCount;
    [self.tableView reloadData];
}

- (BOOL) isTrafficAvailable {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger mapType = [defaults integerForKey:@"mapType"];
    return (mapType == MKMapTypeStandard || mapType == MKMapTypeHybrid);
}

- (BOOL) hasExternalData {
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == LAYERS_SECTION) {
        return [self isTrafficAvailable] ? 4 : 3;
    } else if (section == MAGE_SECTION) {
        return 2;
    } else if (section == EXTERNAL_SECTION) {
        return 0;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self hasExternalData] ? TOTAL_SECTIONS : TOTAL_SECTIONS - 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (indexPath.section == LAYERS_SECTION) {
        if (indexPath.row == LAYERS_ROW_MAP_TYPE) {
            MapTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapTypeCell"];
            cell.mapTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"mapType"];
            cell.mapTypeSegmentedControl.tintColor = [UIColor brand];
            cell.delegate = self;
            
            return cell;
        }
        NSInteger row = indexPath.row;
        if (![self isTrafficAvailable]) {
            row = row + 1;
        }
        
        if (row == LAYERS_ROW_TRAFFIC) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellWithSwitch"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CellWithSwitch"];
            }
            
            cell.textLabel.text = @"Traffic";
            cell.detailTextLabel.text = @"Show Apple Maps Traffic";
            UISwitch *trafficSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            trafficSwitch.on = [defaults boolForKey:@"mapShowTraffic"];
            trafficSwitch.onTintColor = [UIColor themedButton];
            [trafficSwitch addTarget:self action:@selector(trafficSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = trafficSwitch;
            
            return cell;
        } else if (row == LAYERS_ROW_DOWNLOADABLE) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OfflineMapsCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OfflineMapsCell"];
            }
            cell.textLabel.text = @"Downloadable Maps";
            
            if (self.mapsToDownloadCount > 0) {
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
                [imageView setTintColor:[UIColor brand]];
                cell.accessoryView = imageView;
            } else {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            return cell;
        } else if (row == LAYERS_ROW_ONLINE) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StaticLayerCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StaticLayerCell"];
            }
            cell.textLabel.text = @"Online Maps";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    } else if (indexPath.section == MAGE_SECTION) {
        if (indexPath.row == MAGE_ROW_OBSERVATIONS) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellWithSwitch"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CellWithSwitch"];
            }
            cell.textLabel.text = @"Observations";
            cell.detailTextLabel.text = @"Show observations on map";
            UISwitch *observationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            observationSwitch.on = ![defaults boolForKey:@"hideObservations"];
            observationSwitch.onTintColor = [UIColor themedButton];
            [observationSwitch addTarget:self action:@selector(observationSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = observationSwitch;
            
            return cell;
        } else if (indexPath.row == MAGE_ROW_PEOPLE) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellWithSwitch"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CellWithSwitch"];
            }
            cell.textLabel.text = @"People";
            cell.detailTextLabel.text = @"Show people on map";
            UISwitch *peopleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            peopleSwitch.on = ![defaults boolForKey:@"hidePeople"];
            peopleSwitch.onTintColor = [UIColor themedButton];
            [peopleSwitch addTarget:self action:@selector(peopleSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = peopleSwitch;
            
            return cell;
        }
    } else if (indexPath.section == EXTERNAL_SECTION) {
        return 0;
    }

    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == LAYERS_SECTION) {
        return LAYERS_SECTION_NAME;
    } else if (section == MAGE_SECTION) {
        return MAGE_SECTION_NAME;
    } else if (section == EXTERNAL_SECTION) {
        return EXTERNAL_SECTION_NAME;
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == LAYERS_SECTION) {
        if (indexPath.row == LAYERS_ROW_ONLINE) {
            [self.delegate onlineMapsCellTapped];
        } else if (indexPath.row == LAYERS_ROW_DOWNLOADABLE) {
            [self.delegate offlineMapsCellTapped];
        }
    } else if (indexPath.section == MAGE_SECTION) {
        if (indexPath.row == MAGE_ROW_OBSERVATIONS) {
            UISwitch *accessorySwitch = (UISwitch *)([self.tableView cellForRowAtIndexPath:indexPath].accessoryView);
            accessorySwitch.on = !accessorySwitch.on;
            [self observationSwitchChanged:accessorySwitch];
        } else if (indexPath.row == MAGE_ROW_PEOPLE) {
            UISwitch *accessorySwitch = (UISwitch *)([self.tableView cellForRowAtIndexPath:indexPath].accessoryView);
            accessorySwitch.on = !accessorySwitch.on;
            [self peopleSwitchChanged:accessorySwitch];
        }
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor dialog];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.textLabel.textColor = [UIColor primaryText];
}

- (UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (UIView *) tableView:(UITableView*) tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0f;
}

- (void) mapTypeChanged:(MKMapType) mapType {
    if (([self isTrafficAvailable] && [self.tableView numberOfRowsInSection:LAYERS_SECTION] == 3)
        || (![self isTrafficAvailable] && [self.tableView numberOfRowsInSection:LAYERS_SECTION] == 4)){
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:LAYERS_SECTION] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) trafficSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.on forKey:@"mapShowTraffic"];
    [defaults synchronize];
}

- (void) observationSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!sender.on forKey:@"hideObservations"];
    [defaults synchronize];
}

- (void) peopleSwitchChanged: (UISwitch *) sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!sender.on forKey:@"hidePeople"];
    [defaults synchronize];
}

@end
