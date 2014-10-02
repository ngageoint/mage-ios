//
//  ObservationDataStore.m
//  MAGE
//
//  Created by Dan Barela on 9/12/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationDataStore.h"
#import "ObservationTableViewCell.h"
#import "Observation+helper.h"
#import "ObservationFetchedResultsController.h"
#import <NSDate+DateTools.h>

@interface ObservationDataStore ()
    @property (strong, nonatomic) IBOutlet UIViewController *viewController;
@end

@implementation ObservationDataStore

- (id) init {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    self.variantField = [form objectForKey:@"variantField"];
    return self;
}

- (void) startFetchControllerWithManagedObjectContext: (NSManagedObjectContext *) managedObjectContext {
    self.managedObjectContext = managedObjectContext;
    NSError *error;
    if (![[self observationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
    
    return cell.bounds.size.height;
}

- (NSFetchedResultsController *) observationResultsController {
    
    if (_observationResultsController != nil) {
        return _observationResultsController;
    }
    _observationResultsController = [[ObservationFetchedResultsController alloc] initWithManagedObjectContext:_managedObjectContext];
    [_observationResultsController setDelegate:self];
    return _observationResultsController;
}

- (Observation *) observationAtIndexPath: (NSIndexPath *)indexPath {
    return [_observationResultsController objectAtIndexPath:indexPath];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationTableViewCell *observationCell = (ObservationTableViewCell *) cell;
	
	Observation *observation = [_observationResultsController objectAtIndexPath:indexPath];
	[observationCell populateCellWithObservation:observation];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [[_observationResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[_observationResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> theSection = [[_observationResultsController sections] objectAtIndex:section];
    return [theSection name];
}

- (ObservationTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    Observation *observation = [_observationResultsController objectAtIndexPath:indexPath];
    NSString *CellIdentifier = @"observationCell";
    if (self.variantField != nil && [[observation.properties objectForKey:self.variantField] length] != 0) {
        CellIdentifier = @"observationVariantCell";
    }
	
    ObservationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return cell;
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Observation *observation = [_observationResultsController objectAtIndexPath:indexPath];
    if (self.observationSelectionDelegate) {
        [self.observationSelectionDelegate selectedObservation:observation];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

@end
