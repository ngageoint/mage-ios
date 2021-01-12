//
//  TransitionViewController.m
//  MAGE
//
//  Created by Dan Barela on 9/29/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TransitionViewController.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface TransitionViewController ()

@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation TransitionViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.view.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.mageLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
    self.wandLabel.textColor = self.scheme.colorScheme.primaryColorVariant;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.wandLabel.text = @"\U0000f0d0";
}

@end
