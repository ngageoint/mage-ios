//
//  TransitionViewController.m
//  MAGE
//
//  Created by Dan Barela on 9/29/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TransitionViewController.h"
#import "UIColor+UIColor_Mage.h"

@interface TransitionViewController ()

@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;

@end

@implementation TransitionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mageLabel.textColor = [UIColor primaryColor];
    self.wandLabel.textColor = [UIColor primaryColor];
    self.wandLabel.text = @"\U0000f0d0";
    
    self.view.backgroundColor = [UIColor whiteColor];
}

@end
