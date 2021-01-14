//
//  OnlineMapTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OnlineMapTableViewController.h"
#import "ImageryLayer.h"
#import "Layer.h"
#import "Server.h"
#import "ObservationTableHeaderView.h"
#import "MAGE-Swift.h"

@interface OnlineMapTableViewController () <NSFetchedResultsControllerDelegate>
    @property (nonatomic, strong) NSMutableSet *selectedOnlineLayers;
    @property (nonatomic, strong) NSArray *onlineLayers;
    @property (nonatomic, strong) NSArray *insecureOnlineLayers;
    @property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLayersButton;
@property (strong, nonatomic) NSFetchedResultsController *onlineLayersFetchedResultsController;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation OnlineMapTableViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.scheme = containerScheme;
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
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
    [self applyThemeWithContainerScheme:self.scheme];
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
        return [[ObservationTableHeaderView alloc] initWithName:@"Nonsecure Layers" andScheme:self.scheme];
    }
    return [[ObservationTableHeaderView alloc] initWithName:@"Online Layers" andScheme:self.scheme];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    NSUInteger sectionCount = [[self.onlineLayersFetchedResultsController sections] count];
    
    if (sectionCount == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * .8, self.view.bounds.size.height)];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        imageView.image = [UIImage imageNamed:@"layers_large"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.alpha = 0.6f;
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * .8, 0)];
        title.text = @"No Layers";
        title.numberOfLines = 0;
        title.textAlignment = NSTextAlignmentCenter;
        title.translatesAutoresizingMaskIntoConstraints = NO;
        title.font = [UIFont systemFontOfSize:24];
        title.alpha = 0.6f;
        [title sizeToFit];
        
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * .8, 0)];
        description.text = @"Event administrators can add layers to your event.";
        description.numberOfLines = 0;
        description.textAlignment = NSTextAlignmentCenter;
        description.translatesAutoresizingMaskIntoConstraints = NO;
        description.alpha = 0.6f;
        [description sizeToFit];
        
        [view addSubview:title];
        [view addSubview:description];
        [view addSubview:imageView];
        
        [title addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:self.view.bounds.size.width * .8]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];

        [description addConstraint:[NSLayoutConstraint constraintWithItem:description attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:self.view.bounds.size.width * .8]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:description attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:100]];
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:100]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1 constant:16]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:description attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeBottom multiplier:1 constant:16]];
        
        self.tableView.backgroundView = view;
        return 0;
    }
    self.tableView.backgroundView = nil;
    
    return sectionCount;
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
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.accessoryView = nil;
    } else {
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        UISwitch *cacheSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        cacheSwitch.on = [self.selectedOnlineLayers containsObject:layer.remoteId];
        cacheSwitch.onTintColor = self.scheme.colorScheme.primaryColorVariant;
        cacheSwitch.tag = indexPath.row;
        [cacheSwitch addTarget:self action:@selector(layerToggled:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = cacheSwitch;
    }
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    
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
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0;
}

@end
