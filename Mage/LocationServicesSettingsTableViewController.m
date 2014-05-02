//
//  LocationServicesSettingsTableViewController.m
//  Mage
//
//  Created by Dan Barela on 4/30/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "LocationServicesSettingsTableViewController.h"

@interface LocationServicesSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *locationServicesSwitch;

@end

@implementation LocationServicesSettingsTableViewController

- (IBAction)locationServicesSwitched:(id)sender {
    if (!_locationServicesSwitch.on) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject: _locationServicesSwitch.isOn ? @"YES" : @"NO" forKey:@"locationServiceEnabled"];
    [defaults synchronize];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [self.locationServicesSwitch setOn:[[defaults objectForKey:@"locationServiceEnabled"] boolValue] animated:NO];
    [self.locationServicesSwitch addTarget:self action:@selector(locationServicesSwitched:) forControlEvents:UIControlEventValueChanged];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_locationServicesSwitch.on) {
        return 3;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 2;
            break;
        default:
            break;
    }
    return 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([segue.identifier hasPrefix:@"value_"]) {
        ValuePickerTableViewController *vc = [segue destinationViewController];
        NSDictionary *valueDictionary = [defaults dictionaryForKey:[segue.identifier substringFromIndex:6]];
        NSDictionary *frequencies = [valueDictionary valueForKey:@"values"];
        vc.displayValues = [frequencies allKeys];
        vc.values = [frequencies allValues];
        vc.preferenceKey = [valueDictionary valueForKey:@"preferenceKey"];
    }
}

@end
