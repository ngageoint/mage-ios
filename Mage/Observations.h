//
//  ObservationFetchedResultsController.h
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Observations : NSObject

@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, assign) id< NSFetchedResultsControllerDelegate > delegate;

+ (id) observationsInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
