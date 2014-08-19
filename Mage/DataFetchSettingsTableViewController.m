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
@property (weak, nonatomic) IBOutlet UILabel *userFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *observationFetchFrequencyLabel;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setPreferenceDisplayLabel:self.observationFetchFrequencyLabel forPreference:@"observationFetch"];
    [self setPreferenceDisplayLabel:self.userFetchFrequencyLabel forPreference:@"userFetch"];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey
{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    NSDictionary *frequencyDictionary = [defaults dictionaryForKey:prefValuesKey];
    NSArray *labels = [frequencyDictionary valueForKey:@"labels"];
    NSArray *values = [frequencyDictionary valueForKey:@"values"];
    
    NSNumber *frequency = [defaults valueForKey:[frequencyDictionary valueForKey:@"preferenceKey"]];
    
    for (int i = 0; i < values.count; i++) {
        if ([frequency integerValue] == [[values objectAtIndex:i] integerValue]) {
            [label setText:[labels objectAtIndex:i]];
            break;
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
        vc.title = [timeDictionary valueForKey:@"title"];
        vc.section = [timeDictionary valueForKey:@"section"];
        vc.labels = [timeDictionary valueForKey:@"labels"];
        vc.values = [timeDictionary valueForKey:@"values"];
        vc.preferenceKey = [timeDictionary valueForKey:@"preferenceKey"];
    }
}

@end
