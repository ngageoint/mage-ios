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

- (id) init {
    if (self = [super init]) {
        NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);
        
        User *current = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        NSArray *recentEventIds = current.recentEventIds;
        NSFetchRequest *recentFetchRequest = [Event MR_requestAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", recentEventIds]];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"recentSortOrder" ascending:YES];
        [recentFetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
        
        self.recentFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:recentFetchRequest
                                                                                  managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                    sectionNameKeyPath:nil
                                                                                             cacheName:nil];
        self.recentFetchedResultsController.accessibilityLabel = @"My Recent Events";
        self.recentFetchedResultsController.delegate = self;
        
        NSFetchRequest *allFetchRequest = [Event MR_requestAllWithPredicate:[NSPredicate predicateWithFormat:@"NOT (remoteId IN %@)", recentEventIds]];
        NSSortDescriptor *allSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [allFetchRequest setSortDescriptors:[NSArray arrayWithObject:allSort]];
        
        self.otherFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:allFetchRequest
                                                                               managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                 sectionNameKeyPath:nil
                                                                                          cacheName:nil];
        self.otherFetchedResultsController.accessibilityLabel = @"Other Events";
        self.otherFetchedResultsController.delegate = self;
        
    }
    return self;
}

// This method should not be called until the events have been loaded from the server
- (void) startFetchController {
    NSError *error;
    if (![self.otherFetchedResultsController performFetch:&error]) {
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
    if (section == 1) {
        return self.recentFetchedResultsController.fetchedObjects.count;
    } else if (section == 2) {
        return self.otherFetchedResultsController.fetchedObjects.count;
    }
    return 0;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.otherFetchedResultsController.fetchedObjects.count == 0 && self.recentFetchedResultsController.fetchedObjects.count == 0) return 0;
    return 3;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [NSString stringWithFormat:@"%@ (%lu)", self.recentFetchedResultsController.accessibilityLabel, (unsigned long)self.recentFetchedResultsController.fetchedObjects.count];
    } else if (section == 2) {
        return [NSString stringWithFormat:@"%@ (%lu)", self.otherFetchedResultsController.accessibilityLabel, (unsigned long)self.otherFetchedResultsController.fetchedObjects.count];
    }
    return nil;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell"];
    Event *e = nil;
    if (indexPath.section == 1) {
        e = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = e.name;
        cell.detailTextLabel.text = e.eventDescription;
    } else if (indexPath.section == 2) {
        e = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = e.name;
        cell.detailTextLabel.text = e.eventDescription;
    }
    if ([Server currentEventId] != nil && [e.remoteId isEqualToNumber:[Server currentEventId]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}
/*
 
 */
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    NSIndexPath *realNewPath = newIndexPath;
    NSIndexPath *realOldPath = indexPath;
    
    if ([controller.accessibilityLabel isEqualToString: self.otherFetchedResultsController.accessibilityLabel]) {
        realNewPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:2];
        realOldPath = [NSIndexPath indexPathForRow:indexPath.row inSection:2];
    } else {
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
    if (indexPath.section == 1) {
        Event *e = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        [Server setCurrentEventId:e.remoteId];
    } else if (indexPath.section == 2){
        Event *e = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
        [Server setCurrentEventId:e.remoteId];
    }
    [tableView beginUpdates];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView endUpdates];
    [tableView reloadData];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 80)];
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, tableView.frame.size.width, 70)];
        if (self.recentFetchedResultsController.fetchedObjects.count == 0 && self.otherFetchedResultsController.fetchedObjects.count > 1) {
            messageLabel.text = @"Welcome to MAGE.  Please choose an event.  The observations you create and your reported location will be part of the selected event.  You can change your event at anytime within MAGE.";
        } else if (self.recentFetchedResultsController.fetchedObjects.count == 0 && self.otherFetchedResultsController.fetchedObjects.count == 1) {
            messageLabel.text = @"Welcome to MAGE.  You are a part of one event.  The observations you create and your reported location will be part of this event.";
        } else if (self.recentFetchedResultsController.fetchedObjects.count == 1) {
            // they are part of one event and have seen this page before.  Should I show it?
            messageLabel.text = @"Welcome to MAGE.  You are a part of one event.  The observations you create and your reported location will be part of this event.";
        } else if (self.recentFetchedResultsController.fetchedObjects.count > 1) {
            messageLabel.text = @"You are part of multiple events.  The observations you create and your reported location will be part of the selected event.  You can change your event at anytime within MAGE.";
        }
        
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:14];
        [view addSubview:messageLabel];
        return view;
    }
    
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CGFLOAT_MIN)];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    UIView *viewForSection = [tableView.delegate tableView:tableView viewForFooterInSection:section];
    return viewForSection.frame.size.height;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    UIView *viewForSection = [tableView.delegate tableView:tableView viewForHeaderInSection:section];
    return viewForSection.frame.size.height;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CGFLOAT_MIN)];
    if (section == 1 && self.recentFetchedResultsController.fetchedObjects.count == 0) return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CGFLOAT_MIN)];
    if (section == 2 && self.otherFetchedResultsController.fetchedObjects.count == 0) return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CGFLOAT_MIN)];
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
    return view;
}

@end
