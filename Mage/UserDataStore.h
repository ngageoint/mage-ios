//
//  UserDataStore.h
//  MAGE
//
//  Created by William Newman on 11/14/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserSelectionDelegate.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface UserDataStore : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<UserSelectionDelegate> userSelectionDelegate;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;
- (void) startFetchControllerForUserIds:(NSArray *) userIds;

@end
