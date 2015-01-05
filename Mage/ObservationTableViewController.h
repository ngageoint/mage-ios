//
//  ObservationsViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationDataStore.h"
#import "ManagedObjectContextHolder.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (readwrite, strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (strong, nonatomic) id<AttachmentSelectionDelegate> attachmentDelegate;

@end
