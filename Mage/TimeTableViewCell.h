//
//  TimeTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 5/2/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) NSString *preferenceValue;

@end
