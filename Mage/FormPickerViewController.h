//
//  FormPickerViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFGeometry.h"

@protocol FormPickedDelegate <NSObject>

- (void) formPicked: (NSDictionary *) form;
- (void) cancelSelection;

@end

@interface FormPickerViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype) initWithDelegate: (id<FormPickedDelegate>) delegate andForms: (NSArray *) forms;

@end
