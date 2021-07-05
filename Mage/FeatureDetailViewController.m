//
//  FeatureDetailViewController.m
//  MAGE
//
//  Created by William Newman on 1/16/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FeatureDetailViewController.h"

@interface FeatureDetailViewController ()
@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation FeatureDetailViewController

- (instancetype) initWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (self = [super initWithNibName:@"FeatureDetail" bundle:nil]) {
        self.scheme = containerScheme;
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
    
    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.detailTextView.textColor = self.scheme.colorScheme.onBackgroundColor;

    // If scrolling is enabled 'systemLayoutSizeFittingSize' will not calulate the correct height
    self.detailTextView.scrollEnabled = NO;
    
    [self.detailTextView setAttributedText:self.detail];
    
    CGSize size = [self.view systemLayoutSizeFittingSize:CGSizeMake(self.view.frame.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    self.preferredContentSize = CGSizeMake(size.width, size.height + 8); // pad height a little to avoid scroll if view fits
    
    self.detailTextView.scrollEnabled = YES;
}

@end
