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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger mapType = [defaults integerForKey:@"mapType"];
        return (mapType == MKMapTypeStandard || mapType == MKMapTypeHybrid) ? 2 : 1;
    }
    
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            MapTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapTypeCell"];
            cell.mapTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"mapType"];
            cell.mapTypeSegmentedControl.tintColor = [UIColor brand];
            cell.delegate = self;
            
            return cell;
        } else if (indexPath.row == 1) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationSettingsCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ObservationSettingsCell"];
            }
            
            cell.textLabel.text = @"Traffic";
            cell.detailTextLabel.text = @"Show Apple Maps Traffic";
            UISwitch *trafficSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            trafficSwitch.on = [defaults boolForKey:@"mapShowTraffic"];
            trafficSwitch.onTintColor = [UIColor themedButton];
            [trafficSwitch addTarget:self action:@selector(trafficSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = trafficSwitch;
            
            return cell;
        }
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationSettingsCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ObservationSettingsCell"];
        }
        cell.textLabel.text = @"Observations";
        cell.detailTextLabel.text = @"Show observations on map";
        UISwitch *observationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        observationSwitch.on = ![defaults boolForKey:@"hideObservations"];
        observationSwitch.onTintColor = [UIColor themedButton];
        [observationSwitch addTarget:self action:@selector(observationSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = observationSwitch;
        
        return cell;
    } else if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeopleSettingsCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"PeopleSettingsCell"];
        }
        cell.textLabel.text = @"People";
        cell.detailTextLabel.text = @"Show people on map";
        UISwitch *peopleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        peopleSwitch.on = ![defaults boolForKey:@"hidePeople"];
        peopleSwitch.onTintColor = [UIColor themedButton];
        [peopleSwitch addTarget:self action:@selector(peopleSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = peopleSwitch;
        
        return cell;
    } else if (indexPath.section == 3) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StaticLayerCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StaticLayerCell"];
        }
        cell.textLabel.text = @"Static Layers";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    } else if (indexPath.section == 4) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OfflineMapsCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OfflineMapsCell"];
        }
        cell.textLabel.text = @"Offline Maps";
        
        if (self.mapsToDownloadCount > 0) {
            UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            circle.layer.cornerRadius = 10;
            circle.layer.borderWidth = .5;
            circle.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            [circle setBackgroundColor:[UIColor mageBlue]];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
            [imageView setFrame:CGRectMake(-2, -2, 24, 24)];
            [imageView setTintColor:[UIColor whiteColor]];
            [circle addSubview:imageView];
            cell.accessoryView = circle;
        } else {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    } else if (indexPath.section == 5) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StaticLayerCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StaticLayerCell"];
        }
        cell.textLabel.text = @"Online Maps";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Maps";
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 1) {
        UISwitch *accessorySwitch = (UISwitch *)([self.tableView cellForRowAtIndexPath:indexPath].accessoryView);
        accessorySwitch.on = !accessorySwitch.on;
        [self observationSwitchChanged:accessorySwitch];
    } else if (indexPath.section == 2) {
        UISwitch *accessorySwitch = (UISwitch *)([self.tableView cellForRowAtIndexPath:indexPath].accessoryView);
        accessorySwitch.on = !accessorySwitch.on;
        [self peopleSwitchChanged:accessorySwitch];
    } else if (indexPath.section == 3) {
        [self.delegate staticLayersCellTapped];
    } else if (indexPath.section == 4) {
        [self.delegate offlineMapsCellTapped];
    } else if (indexPath.section == 5) {
        [self.delegate onlineMapsCellTapped];
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor dialog];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.textLabel.textColor = [UIColor primaryText];
}

-(UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 45.0f;
    }
    return UITableViewAutomaticDimension;
}

- (void) mapTypeChanged:(MKMapType) mapType {
    Boolean showingTraffic = [self.tableView numberOfRowsInSection:0] == 2 ? true : false;
    if (mapType == MKMapTypeSatellite && showingTraffic) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    } else if ((mapType == MKMapTypeStandard || mapType == MKMapTypeHybrid) && !showingTraffic) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
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
