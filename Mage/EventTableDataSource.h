//
//  EventTableDataSource.h
//  MAGE
//
//  Created by Dan Barela on 3/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface EventTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, strong)  NSFetchedResultsController *otherFetchedResultsController;
@property(nonatomic, strong)  NSFetchedResultsController *recentFetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void) startFetchController;

@end
