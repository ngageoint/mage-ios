//
//  ObservationDataStore.h
//  MAGE
//
//  Created by Dan Barela on 9/12/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObservationTableViewCell.h"
#import "Observations.h"
#import "ObservationSelectionDelegate.h"

@interface ObservationDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Observations *observations;
@property (strong, nonatomic) NSDictionary *form;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *variantField;
@property (nonatomic, strong) id<ObservationSelectionDelegate> observationSelectionDelegate;

- (Observation *) observationAtIndexPath: (NSIndexPath *)indexPath;
- (ObservationTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView;
- (void) startFetchController;
- (void) startFetchControllerWithObservations: (Observations *) observations;

@end
