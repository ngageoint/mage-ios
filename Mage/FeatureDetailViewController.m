//
//  FeatureDetailViewController.m
//  MAGE
//
//  Created by William Newman on 1/16/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FeatureDetailViewController.h"
#import "UIColor+Mage.h"

@interface FeatureDetailViewController ()
@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@end

@implementation FeatureDetailViewController

- (instancetype) init {
    if (self = [super initWithNibName:@"FeatureDetail" bundle:nil]) {
    }
    
    return self;
}

- (IBAction)onOkTapped:(id)sender {
    if (self.delegate) {
        [self.delegate onDismiss];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor background];
    self.detailTextView.textColor = [UIColor secondaryText];

    // If scrolling is enabled 'systemLayoutSizeFittingSize' will not calulate the correct height
    self.detailTextView.scrollEnabled = NO;

    [self.detailTextView setText:self.detail];
    
    CGSize size = [self.view systemLayoutSizeFittingSize:CGSizeMake(self.view.frame.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    self.preferredContentSize = CGSizeMake(size.width, size.height + 8); // pad height a little to avoid scroll if view fits
    
    self.detailTextView.scrollEnabled = YES;
}

@end
