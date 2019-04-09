//
//  FormDefaultsTableViewController.h
//  MAGE
//
//  Created by William Newman on 1/30/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FormDefaultsControllerDelegate

- (void) cancel;
- (void) save;
- (void) reset;
- (void) fieldSelected: (NSDictionary *) field;
- (void) fieldEditDone: (NSDictionary *) field value:(id) value reload:(BOOL) reload;

@end

@interface FormDefaultsTableViewController : UITableViewController

@property (weak, nonatomic) id<FormDefaultsControllerDelegate> delegate;
@property (weak, nonatomic) NSDictionary* form;

- (BOOL) validate;

@end

NS_ASSUME_NONNULL_END
