//
//  MageOfflineObservationController.m
//  MAGE
//
//  Created by William Newman on 5/22/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageOfflineObservationManager.h"
#import "MAGE-Swift.h"

@interface MageOfflineObservationManager()<NSFetchedResultsControllerDelegate>
@property (assign, nonatomic) NSInteger offlineObservationCount;
@property (strong, nonatomic) NSFetchedResultsController *observationFetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation MageOfflineObservationManager

-(instancetype) initWithDelegate:(id<OfflineObservationDelegate>) delegate context: (NSManagedObjectContext *) context {
   	if ((self = [super init])) {
        _offlineObservationCount = -1;
        _delegate = delegate;
        _context = context;
        
        NSFetchRequest *request = [Observation fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"eventId == %@ AND error != nil", [Server currentEventId]];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
        
        _observationFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                  managedObjectContext:context
                                                                                    sectionNameKeyPath:nil
                                                                                             cacheName:nil];
        _observationFetchedResultsController.delegate = self;
    }
    
    return self;
}

+ (NSUInteger) offlineObservationCount {
    NSFetchRequest *request = [Observation fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"error != nil"];
    NSError *error = nil;
    NSUInteger count = [[NSManagedObjectContext defaultContext] countForFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error counting offline observations: %@", error);
        return 0;
    }
    return count;
}

- (void) start {
    NSError *error = nil;
    if (![self.observationFetchedResultsController performFetch:&error]) {
        NSLog(@"Error starting offline observations FRC %@", error);
    }
    
    [self updateOfflineCount:[[self.observationFetchedResultsController fetchedObjects] count]];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"currentEventId" options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void) stop {
    self.delegate = nil;
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"currentEventId"];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id) anObject
       atIndexPath:(NSIndexPath *) indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *) newIndexPath {
    
    [self updateOfflineCount:[[self.observationFetchedResultsController fetchedObjects] count]];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self.observationFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND error != nil", [Server currentEventId]]];
    [self.observationFetchedResultsController performFetch:nil];
    [self updateOfflineCount:[[self.observationFetchedResultsController fetchedObjects] count]];
}

- (void) updateOfflineCount:(NSInteger) count {
    if (count != self.offlineObservationCount) {
        self.offlineObservationCount = count;
        [self.delegate offlineObservationsDidChangeCount:count];
    }
}

@end
