//
//  OnlineMapTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OnlineMapTableViewController.h"
#import "Theme+UIResponder.h"
#import "Layer.h"
#import "Server.h"

@interface OnlineMapTableViewController ()
    @property (nonatomic, strong) NSMutableSet *selectedOnlineLayers;
    @property (nonatomic, strong) NSArray *onlineLayers;
    @property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLayersButton;
@end

@implementation OnlineMapTableViewController
- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (instancetype) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedOnlineLayers = [NSMutableSet setWithArray:[defaults valueForKeyPath:[NSString stringWithFormat: @"selectedOnlineLayers.%@", [Server currentEventId]]]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh Layers" style:UIBarButtonItemStylePlain target:self action:@selector(refreshLayers:)];
    [self update];
    [self registerForThemeChanges];
}

- (void) reloadTable {
    self.onlineLayers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]]];

    [self.tableView reloadData];
    self.refreshLayersButton.enabled = YES;
}

- (IBAction)refreshLayers:(id)sender {
    self.refreshLayersButton.enabled = NO;
    
    [self updateAndReloadData];
    
    [Layer refreshLayersForEvent:[Server currentEventId]];
}

-(void) updateAndReloadData{
    [self update];
    [self.tableView reloadData];
}

-(void) update{
    self.onlineLayers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ && type == %@", [Server currentEventId], @"Imagery"]];

    self.refreshLayersButton.enabled = YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.onlineLayers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;

    Layer *layer = [self.onlineLayers objectAtIndex:indexPath.row];
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"onlineLayerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"onlineLayerCell"];
    }
    
    cell.textLabel.text = layer.name;
    if ([layer.type isEqualToString:@"Imagery"]) {
        cell.detailTextLabel.text = layer.url;
    } else {
        cell.detailTextLabel.text = layer.type;
    }
    if (![[layer url] hasPrefix:@"https"]) {
        cell.textLabel.textColor = [UIColor secondaryText];
    } else {
        cell.textLabel.textColor = [UIColor primaryText];
    }
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.backgroundColor = [UIColor dialog];
    
    cell.accessoryView = nil;
    cell.accessoryType = [self.selectedOnlineLayers containsObject:layer.remoteId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
 
    cell.backgroundColor = [UIColor dialog];
    return cell;
}

- (Layer *) layerForRow: (NSUInteger) row {
    return [self.onlineLayers objectAtIndex: row];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    
    if (![[[self layerForRow:indexPath.row] url] hasPrefix:@"https"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Non HTTPS Layer"
                                                                       message:@"We cannot load this layer on mobile because it cannot be accessed securely."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedOnlineLayers addObject:[self layerForRow:indexPath.row].remoteId];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedOnlineLayers removeObject:[self layerForRow:indexPath.row].remoteId];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@{[[Server currentEventId] stringValue] :[self.selectedOnlineLayers allObjects]} forKey:@"selectedOnlineLayers"];
    [defaults synchronize];
    
    [tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}
@end
