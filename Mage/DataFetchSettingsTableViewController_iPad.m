//
//  DataFetchSettingsTableViewController_iPad.m
//  MAGE
//
//  Created by William Newman on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DataFetchSettingsTableViewController_iPad.h"
#import "LocationFetchService.h"
#import "ObservationFetchService.h"

@interface DataFetchSettingsTableViewController_iPad ()

@property (weak, nonatomic) IBOutlet UISwitch *dataFetchSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *observationFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *userFetchPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *observationFetchPicker;

@property (nonatomic, weak) IBOutlet UserFetchDataSource *userFetchDataSource;
@property (nonatomic, weak) IBOutlet ObservationFetchDataSource *observationFetchDataSource;

@property (nonatomic) BOOL isUserFetchSelected;
@property (nonatomic) BOOL isObservationFetchSelected;

@end

@implementation DataFetchSettingsTableViewController_iPad

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


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [self.dataFetchSwitch setOn:[[defaults objectForKey:@"dataFetchEnabled"] boolValue] animated:NO];
    [self.dataFetchSwitch addTarget:self action:@selector(dataFetchSwitched:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setPreferenceDisplayLabel:self.observationFetchFrequencyLabel forPreference:@"observationFetch"];
    [self setPreferenceDisplayLabel:self.userFetchFrequencyLabel forPreference:@"userFetch"];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSInteger observationPickerRow = [[self.observationFetchDataSource values] indexOfObject:[defaults objectForKey:kObservationFetchFrequencyKey]];
    [self.observationFetchPicker selectRow:observationPickerRow inComponent:0 animated:NO];
    
    NSInteger userPickerRow = [[self.userFetchDataSource values] indexOfObject:[defaults objectForKey:kLocationFetchFrequencyKey]];
    [self.userFetchPicker selectRow:userPickerRow inComponent:0 animated:NO];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_dataFetchSwitch.on) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 4;
            break;
        default:
            break;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            self.isUserFetchSelected = !self.isUserFetchSelected;
            [tableView reloadData];
        } else if (indexPath.row == 2) {
            self.isObservationFetchSelected = !self.isObservationFetchSelected;
            [tableView reloadData];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 1 && !self.isUserFetchSelected) {
            return 0.0;
        } else if (indexPath.row == 3 && !self.isObservationFetchSelected) {
            return 0.0;
        }
    }
    
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    return height;
}

-(void) userFetchIntervalSelected:(NSString *) value withLabel:(NSString *) label {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:kLocationFetchFrequencyKey];
    [defaults synchronize];
    
    [self setPreferenceDisplayLabel:self.userFetchFrequencyLabel forPreference:@"userFetch"];
}

-(void) observationFetchIntervalSelected:(NSString *) value withLabel:(NSString *) label {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:kObservationFetchFrequencyKey];
    [defaults synchronize];
    
    [self setPreferenceDisplayLabel:self.observationFetchFrequencyLabel forPreference:@"observationFetch"];
}
@end
