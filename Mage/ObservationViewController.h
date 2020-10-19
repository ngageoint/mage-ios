//
//  ObservationViewController.h
//  MAGE
//
//  Created by William Newman on 11/2/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Observation.h"
#import "ObservationActionsTableViewCell.h"
#import "ObservationImportantTableViewCell.h"
#import "AttachmentSelectionDelegate.h"
#import "AttachmentCollectionDataStore.h"

@interface ObservationViewController : UITableViewController<UITableViewDelegate, UITableViewDataSource, ObservationActionsDelegate, ObservationImportantDelegate, AttachmentSelectionDelegate>
@property (strong, nonatomic) NSMutableArray *tableLayout;
@property (weak, nonatomic) IBOutlet UITableView *propertyTable;
@property (strong, nonatomic) IBOutlet AttachmentCollectionDataStore *attachmentCollectionDataStore;

@property (strong, nonatomic) Observation *observation;

- (void) registerCellTypes;

@end
