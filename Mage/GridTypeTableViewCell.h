//
//  GridTypeTableViewCell.h
//  MAGE
//
//  Created by Brian Osborn on 9/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GridTypeDelegate

-(void) gridTypeChanged:(GridType) gridType;

@end

@interface GridTypeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISegmentedControl *gridTypeSegmentedControl;
@property (weak, nonatomic) id<GridTypeDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;

@end
