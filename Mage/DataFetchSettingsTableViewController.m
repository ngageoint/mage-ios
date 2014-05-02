//
//  DataFetchSettingsTableViewController.m
//  Mage
//
//  Created by Dan Barela on 5/1/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "DataFetchSettingsTableViewController.h"

@interface DataFetchSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *dataFetchSwitch;

@end

@implementation DataFetchSettingsTableViewController

- (IBAction)dataFetchSwitched:(id)sender {
    if (!_dataFetchSwitch.on) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject: _dataFetchSwitch.isOn ? @"YES" : @"NO" forKey:@"dataFetchEnabled"];
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
    [self.dataFetchSwitch setOn:[[defaults objectForKey:@"dataFetchEnabled"] boolValue] animated:NO];
    [self.dataFetchSwitch addTarget:self action:@selector(dataFetchSwitched:) forControlEvents:UIControlEventValueChanged];
    
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
    if (_dataFetchSwitch.on) {
        return 2;
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
        NSDictionary *timeDictionary = [defaults dictionaryForKey:[segue.identifier substringFromIndex:6]];
        NSDictionary *frequencies = [timeDictionary valueForKey:@"values"];
        vc.displayValues = [frequencies allKeys];
        vc.values = [frequencies allValues];
        vc.preferenceKey = [timeDictionary valueForKey:@"preferenceKey"];
    }
}

@end
