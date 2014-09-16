//
//  PeopleDataStore.h
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Location.h"
#import "PersonTableViewCell.h"
#import "LocationFetchedResultsController.h"

@interface PeopleDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) LocationFetchedResultsController *locationResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (Location *) locationAtIndexPath: (NSIndexPath *)indexPath;
- (void) startFetchControllerWithManagedObjectContext: (NSManagedObjectContext *) managedObjectContext;

@end
