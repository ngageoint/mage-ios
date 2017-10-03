//
//  DropdownEditViewController.h
//  MAGE
//
//  Created by William Newman on 6/1/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationEditTableViewController.h"

@interface SelectEditViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating>

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andValue: value andDelegate: (id<PropertyEditDelegate>) delegate;

@end
