//
//  TimePickerTableViewController.h
//  Mage
//
//  Created by Dan Barela on 5/2/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimePickerTableViewController : UITableViewController <UITableViewDelegate>

@property (nonatomic, strong) NSArray *times;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic) NSNumber *selected;
@property (nonatomic, strong) NSString *preferenceKey;

@end
