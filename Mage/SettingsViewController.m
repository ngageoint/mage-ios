//
//  SettingsViewController.m
//  Mage
//
//  Created by Dan Barela on 2/21/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *locationServicesStatus;
@property (weak, nonatomic) IBOutlet UILabel *dataFetchStatus;

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"locationServiceEnabled"] boolValue]) {
        [self.locationServicesStatus setText:@"On"];
    } else {
        [self.locationServicesStatus setText:@"Off"];
    }
    
    if ([[defaults objectForKey:@"dataFetchEnabled"] boolValue]) {
        [self.dataFetchStatus setText:@"On"];
    } else {
        [self.dataFetchStatus setText:@"Off"];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"timeSettingSegue"]) {
        UIViewController *nav = [segue destinationViewController];
//        FirmyVC *firmyVC = (FirmyVC *)nav.topViewController;
//        firmyVC.tabFirmy = self.tabFirmy;
    }
}

@end
