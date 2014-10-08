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
#import "Locations.h"
#import "UserSelectionDelegate.h"

@interface PeopleDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Locations *locations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<UserSelectionDelegate> personSelectionDelegate;

- (Location *) locationAtIndexPath: (NSIndexPath *)indexPath;
- (void) startFetchControllerWithManagedObjectContext: (NSManagedObjectContext *) managedObjectContext;

@end
