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
#import "Observations.h"
#import <NSDate+DateTools.h>
#import "Server+helper.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationDataStore ()
    @property (weak, nonatomic) IBOutlet UIViewController *viewController;
    @property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
    @property (nonatomic) NSDateFormatter *dateFormatter;
    @property (nonatomic) NSDateFormatter *dateFormatterToDate;
@end

@implementation ObservationDataStore

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

- (id) init {
    NSDictionary *form = [Server observationForm];
    self.variantField = [form objectForKey:@"variantField"];
    return self;
}

- (void) startFetchControllerWithObservations: (Observations *) observations {
    self.observations = observations;
    self.observations.delegate = self;
    
    NSError *error;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

- (void) startFetchController {
    self.observations = [Observations observations];
    self.observations.delegate = self;

    NSError *error;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationTableViewCell *cell = (ObservationTableViewCell *)[self cellForObservationAtIndex:indexPath inTableView:tableView];
    Observation *o = [self observationAtIndexPath:indexPath];
    if (o.attachments.count == 0) {
        return cell.attachmentCollection.frame.origin.y;
    }
    return cell.bounds.size.height;
}

- (Observation *) observationAtIndexPath: (NSIndexPath *)indexPath {
    return [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationTableViewCell *observationCell = (ObservationTableViewCell *) cell;
	
	Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
	[observationCell populateCellWithObservation:observation];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.observations.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[self.observations.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> theSection = [[self.observations.fetchedResultsController sections] objectAtIndex:section];
    NSDate *date = [self.dateFormatterToDate dateFromString:[theSection name]];
    return [self.dateFormatter stringFromDate:date];
}

- (ObservationTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    ObservationTableViewCell *cell = (ObservationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"obsCell"];
    cell.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
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
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
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
        default:
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
    Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.observationSelectionDelegate) {
        [self.observationSelectionDelegate selectedObservation:observation];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.observationSelectionDelegate) {
        [self.observationSelectionDelegate observationDetailSelected:observation];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

@end
