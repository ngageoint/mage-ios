//
//  LocationFetchedResultsController.h
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface LocationFetchedResultsController : NSFetchedResultsController

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context;

@end
