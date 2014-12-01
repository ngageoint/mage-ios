//
//  OfflineMapTableViewController.m
//  MAGE
//
//  Created by William Newman on 11/11/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OfflineMapTableViewController.h"

@interface OfflineMapTableViewController ()
    @property (nonatomic, strong) NSArray *processingOfflineMaps;
    @property (nonatomic, strong) NSArray *availableOfflineMaps;
    @property (nonatomic, strong) NSMutableSet *selectedOfflineMaps;
@end

@implementation OfflineMapTableViewController

bool originalNavBarHidden;

-(void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.processingOfflineMaps = [defaults valueForKeyPath:@"offlineMaps.processing"];
    self.availableOfflineMaps = [defaults valueForKeyPath:@"offlineMaps.available"];
    self.selectedOfflineMaps = [NSMutableSet setWithArray:[defaults objectForKey:@"selectedOfflineMaps"]];
    
    [defaults addObserver:self
               forKeyPath:@"offlineMaps"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"offlineMaps"];
}

-(void) observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([@"offlineMaps" isEqualToString:keyPath]) {
        self.processingOfflineMaps = [object valueForKeyPath:@"offlineMaps.processing"];
        self.availableOfflineMaps = [object valueForKeyPath:@"offlineMaps.available"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tableView {
    return self.processingOfflineMaps.count > 0 ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.processingOfflineMaps.count > 0 && section == 0) {
        return self.processingOfflineMaps.count;
    } else {
        return self.availableOfflineMaps.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.processingOfflineMaps.count > 0 && section == 0) {
        return @"Extracting Archives";
    } else {
        return @"Offline Maps";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.processingOfflineMaps.count > 0 && [indexPath section] == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"processingOfflineMapCell" forIndexPath:indexPath];
        UILabel *textLabel = (UILabel *)[cell viewWithTag:100];
        textLabel.text = [self.processingOfflineMaps objectAtIndex:[indexPath row]];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"availableOfflineMapCell" forIndexPath:indexPath];
        cell.textLabel.text = [self.availableOfflineMaps objectAtIndex:[indexPath row]];
        
        if ([self.selectedOfflineMaps containsObject:cell.textLabel.text]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.selected = YES;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.accessoryType = [self.selectedOfflineMaps containsObject:cell.textLabel.text] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        return cell;
    }
}
//
//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if ([self.selectedOfflineMaps containsObject:cell.textLabel.text]) {
//        [cell setSelected:YES animated:NO];
//    }
//}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];

    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedOfflineMaps addObject:cell.textLabel.text];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedOfflineMaps removeObject:cell.textLabel.text];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[self.selectedOfflineMaps allObjects] forKey:@"selectedOfflineMaps"];
}

//-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *) indexPath{
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    cell.accessoryType = UITableViewCellAccessoryNone;
//    [self.selectedOfflineMaps removeObject:cell.textLabel.text];
//
//    [[NSUserDefaults standardUserDefaults] setObject:[self.selectedOfflineMaps allObjects] forKey:@"selectedOfflineMaps"];
//}

@end
