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
#import "ObservationEditGeometryTableViewCell.h"
#import "GeometryEditViewController.h"
#import <NSManagedObjectContext+MAGE.h>
#import <Observation+helper.h>

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

-(void) cancel:(id)sender {
    //do your saving and such here
    [self.editDataStore discardChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveObservation:(id)sender {
    if ([self.editDataStore saveObservation]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = item;

    // if self.observation is null create a new one
    if (self.observation == nil) {
        self.observation = (Observation *)[NSEntityDescription insertNewObjectForEntityForName:@"Observation" inManagedObjectContext:[NSManagedObjectContext defaultManagedObjectContext]];
        [self.observation initializeNewObservationWithLocation: self.location];
    }
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
    } else if([segue.identifier isEqualToString:@"geometrySegue"]) {
        GeometryEditViewController *gvc = [segue destinationViewController];
        ObservationEditGeometryTableViewCell *cell = sender;
        [gvc setGeoPoint:cell.geoPoint];
        [gvc setFieldDefinition: cell.fieldDefinition];
        [gvc setObservation:self.observation];
    }
}

- (IBAction)unwindFromDropdownController: (UIStoryboardSegue *) segue {
    DropdownEditTableViewController *vc = [segue sourceViewController];
    [self.editDataStore observationField:vc.fieldDefinition valueChangedTo:vc.value reloadCell:YES];
}

- (IBAction)unwindFromGeometryController: (UIStoryboardSegue *) segue {
    GeometryEditViewController *vc = [segue sourceViewController];
    [self.editDataStore observationField:vc.fieldDefinition valueChangedTo:vc.geoPoint reloadCell:YES];
}


@end
