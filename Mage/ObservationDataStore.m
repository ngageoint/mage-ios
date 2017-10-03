//
//  ObservationDataStore.m
//  MAGE
//
//

#import "ObservationDataStore.h"
#import "ObservationTableViewCell.h"
#import "Observation.h"
#import "Observations.h"
#import <NSDate+DateTools.h>
#import "Server.h"
#import "AttachmentSelectionDelegate.h"
#import "Event.h"
#import "GeometryUtility.h"

@interface ObservationDataStore ()
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
    self.event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    /*
     NSArray *forms = event.forms;
     NSDictionary *form = [forms objectAtIndex:0];
     self.variantField = [form objectForKey:@"variantField"];
     */
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
    
    [self.tableView reloadData];
}

- (void) startFetchController {
    self.observations = [Observations observations];
    self.observations.delegate = self;

    NSError *error;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

- (void) updatePredicates {
    [self.observations.fetchedResultsController.fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[Observations getPredicatesForObservations]]];
    NSError *error;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (Observation *) observationAtIndexPath: (NSIndexPath *)indexPath {
    return [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationTableViewCell *observationCell = (ObservationTableViewCell *) cell;
	
	Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
	[observationCell populateCellWithObservation:observation];
    observationCell.observationActionsDelegate = self;
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
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> theSection = [[self.observations.fetchedResultsController sections] objectAtIndex:section];
    return [theSection name];
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
        [self.observationSelectionDelegate observationDetailSelected:observation];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) observationMapTapped:(ObservationTableViewCell *) tableViewCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tableViewCell];
    Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
    [self.observationSelectionDelegate selectedObservation:observation];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (void) observationFavoriteTapped:(ObservationTableViewCell *) tableViewCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tableViewCell];
    Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
    [observation toggleFavoriteWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void) observationShareTapped:(ObservationTableViewCell *) tableViewCell {
//    NSIndexPath *indexPath = [self.tableView indexPathForCell:tableViewCell];
//    Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
//    [observation shareObservationForViewController:self.viewController];
}

- (void)observationDirectionsTapped:(ObservationTableViewCell *) tableViewCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tableViewCell];
    Observation *observation = [self.observations.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSURL *appleMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?ll=%f,%f&q=%@", observation.location.coordinate.latitude, observation.location.coordinate.longitude, [observation primaryFieldText]]];
    NSURL *googleMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/maps/dir/?api=1&destination=%f,%f", observation.location.coordinate.latitude, observation.location.coordinate.longitude]];
    
    NSMutableDictionary *urlMap = [[NSMutableDictionary alloc] init];
    [urlMap setObject:appleMapsUrl forKey:@"Apple Maps"];
    
    if ([[UIApplication sharedApplication] canOpenURL:googleMapsUrl]) {
        [urlMap setObject:googleMapsUrl forKey:@"Google Maps"];
    }
    if ([urlMap count] > 0) {
        [self presentMapsActionSheetForURLs:urlMap];
    } else {
        [[UIApplication sharedApplication] openURL:appleMapsUrl options:@{} completionHandler:^(BOOL success) {
            NSLog(@"opened? %d", success);
        }];
    }
}

- (void) presentMapsActionSheetForURLs: (NSDictionary *) urlMap {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Get Directions With..."
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSString *app in urlMap) {
        [alert addAction:[UIAlertAction actionWithTitle:app style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[urlMap valueForKey:app] options:@{} completionHandler:^(BOOL success) {
                NSLog(@"opened? %d", success);
            }];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.tableView;
        alert.popoverPresentationController.sourceRect = self.tableView.frame;
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    [self.viewController presentViewController:alert animated:YES completion:nil];
}

@end
