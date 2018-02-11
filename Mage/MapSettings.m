//
//  MapSettings.m
//  MAGE
//
//

#import "MapSettings.h"
#import "MapTypeTableViewCell.h"

@interface MapSettings () <UITableViewDelegate, UITableViewDataSource>
    @property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;
    @property (weak, nonatomic) IBOutlet UISwitch *showObservationsSwitch;
    @property (weak, nonatomic) IBOutlet UISwitch *showPeopleSwitch;
    @property (strong) id<MapSettingsDelegate> delegate;
@end

@implementation MapSettings

- (instancetype) initWithDelegate: (id<MapSettingsDelegate>) delegate {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.delegate = delegate;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MapTypeCell" bundle:nil] forCellReuseIdentifier:@"MapTypeCell"];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mapTypeSegmentedControl.selectedSegmentIndex = [defaults integerForKey:@"mapType"];
    
    
    self.showObservationsSwitch.on = ![defaults boolForKey:@"hideObservations"];
    
    self.showPeopleSwitch.on = ![defaults boolForKey:@"hidePeople"];
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"MAP TYPE";
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

@end
