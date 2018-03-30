//
//  FormCollectionViewCell.h
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FormCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *formNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *markerView;
@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (strong, nonatomic) NSDictionary *form;

- (void) configureCellForForm: (NSDictionary *) form;

@end
