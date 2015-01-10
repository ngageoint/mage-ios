//
//  ObservationFetchedResultsController.h
//  MAGE
//
//  Created by William Newman on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "User+helper.h"
#import "Observation.h"

@interface Observations : NSObject

@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, assign) id< NSFetchedResultsControllerDelegate > delegate;

+ (id) observations;
+ (id) observationsForUser:(User *) user;
+ (id) observationsForObservation:(Observation *) observation;

- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
