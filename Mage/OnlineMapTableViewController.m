//
//  OnlineMapTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OnlineMapTableViewController.h"
#import "Theme+UIResponder.h"
#import "ImageryLayer.h"
#import "Layer.h"
#import "Server.h"
#import "ObservationTableHeaderView.h"

@interface OnlineMapTableViewController () <NSFetchedResultsControllerDelegate>
    @property (nonatomic, strong) NSMutableSet *selectedOnlineLayers;
    @property (nonatomic, strong) NSArray *onlineLayers;
    @property (nonatomic, strong) NSArray *insecureOnlineLayers;
    @property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLayersButton;
@property (strong, nonatomic) NSFetchedResultsController *onlineLayersFetchedResultsController;
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
    
    self.onlineLayersFetchedResultsController = [ImageryLayer MR_fetchAllGroupedBy:@"isSecure" withPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]] sortedBy:@"isSecure,name:YES" ascending:NO delegate:self];
    [self.onlineLayersFetchedResultsController performFetch:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh Layers" style:UIBarButtonItemStylePlain target:self action:@selector(refreshLayers:)];
    [self registerForThemeChanges];
}

- (IBAction)refreshLayers:(id)sender {
    [Layer refreshLayersForEvent:[Server currentEventId]];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] endUpdates];
}


#pragma mark - Table view data source

- (UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [[ObservationTableHeaderView alloc] initWithName:@"Nonsecure Layers"];
    }
    return [[ObservationTableHeaderView alloc] initWithName:@"Online Layers"];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    return [[self.onlineLayersFetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.onlineLayersFetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ImageryLayer *layer = [self.onlineLayersFetchedResultsController objectAtIndexPath:indexPath];
      
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"onlineLayerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"onlineLayerCell"];
    }
    
    cell.textLabel.text = layer.name;
    cell.detailTextLabel.text = layer.url;
    if (!layer.isSecure) {
        cell.textLabel.textColor = [UIColor secondaryText];
    } else {
        cell.textLabel.textColor = [UIColor primaryText];
    }
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.backgroundColor = [UIColor dialog];
    
    UISwitch *cacheSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cacheSwitch.on = [self.selectedOnlineLayers containsObject:layer.remoteId];
    cacheSwitch.onTintColor = [UIColor themedButton];
    cacheSwitch.tag = indexPath.row;
    [cacheSwitch addTarget:self action:@selector(layerToggled:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = cacheSwitch;
    
    return cell;
}

- (IBAction)layerToggled: (UISwitch *)sender {
    ImageryLayer *layer = [self.onlineLayersFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    if (sender.on) {
        [self.selectedOnlineLayers addObject:layer.remoteId];
    } else {
        [self.selectedOnlineLayers removeObject:layer.remoteId];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@{[[Server currentEventId] stringValue] :[self.selectedOnlineLayers allObjects]} forKey:@"selectedOnlineLayers"];
    [defaults synchronize];
}

- (ImageryLayer *) layerForRow: (NSUInteger) row {
    return [self.onlineLayers objectAtIndex: row];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    ImageryLayer *layer = [self.onlineLayersFetchedResultsController objectAtIndexPath:indexPath];
    
    if (!layer.isSecure) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Non HTTPS Layer"
                                                                       message:@"We cannot load this layer on mobile because it cannot be accessed securely."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
//    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
//
//    if (cell.accessoryType == UITableViewCellAccessoryNone) {
//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
//        [self.selectedOnlineLayers addObject:layer.remoteId];
//    } else {
//        cell.accessoryType = UITableViewCellAccessoryNone;
//        [self.selectedOnlineLayers removeObject:layer.remoteId];
//    }
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@{[[Server currentEventId] stringValue] :[self.selectedOnlineLayers allObjects]} forKey:@"selectedOnlineLayers"];
//    [defaults synchronize];
//
//    [tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0;
}

@end
