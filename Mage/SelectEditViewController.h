//
//  DropdownEditViewController.h
//  MAGE
//
//  Created by William Newman on 6/1/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationEditViewController.h"

@interface SelectEditViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating>
@property (weak, nonatomic) NSDictionary *fieldDefinition;
@property (weak, nonatomic) id value;
@property (weak, nonatomic) id<PropertyEditDelegate> propertyEditDelegate;
@end
