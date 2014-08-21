//
//  DropdownEditTableViewController.h
//  Mage
//
//  Created by Dan Barela on 8/21/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropdownEditTableViewController : UITableViewController

@property (strong, nonatomic) id fieldDefinition;
@property (strong, nonatomic) NSString *value;

@end
