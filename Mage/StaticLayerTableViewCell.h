//
//  StaticLayerTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 1/22/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StaticLayerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *layerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *featureCountLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end
