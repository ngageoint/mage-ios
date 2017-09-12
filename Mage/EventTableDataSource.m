//
//  EventTableDataSource.m
//  MAGE
//
//

#import "EventTableDataSource.h"
#import <Event.h>
#import <User.h>
#import <Server.h>
#import "EventChooserController.h"
#import "Observation.h"
#import "EventTableViewCell.h"

@interface EventTableDataSource()

@property (strong, nonatomic) NSDictionary *eventIdToOfflineObservationCount;

@end

@implementation EventTableDataSource

- (id) init {
    if (self = [super init]) {

    }
    return self;
}

// This method should not be called until the events have been loaded from the server
- (void) startFetchController {
    
    User *current = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *recentEventIds = [NSArray arrayWithArray:current.recentEventIds];
    
    self.otherFetchedResultsController = [Event MR_fetchAllSortedBy:@"name"
                                                      ascending:YES
                                                  withPredicate:[NSPredicate predicateWithFormat:@"NOT (remoteId IN %@)", recentEventIds]
                                                        groupBy:nil
                                                       delegate:self
                                                      inContext:[NSManagedObjectContext MR_defaultContext]];
    
    self.otherFetchedResultsController.accessibilityLabel = @"Other Events";
    
    self.recentFetchedResultsController = [Event MR_fetchAllSortedBy:@"recentSortOrder"
                                                       ascending:YES
                                                   withPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", recentEventIds]
                                                         groupBy:nil
                                                        delegate:self
                                                       inContext:[NSManagedObjectContext MR_defaultContext]];
    
    self.recentFetchedResultsController.accessibilityLabel = @"My Recent Events";

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
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[Observation MR_entityName]];
    
    NSExpression *eventExpression = [NSExpression expressionForKeyPath:@"eventId"];
    NSExpressionDescription *countExpression = [[NSExpressionDescription alloc] init];
    
    countExpression.name = @"count";
    countExpression.expression = [NSExpression expressionForFunction:@"count:" arguments:@[eventExpression]];
    countExpression.expressionResultType = NSInteger64AttributeType;
    
    request.resultType = NSDictionaryResultType;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    request.propertiesToGroupBy = @[@"eventId"];
    request.propertiesToFetch = @[@"eventId", countExpression];
    request.predicate = [NSPredicate predicateWithFormat:@"error != nil"];
    
    NSArray *groups = [[NSManagedObjectContext MR_defaultContext] executeFetchRequest:request error:nil];
    NSMutableDictionary *offlineCount = [[NSMutableDictionary alloc] init];
    for (NSDictionary *group in groups) {
        [offlineCount setObject:[group objectForKey:@"count"] forKey:[group objectForKey:@"eventId"]];
    }
    self.eventIdToOfflineObservationCount = offlineCount;

    
//    [self.tableView reloadData];
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
    EventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell"];
    Event *event = nil;
    if (indexPath.section == 1) {
        event = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 2) {
        event = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    }
    
    [cell populateCellWithEvent:event offlineObservationCount:[[self.eventIdToOfflineObservationCount objectForKey:event.remoteId] integerValue]];
    
    return cell;
}

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
    Event *event = nil;
    if (indexPath.section == 1) {
        event = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 2) {
        event = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    }

    [Server setCurrentEventId:event.remoteId];
    [self.eventSelectionDelegate didSelectEvent:event];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
