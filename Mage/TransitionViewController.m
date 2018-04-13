//
//  TransitionViewController.m
//  MAGE
//
//  Created by Dan Barela on 9/29/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TransitionViewController.h"
#import "Theme+UIResponder.h"

@interface TransitionViewController ()

@property (weak, nonatomic) IBOutlet UILabel *wandLabel;
@property (weak, nonatomic) IBOutlet UILabel *mageLabel;

@end

@implementation TransitionViewController

- (void) themeDidChange:(MageTheme)theme {
//    self.view.backgroundColor = [UIColor background];
//    self.wandLabel.textColor = [UIColor brand];
//    self.mageLabel.textColor = [UIColor brand];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.wandLabel.text = @"\U0000f0d0";
    self.view.backgroundColor = [UIColor background];
    self.wandLabel.textColor = [UIColor brand];
    self.mageLabel.textColor = [UIColor brand];
    [self registerForThemeChanges];
}

@end
