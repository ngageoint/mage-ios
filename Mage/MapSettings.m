//
//  MapSettings.m
//  MAGE
//
//

#import "MapSettings.h"
#import "MapTypeTableViewCell.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "Layer.h"
#import "Server.h"

@interface MapSettings () <UITableViewDelegate, UITableViewDataSource>
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
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

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (indexPath.section == 0) {
        MapTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapTypeCell"];
        cell.mapTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"mapType"];
        cell.mapTypeSegmentedControl.tintColor = [UIColor brand];
        return cell;
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
        
        NSUInteger count = [Layer MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND type == %@ AND (loaded == 0 || loaded == nil)", [Server currentEventId], @"GeoPackage"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (count > 0) {
            UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            circle.layer.cornerRadius = 10;
            [circle setBackgroundColor:[UIColor mageBlue]];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
            [imageView setFrame:CGRectMake(-2, -2, 24, 24)];
            [imageView setTintColor:[UIColor whiteColor]];
            [circle addSubview:imageView];
            cell.accessoryView = circle;
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Map Type";
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
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor background];
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

@end
