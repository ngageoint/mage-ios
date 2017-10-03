//
//  PeopleDataStore.m
//  MAGE
//
//

#import "LocationDataStore.h"
#import "PersonTableViewCell.h"
#import "Location.h"
#import "Locations.h"
#import "NSDate+DateTools.h"

@interface LocationDataStore ()
    @property (weak, nonatomic) IBOutlet UIViewController *viewController;
    @property (nonatomic) NSDateFormatter *dateFormatter;
    @property (nonatomic) NSDateFormatter *dateFormatterToDate;
@end

@implementation LocationDataStore

- (NSDateFormatter *) dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = kCFDateFormatterLongStyle;
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    
    return _dateFormatter;
    
}

- (NSDateFormatter *) dateFormatterToDate {
    if (_dateFormatterToDate == nil) {
        _dateFormatterToDate = [[NSDateFormatter alloc] init];
        _dateFormatterToDate.dateFormat = @"yyyy-MM-dd";
        _dateFormatterToDate.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    
    return _dateFormatterToDate;
    
}

- (void) startFetchController {
    self.locations = [Locations locationsForAllUsers];
    self.locations.delegate = self;
    
    NSError *error;
    if (![self.locations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

- (void) updatePredicates {
    [self.locations.fetchedResultsController.fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[Locations getPredicatesForLocations]]];
    NSError *error;
    if (![self.locations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

- (Location *) locationAtIndexPath: (NSIndexPath *)indexPath {
    return [self.locations.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[self.locations.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void) configureCell:(UITableViewCell *) cell atIndexPath:(NSIndexPath *)indexPath {
	PersonTableViewCell *personCell = (PersonTableViewCell *) cell;
	
	Location *location = [self.locations.fetchedResultsController objectAtIndexPath:indexPath];
    [personCell populateCellWithUser:location.user];
    personCell.userActionsDelegate = self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    PersonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"personCell"];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PersonTableViewCell *cell = (PersonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"personCell"];
    return cell.frame.size.height;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.locations.fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> theSection = [[self.locations.fetchedResultsController sections] objectAtIndex:section];
    NSDate *date = [self.dateFormatterToDate dateFromString:[theSection name]];
    return [self.dateFormatter stringFromDate:date];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
	
    UITableView *tableView = self.tableView;
	
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
			
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
			
        case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
    }
}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id) sectionInfo atIndex:(NSUInteger) sectionIndex forChangeType:(NSFetchedResultsChangeType) type {
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Location *location = [self.locations.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.personSelectionDelegate) {
        [self.personSelectionDelegate userDetailSelected:location.user];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) userMapTapped:(PersonTableViewCell *) tableViewCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tableViewCell];
    Location *location = [self.locations.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.personSelectionDelegate) {
        [self.personSelectionDelegate selectedUser:location.user];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

@end
