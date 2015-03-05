//
//  EventTableDataSource.m
//  MAGE
//
//  Created by Dan Barela on 3/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventTableDataSource.h"
#import <Event+helper.h>
#import <User+helper.h>
#import <Server+helper.h>

@implementation EventTableDataSource

- (void) startFetchController {
    
    NSFetchRequest *allFetchRequest = [Event MR_requestAllSortedBy:@"name" ascending:YES];
    self.allFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:allFetchRequest
                                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    self.allFetchedResultsController.accessibilityLabel = @"All Events";
    self.allFetchedResultsController.delegate = self;
    
    User *current = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *recentEventIds = current.recentEventIds;
    NSFetchRequest *recentFetchRequest = [Event MR_requestAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", recentEventIds]];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"recentSortOrder" ascending:YES];
    
    [recentFetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    self.recentFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:recentFetchRequest
                                                                           managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                             sectionNameKeyPath:nil
                                                                                      cacheName:nil];
    self.recentFetchedResultsController.accessibilityLabel = @"Recent Events";
    self.recentFetchedResultsController.delegate = self;
    
    NSError *error;
    if (![self.allFetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    if (![self.recentFetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    [self.tableView reloadData];
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.recentFetchedResultsController.fetchedObjects.count;
    } else {
        return self.allFetchedResultsController.fetchedObjects.count;
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return self.recentFetchedResultsController.accessibilityLabel;
    } else {
        return self.allFetchedResultsController.accessibilityLabel;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell"];
    Event *e = nil;
    if (indexPath.section == 0) {
        e = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = e.name;
        cell.detailTextLabel.text = e.eventDescription;
    } else {
        e = [self.allFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = e.name;
        cell.detailTextLabel.text = e.eventDescription;
    }
    if ([e.remoteId isEqualToNumber:[Server currentEventId]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    NSIndexPath *realNewPath = newIndexPath;
    NSIndexPath *realOldPath = indexPath;
    
    if ([controller.accessibilityLabel isEqualToString: self.allFetchedResultsController.accessibilityLabel]) {
        realNewPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:1];
        realOldPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
    }
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:realNewPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:realOldPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:realOldPath] withRowAnimation:NO];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:realOldPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:realNewPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        Event *e = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        [Server setCurrentEventId:e.remoteId];
    } else {
        Event *e = [self.allFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        [Server setCurrentEventId:e.remoteId];
    }
    [tableView beginUpdates];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView endUpdates];
    [tableView reloadData];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 25)];
    [label setFont:[UIFont boldSystemFontOfSize:18]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText: [tableView.dataSource tableView:tableView titleForHeaderInSection:section]];
    [view addSubview:label];
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 29, tableView.frame.size.width, 1)];
    [bottomBorder setBackgroundColor:[UIColor lightGrayColor]];
    [view addSubview:bottomBorder];
    [view setBackgroundColor:[UIColor colorWithRed:65/255.0 green:124/255.0 blue:200/255.0 alpha:1]];
    [view.layer setCornerRadius:3.0f];
    return view;
}

@end
