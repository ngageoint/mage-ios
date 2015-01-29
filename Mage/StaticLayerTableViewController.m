//
//  StaticLayerTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 1/22/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "StaticLayerTableViewController.h"
#import "StaticLayerTableViewCell.h"
#import <StaticLayer+helper.h>

@interface StaticLayerTableViewController ()
    @property (nonatomic, strong) NSMutableSet *selectedStaticLayers;
    @property (nonatomic, strong) NSArray *staticLayers;
@end

@implementation StaticLayerTableViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedStaticLayers = [NSMutableSet setWithArray:[defaults objectForKey:@"selectedStaticLayers"]];
    self.staticLayers = [StaticLayer MR_findAll];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(staticLayerFetched:) name: StaticLayerLoaded object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StaticLayerLoaded object:nil];
}

- (void)staticLayerFetched:(NSNotification *)notification {
    NSLog(@"static layer loaded");
    self.staticLayers = [StaticLayer MR_findAll];
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.tableView reloadData];
    });
}

- (IBAction)refreshLayers:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"selectedStaticLayers"];
    self.selectedStaticLayers = nil;
    self.staticLayers = nil;
    [self.tableView reloadData];
    [StaticLayer refreshStaticLayers:^(BOOL success) {
        NSLog(@"static layers refreshed");
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.staticLayers.count;
}

- (StaticLayer *) layerForRow: (NSUInteger) row {
    return [self.staticLayers objectAtIndex: row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StaticLayerTableViewCell *cell = (StaticLayerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"staticLayerCell" forIndexPath:indexPath];
    StaticLayer *layer = [self layerForRow:indexPath.row];
    
    cell.layerNameLabel.text = layer.name;
    cell.loadingIndicator.hidden = [layer.loaded boolValue];
    cell.featureCountLabel.text = [NSString stringWithFormat:@"%lu features", (unsigned long)[(NSArray *)[layer.data objectForKey:@"features"] count]];
    cell.selected = [self.selectedStaticLayers containsObject:layer.remoteId];
    cell.accessoryType = [self.selectedStaticLayers containsObject:layer.remoteId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
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
    
    [[NSUserDefaults standardUserDefaults] setObject:[self.selectedStaticLayers allObjects] forKey:@"selectedStaticLayers"];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

@end
