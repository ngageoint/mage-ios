//
//  PeopleDataStore.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "PeopleDataStore.h"
#import "PersonTableViewCell.h"
#import "Location+helper.h"
#import "LocationFetchedResultsController.h"

@interface PeopleDataStore ()
    @property (strong, nonatomic) IBOutlet UIViewController *viewController;
@end

@implementation PeopleDataStore

- (void) startFetchControllerWithManagedObjectContext: (NSManagedObjectContext *) managedObjectContext {
    self.managedObjectContext = managedObjectContext;
    NSError *error;
    if (![[self locationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    NSArray *results = [self.locationResultsController fetchedObjects];
    NSLog(@"found %lu users", (unsigned long)results.count);
}

- (NSFetchedResultsController *) locationResultsController {
    
    if (_locationResultsController != nil) {
        return _locationResultsController;
    }
    _locationResultsController = [[LocationFetchedResultsController alloc] initWithManagedObjectContext:_managedObjectContext];
    [_locationResultsController setDelegate:self];
    return _locationResultsController;
}

- (Location *) locationAtIndexPath: (NSIndexPath *)indexPath {
    return [_locationResultsController objectAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[_locationResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void) configureCell:(UITableViewCell *) cell atIndexPath:(NSIndexPath *)indexPath {
	PersonTableViewCell *personCell = (PersonTableViewCell *) cell;
	
	Location *location = [_locationResultsController objectAtIndexPath:indexPath];
	[personCell populateCellWithUser:location.user];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    PersonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"personCell"];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [[_locationResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> theSection = [[_locationResultsController sections] objectAtIndex:section];
    return [theSection name];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
	
    UITableView *tableView = self.tableView;
	
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
			
        case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Location *location = [_locationResultsController objectAtIndexPath:indexPath];
    if (self.personSelectionDelegate) {
        [self.personSelectionDelegate selectedUser:location.user];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

@end
