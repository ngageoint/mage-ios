//
//  UserDataStore.m
//  MAGE
//
//  Created by William Newman on 11/14/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UserDataStore.h"
#import "User.h"
#import "PersonTableViewCell.h"

@interface UserDataStore ()
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSDateFormatter *dateFormatterToDate;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation UserDataStore

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

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>) containerScheme {
    if (containerScheme) {
        self.scheme = containerScheme;
    }
    
}

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super init];
    self.scheme = containerScheme;
    return self;
}

- (void) startFetchControllerForUserIds:(NSArray *) userIds {
    self.fetchedResultsController = [User MR_fetchAllSortedBy:@"name"
                                                        ascending:NO
                                                    withPredicate:[NSPredicate predicateWithFormat:@"remoteId IN %@ ", userIds]
                                                          groupBy:nil
                                                         delegate:nil
                                                        inContext:[NSManagedObjectContext MR_defaultContext]];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void) configureCell:(UITableViewCell *) cell atIndexPath:(NSIndexPath *)indexPath {
    PersonTableViewCell *personCell = (PersonTableViewCell *) cell;
    personCell.name.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    personCell.timestamp.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    personCell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    personCell.icon.tintColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [personCell populateCellWithUser:user];
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
    return [[self.fetchedResultsController sections] count];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.userSelectionDelegate != nil) {
        [self.userSelectionDelegate userDetailSelected:user];
    }
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

@end
