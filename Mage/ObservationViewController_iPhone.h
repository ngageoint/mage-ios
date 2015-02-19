//
//  ObservationViewController_iPhone.h
//  MAGE
//
//  Created by Dan Barela on 2/11/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Observation+helper.h>

@interface ObservationViewController_iPhone : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) Observation *observation;
@property (weak, nonatomic) IBOutlet UITableView *propertyTable;

@end
