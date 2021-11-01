//
//  EventTableDataSource.m
//  MAGE
//
//

#import "EventTableDataSource.h"
#import "Server.h"
#import "EventChooserController.h"
#import "Observation.h"
#import "EventTableViewCell.h"
#import "EventTableHeaderView.h"

@interface EventTableDataSource()
@property (strong, nonatomic) NSDictionary *eventIdToOfflineObservationCount;
@property (strong, nonatomic) NSString *currentFilter;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation EventTableDataSource

- (id) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [self init];
    self.scheme = containerScheme;
    return self;
}

- (void) updateOtherFetchedResultsControllerWithRecentEvents: (NSArray *) recentEventIds {
    if (!self.otherFetchedResultsController) {
        self.otherFetchedResultsController = [Event caseInsensitiveSortFetchAllWithSortTerm:@"name" ascending:true predicate:[NSPredicate predicateWithFormat:@"NOT (remoteId IN %@)", recentEventIds] groupBy:nil context:[NSManagedObjectContext MR_defaultContext]];
        self.otherFetchedResultsController.accessibilityLabel = @"Other Events";
    }
    NSError *error;
    if (![self.otherFetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void) updateRecentFetchedResultsControllerWithRecentEvents: (NSArray *) recentEventIds {
    NSFetchRequest *recentRequest = [Event MR_requestAllInContext:[NSManagedObjectContext MR_defaultContext]];
    [recentRequest setPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", recentEventIds]];
    [recentRequest setIncludesSubentities:NO];
    NSSortDescriptor* sortBy = [NSSortDescriptor sortDescriptorWithKey:@"recentSortOrder" ascending:YES];
    [recentRequest setSortDescriptors:[NSArray arrayWithObject:sortBy]];
    if (!self.recentFetchedResultsController) {
        self.recentFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:recentRequest
                                                                                  managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                    sectionNameKeyPath:nil
                                                                                             cacheName:nil];
        self.recentFetchedResultsController.accessibilityLabel = @"My Recent Events";
    }
    
    NSError *error;
    
    if (![self.recentFetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void) refreshEventData {
    User *current = [User fetchCurrentUserWithContext:[NSManagedObjectContext MR_defaultContext]];
    NSArray *recentEventIds = [NSArray arrayWithArray:current.recentEventIds];
    [self updateOtherFetchedResultsControllerWithRecentEvents:recentEventIds];
    [self updateRecentFetchedResultsControllerWithRecentEvents:recentEventIds];
}

- (void) startFetchController {
    [self refreshEventData];
    
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
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"Section %ld", (long)section);
    if (self.filteredFetchedResultsController) {
        return self.filteredFetchedResultsController.fetchedObjects.count;
    }
    if (section == 1) {
        return self.recentFetchedResultsController.fetchedObjects.count;
    } else if (section == 2) {
        return self.otherFetchedResultsController.fetchedObjects.count;// self.otherFetchedResultsController.fetchedObjects.count;
    }
    return 0;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.filteredFetchedResultsController != nil) return 1;
    if (self.otherFetchedResultsController.fetchedObjects.count == 0 && self.recentFetchedResultsController.fetchedObjects.count == 0) return 0;
    return 3;
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

#pragma

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.filteredFetchedResultsController) {
        return [NSString stringWithFormat:@"%@ (%lu)", self.filteredFetchedResultsController.accessibilityLabel, (unsigned long)self.filteredFetchedResultsController.fetchedObjects.count];
    }
    if (section == 1) {
        return [NSString stringWithFormat:@"%@ (%lu)", self.recentFetchedResultsController.accessibilityLabel, (unsigned long)self.recentFetchedResultsController.fetchedObjects.count];
    } else if (section == 2) {
        return [NSString stringWithFormat:@"%@ (%lu)", @"Other Events", (unsigned long)self.otherFetchedResultsController.fetchedObjects.count];
    }
    return nil;
}

- (void) setEventFilter: (NSString *) filter withDelegate:(id<NSFetchedResultsControllerDelegate>) delegate {
    if (!filter) {
        self.filteredFetchedResultsController.delegate = nil;
        self.filteredFetchedResultsController = nil;
        return;
    }
    if (!self.filteredFetchedResultsController) {
        self.filteredFetchedResultsController = [Event caseInsensitiveSortFetchAllWithSortTerm:@"name" ascending:true predicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", filter] groupBy:nil context:[NSManagedObjectContext MR_defaultContext]];
        self.filteredFetchedResultsController.delegate = delegate;
    
        self.filteredFetchedResultsController.accessibilityLabel = @"Filtered";
    } else {
        [self.filteredFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", filter]];
    }
    NSError *error;
    if (![self.filteredFetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell"];
    cell.eventName.textColor = self.scheme.colorScheme.onSurfaceColor;
    cell.eventDescription.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.60];
    Event *event = nil;
    
    if (self.filteredFetchedResultsController != nil) {
        event = [self.filteredFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        event = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 2) {
        event = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    }
    
    [cell populateCellWithEvent:event offlineObservationCount:[[self.eventIdToOfflineObservationCount objectForKey:event.remoteId] integerValue]];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = nil;
    if (self.filteredFetchedResultsController != nil) {
        event = [self.filteredFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        event = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 2) {
        event = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    }
    if (event.eventDescription && ![event.eventDescription isEqualToString:@""]) {
        return 72.0f;
    }
    return 48.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = nil;
    if (self.filteredFetchedResultsController != nil) {
        event = [self.filteredFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        event = [self.recentFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    } else if (indexPath.section == 2) {
        event = [self.otherFetchedResultsController.fetchedObjects objectAtIndex:indexPath.row];
    }

    [Server setCurrentEventId:event.remoteId];
    [self.eventSelectionDelegate didSelectEvent:event];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0 && self.filteredFetchedResultsController != nil && [self.filteredFetchedResultsController.fetchedObjects count] != 0) {
            return 40.0f;
    }
    return CGFLOAT_MIN;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.filteredFetchedResultsController != nil) {
        return 48.0f;
    }
    
    if (section == 0) return CGFLOAT_MIN;
    
    if (section == 1 && self.recentFetchedResultsController.fetchedObjects.count == 0) return CGFLOAT_MIN;
    
    if (section == 2 && self.otherFetchedResultsController.fetchedObjects.count == 0) return CGFLOAT_MIN;
   
    return 48.0f;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.filteredFetchedResultsController != nil && [self.filteredFetchedResultsController.fetchedObjects count] != 0) {
        return @"End of Results";
    }
    return nil;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.filteredFetchedResultsController != nil) {
        NSString *name = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
        return [[EventTableHeaderView alloc] initWithName:name containerScheme:self.scheme];
    }
        
    if (section == 0) return [[UIView alloc] initWithFrame:CGRectZero];
    if (section == 1 && self.recentFetchedResultsController.fetchedObjects.count == 0) return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CGFLOAT_MIN)];
    if (section == 2 && self.otherFetchedResultsController.fetchedObjects.count == 0) return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, CGFLOAT_MIN)];
    
    NSString *name = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    return [[EventTableHeaderView alloc] initWithName:name containerScheme:self.scheme];
}

@end
