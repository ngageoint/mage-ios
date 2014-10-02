//
//  ObservationEditViewController.m
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditViewController.h"
#import "ObservationEditViewDataStore.h"
#import "DropdownEditTableViewController.h"
#import "ObservationPickerTableViewCell.h"

@interface ObservationEditViewController ()

@property (nonatomic, strong) IBOutlet ObservationEditViewDataStore *editDataStore;

@end

@implementation ObservationEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) init {
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editDataStore.observation = self.observation;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"dropdownSegue"]) {
        DropdownEditTableViewController *vc = [segue destinationViewController];
        ObservationPickerTableViewCell *cell = sender;
        
        [vc setFieldDefinition:cell.fieldDefinition];
        [vc setValue:cell.valueLabel.text];
    }
}

- (IBAction)unwindFromDropdownController: (UIStoryboardSegue *) segue {
    DropdownEditTableViewController *vc = [segue sourceViewController];
    NSString *fieldKey = (NSString *)[vc.fieldDefinition objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:_observation.properties];
    [newProperties setObject:vc.value forKey:fieldKey];
    _observation.properties = newProperties;
    
    [self.editDataStore.editTable reloadData];
    NSLog(@"choose %@", vc.value);
    
}


@end
