//
//  MapSettings.m
//  MAGE
//
//

#import "MapSettings.h"
#import "MapTypeTableViewCell.h"
#import "GridTypeTableViewCell.h"
#import "ObservationTableHeaderView.h"
#import "MAGE-Swift.h"

@interface MapSettings () <UITableViewDelegate, UITableViewDataSource, MapTypeDelegate, GridTypeDelegate>
    @property (strong) id<MapSettingsDelegate> delegate;
@property (strong) NSArray *feeds;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation MapSettings

static const NSInteger TOTAL_SECTIONS = 3;

static const NSInteger LAYERS_SECTION = 0;
static const NSInteger MAGE_SECTION = 1;
static const NSInteger FEED_SECTION = 2;

static const NSInteger TOTAL_LAYER_SECTIONS = 5;

static const NSInteger LAYERS_ROW_MAP_TYPE = 0;
static const NSInteger LAYERS_ROW_GRID_TYPE = 1;
static const NSInteger LAYERS_ROW_TRAFFIC = 2;
static const NSInteger LAYERS_ROW_DOWNLOADABLE = 3;
static const NSInteger LAYERS_ROW_ONLINE = 4;

static const NSInteger MAGE_ROW_OBSERVATIONS = 0;
static const NSInteger MAGE_ROW_PEOPLE = 1;

static NSString *LAYERS_SECTION_NAME = @"Layers";
static NSString *MAGE_SECTION_NAME = @"MAGE";
static NSString *FEED_SECTION_NAME = @"Feeds";

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
}

- (instancetype) initWithDelegate: (id<MapSettingsDelegate>) delegate scheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.scheme = containerScheme;
    self.delegate = delegate;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.tableView.accessibilityIdentifier = @"settings";
    [self applyThemeWithContainerScheme:self.scheme];
    [self.tableView registerNib:[UINib nibWithNibName:@"MapTypeCell" bundle:nil] forCellReuseIdentifier:@"MapTypeCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GridTypeCell" bundle:nil] forCellReuseIdentifier:@"GridTypeCell"];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _feeds = [Feed getMappableFeedsWithEventId:[Server currentEventId]];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == LAYERS_SECTION) {
        return [self isTrafficAvailable] ? TOTAL_LAYER_SECTIONS : TOTAL_LAYER_SECTIONS - 1;
    } else if (section == MAGE_SECTION) {
        return 2;
    } else if (section == FEED_SECTION) {
        return [_feeds count];
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return TOTAL_SECTIONS;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (indexPath.section == LAYERS_SECTION) {
        if (indexPath.row == LAYERS_ROW_MAP_TYPE) {
            MapTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapTypeCell"];
            cell.mapTypeSegmentedControl.selectedSegmentTintColor = self.scheme.colorScheme.primaryColor;
            [cell.mapTypeSegmentedControl setTitleTextAttributes:@{
                NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]
            } forState:UIControlStateNormal];
            [cell.mapTypeSegmentedControl setTitleTextAttributes:@{
                NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor
            } forState:UIControlStateSelected];
            cell.mapTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"mapType"];
            cell.cellTitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.delegate = self;
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            return cell;
        }
        if (indexPath.row == LAYERS_ROW_GRID_TYPE) {
            GridTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GridTypeCell"];
            cell.gridTypeSegmentedControl.selectedSegmentTintColor = self.scheme.colorScheme.primaryColor;
            [cell.gridTypeSegmentedControl setTitleTextAttributes:@{
                NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]
            } forState:UIControlStateNormal];
            [cell.gridTypeSegmentedControl setTitleTextAttributes:@{
                NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor
            } forState:UIControlStateSelected];
            cell.gridTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"gridType"];
            cell.cellTitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.delegate = self;
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
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
            trafficSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            [trafficSwitch addTarget:self action:@selector(trafficSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = trafficSwitch;
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            return cell;
        } else if (row == LAYERS_ROW_DOWNLOADABLE) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OfflineMapsCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OfflineMapsCell"];
            }
            cell.textLabel.text = @"Offline Layers";
            
            if (self.mapsToDownloadCount > 0) {
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
                [imageView setTintColor:self.scheme.colorScheme.primaryColor];
                cell.accessoryView = imageView;
            } else {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
            return cell;
        } else if (row == LAYERS_ROW_ONLINE) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StaticLayerCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StaticLayerCell"];
            }
            cell.textLabel.text = @"Online Layers";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
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
            observationSwitch.on = !defaults.hideObservations;
            observationSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            [observationSwitch addTarget:self action:@selector(observationSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = observationSwitch;
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
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
            peopleSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            [peopleSwitch addTarget:self action:@selector(peopleSwitchChanged:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = peopleSwitch;
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
            return cell;
        }
    } else if (indexPath.section == FEED_SECTION) {
        NSArray *selectedFeeds = [defaults arrayForKey:[NSString stringWithFormat:@"selectedFeeds-%@", [Server currentEventId]]];
        Feed *feed = [_feeds objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellWithSwitch"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CellWithSwitch"];
        }
        cell.textLabel.text = feed.title;
        cell.detailTextLabel.text = feed.summary;
        UISwitch *observationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        observationSwitch.on = [selectedFeeds containsObject:feed.remoteId];
        observationSwitch.tag = feed.tag.integerValue;
        observationSwitch.accessibilityLabel = [NSString stringWithFormat:@"feed-switch-%@", feed.remoteId];
        NSLog(@"added switch called feed-switch-%@", feed.remoteId);
        observationSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
        [observationSwitch addTarget:self action:@selector(feedSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = observationSwitch;
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
        return cell;
    }

    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == LAYERS_SECTION) {
        return LAYERS_SECTION_NAME;
    } else if (section == MAGE_SECTION) {
        return MAGE_SECTION_NAME;
    } else if (section == FEED_SECTION && [_feeds count] != 0) {
        return FEED_SECTION_NAME;
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == LAYERS_SECTION) {
        NSInteger row = indexPath.row;
        if (![self isTrafficAvailable]) {
            row = row + 1;
        }
        if (row == LAYERS_ROW_ONLINE) {
            [self.delegate onlineMapsCellTapped];
        } else if (row == LAYERS_ROW_DOWNLOADABLE) {
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
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
}

- (UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section] andScheme:self.scheme];
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

- (void)gridTypeChanged:(GridType)gridType {

}

- (void) trafficSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.on forKey:@"mapShowTraffic"];
    [defaults synchronize];
}

- (void) observationSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    defaults.hideObservations = !sender.on;
    [defaults synchronize];
}

- (void) peopleSwitchChanged: (UISwitch *) sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!sender.on forKey:@"hidePeople"];
    [defaults synchronize];
}

- (void) feedSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    Feed* feed = (Feed *)[Feed MR_findFirstByAttribute:@"tag" withValue:[NSNumber numberWithInteger: sender.tag]];
    NSMutableArray *selectedFeedsForEvent = [[defaults arrayForKey:[NSString stringWithFormat:@"selectedFeeds-%@", [Server currentEventId]]] mutableCopy];
    if (sender.on) {
        [selectedFeedsForEvent addObject:feed.remoteId];
    } else {
        [selectedFeedsForEvent removeObject:feed.remoteId];
    }
    [defaults setObject:selectedFeedsForEvent forKey:[NSString stringWithFormat:@"selectedFeeds-%@", [Server currentEventId]]];
    [defaults synchronize];
    
    BOOL isOn = sender.on;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        Feed *localFeed = [feed MR_inContext:localContext];
        [localFeed setSelected:isOn];
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        
    }];

}

@end
