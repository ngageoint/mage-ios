//
//  StaticLayerTableViewController.m
//  MAGE
//
//

#import "StaticLayerTableViewController.h"
#import "StaticLayerTableViewCell.h"
#import "StaticLayer.h"
#import "Layer.h"
#import "Server.h"
#import "Theme+UIResponder.h"

@interface StaticLayerTableViewController ()
    @property (nonatomic, strong) NSMutableSet *selectedStaticLayers;
    @property (nonatomic, strong) NSArray *staticLayers;
    @property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLayersButton;
@end

@implementation StaticLayerTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForThemeChanges];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh Layers" style:UIBarButtonItemStylePlain target:self action:@selector(refreshLayers:)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedStaticLayers = [NSMutableSet setWithArray:[defaults valueForKeyPath:[NSString stringWithFormat: @"selectedStaticLayers.%@", [Server currentEventId]]]];
    
    self.staticLayers = [StaticLayer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(staticLayerFetched:) name: LayerFetched object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(staticLayerFetched:) name: StaticLayerLoaded object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)staticLayerFetched:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        weakSelf.staticLayers = [StaticLayer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]]];
        [weakSelf.tableView reloadData];
        weakSelf.refreshLayersButton.enabled = YES;
    });
}

- (IBAction)refreshLayers:(id)sender {
    self.refreshLayersButton.enabled = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:[NSString stringWithFormat: @"selectedStaticLayers.%@", [Server currentEventId]]];
    self.staticLayers = [[NSArray alloc] init];
    [self.selectedStaticLayers removeAllObjects];
    [self.tableView reloadData];
    
    [Layer refreshLayersForEvent:[Server currentEventId]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"static layer count %lu", (unsigned long)self.staticLayers.count);
    return self.staticLayers.count;
}

- (StaticLayer *) layerForRow: (NSUInteger) row {
    return [self.staticLayers objectAtIndex: row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"staticLayerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"staticLayerCell"];
    }
    
    StaticLayer *layer = [self layerForRow:indexPath.row];
    
    cell.textLabel.text = layer.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu features", (unsigned long)[(NSArray *)[layer.data objectForKey:@"features"] count]];
    
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.backgroundColor = [UIColor background];
    
    if (![layer.loaded boolValue]) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicator setFrame:CGRectZero];
        [activityIndicator startAnimating];
        cell.accessoryView = activityIndicator;
        activityIndicator.color = [UIColor secondaryText];
    } else {
        cell.accessoryView = nil;
        cell.accessoryType = [self.selectedStaticLayers containsObject:layer.remoteId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];

    if (![[self layerForRow:indexPath.row].loaded boolValue]) {
        return;
    }
    
    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedStaticLayers addObject:[self layerForRow:indexPath.row].remoteId];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedStaticLayers removeObject:[self layerForRow:indexPath.row].remoteId];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@{[[Server currentEventId] stringValue] :[self.selectedStaticLayers allObjects]} forKey:@"selectedStaticLayers"];
    [defaults synchronize];
    
    [tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

@end
