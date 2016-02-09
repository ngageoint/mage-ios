//
//  AttributionTableViewCell.h
//  MAGE
//
//  Created by William Newman on 2/8/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AttributionTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *attribution;
@property (weak, nonatomic) IBOutlet UILabel *copyright;
@property (weak, nonatomic) IBOutlet UITextView *text;
@end
