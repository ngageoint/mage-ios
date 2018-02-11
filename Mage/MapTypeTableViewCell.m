//
//  MapTypeTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 1/4/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapTypeTableViewCell.h"

@implementation MapTypeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onMapTypeChanged:(UISegmentedControl *)segmentedControl {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:segmentedControl.selectedSegmentIndex forKey:@"mapType"];
    [defaults synchronize];
}

@end
