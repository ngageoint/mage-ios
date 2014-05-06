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
@property (weak, nonatomic) IBOutlet UILabel *userReportingFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsSensitivityLabel;

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setPreferenceDisplayLabel:self.userReportingFrequencyLabel forPreference:@"userReporting"];
    [self setPreferenceDisplayLabel:self.gpsSensitivityLabel forPreference:@"gpsSensitivities"];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey
{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    NSDictionary *frequencyDictionary = [defaults dictionaryForKey:prefValuesKey];
    NSDictionary *frequencies = [frequencyDictionary valueForKey:@"values"];
    
    NSNumber *frequency = [defaults valueForKey:[frequencyDictionary valueForKey:@"preferenceKey"]];
    
    for (id key in frequencies) {
        if ([frequency unsignedLongLongValue] == [[frequencies valueForKey: key] unsignedLongLongValue]) {
            [label setText:key];
        }
    }
    
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
