//
//  FormCollectionViewCell.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormCollectionViewCell.h"
#import <HexColor.h>

@implementation FormCollectionViewCell

- (void) configureCellForForm: (NSDictionary *) form {
    self.formNameLabel.text = [form objectForKey:@"name"];
    self.circleView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];

    self.circleView.layer.cornerRadius = self.circleView.frame.size.width / 2;
    self.circleView.layer.borderWidth = 3;
    self.circleView.layer.borderColor = [UIColor colorWithHexString:[form objectForKey:@"color"] alpha:1.0f].CGColor;
    
    self.markerView.tintColor = [UIColor colorWithHexString:[form objectForKey:@"color"] alpha:1.0f];
}

@end
