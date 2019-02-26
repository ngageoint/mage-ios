//
//  DataFetchSettingsTableViewController.m
//  Mage
//
//

#import "DataFetchSettingsTableViewController.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "RightDetailSubtitleTableViewCell.h"

@interface DataFetchSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *dataFetchSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *observationFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataFetchingLabel;
@property (weak, nonatomic) IBOutlet UILabel *usersLabel;
@property (weak, nonatomic) IBOutlet UILabel *usersDescription;
@property (weak, nonatomic) IBOutlet UILabel *observationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *observationsDescription;

@property (assign, nonatomic) BOOL fetchEnabled;

@end

@implementation DataFetchSettingsTableViewController

static NSInteger USER_FETCH_CELL_ROW = 0;
static NSInteger OBSERVATION_FETCH_CELL_ROW = 1;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.fetchEnabled = [[defaults objectForKey:@"dataFetchEnabled"] boolValue];
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"RightDetailSubtitleCell" bundle:nil] forCellReuseIdentifier:@"rightDetailSubtitleCell"];
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self registerForThemeChanges];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
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

- (void) dataFetchSwitched:(id)sender {
    BOOL on = [sender isOn];
    self.fetchEnabled = on;
    
    if (on) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: on ? @"YES" : @"NO" forKey:@"dataFetchEnabled"];
    [defaults synchronize];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return self.fetchEnabled ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text =  @"Data Fetching";
        cell.textLabel.textColor = [UIColor primaryText];
        cell.backgroundColor = [UIColor background];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.onTintColor = [UIColor themedButton];
        cell.accessoryView = toggle;

        [toggle setOn:self.fetchEnabled animated:NO];
        [toggle addTarget:self action:@selector(dataFetchSwitched:) forControlEvents:UIControlEventValueChanged];

        return cell;
    } else {
        RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];

        if (indexPath.row == USER_FETCH_CELL_ROW) {
            cell.title.text = @"Users";
            cell.subtitle.text = @"Updates to user locations will be fetched at this interval. Smaller intervals will fetch user locations more often at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"userFetch"];
        } else {
            cell.title.text = @"Observations";
            cell.subtitle.text = @"Updates to observations will be fetched at this interval. Smaller intervals will fetch observations more often at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"observationFetch"];
        }
        
        cell.title.textColor = [UIColor primaryText];
        cell.subtitle.textColor = [UIColor secondaryText];
        cell.detail.textColor = [UIColor primaryText];
        cell.backgroundColor = [UIColor background];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return;
    }

    NSString *key = indexPath.row == USER_FETCH_CELL_ROW ? @"userFetch" : @"observationFetch";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *fetchPreferences = [defaults dictionaryForKey:key];
    
    ValuePickerTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"ValuePicker" owner:self options:nil][0];

    viewController.title = [fetchPreferences valueForKey:@"title"];
    viewController.section = [fetchPreferences valueForKey:@"section"];
    viewController.labels = [fetchPreferences valueForKey:@"labels"];
    viewController.values = [fetchPreferences valueForKey:@"values"];
    viewController.preferenceKey = [fetchPreferences valueForKey:@"preferenceKey"];
    [self.navigationController pushViewController:viewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"Data Fetch Frequency";
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [UIColor brand];
    }
}

@end
