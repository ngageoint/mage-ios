//
//  FilterTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 7/20/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FilterTableViewController.h"
#import "MageFilter.h"
#import "ObservationFilterTableViewController.h"
#import "LocationFilterTableViewController.h"
#import <MaterialComponents/MDCContainerScheme.h>

@interface FilterTableViewController ()
@property (assign, nonatomic) BOOL isPopover;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation FilterTableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.navigationController.navigationBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.navigationController.navigationBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
    self.navigationController.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self setPreferredContentSize:CGSizeMake(340.0f, 550.0f)];
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    NSString *filterString = @"";
    if ([indexPath row] == 0) {
        filterString = [MageFilter getFilterString];
        if ([filterString length] == 0) {
            filterString = @"All";
        }
    } else if ([indexPath row] == 1) {
        filterString = [MageFilter getLocationFilterString];
        if ([filterString length] == 0) {
            filterString = @"All";
        }
    }
    
    cell.detailTextLabel.text = filterString;
    
    if (self.scheme) {
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    }
    
    return cell;
}

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass: ObservationFilterTableViewController.class]) {
        ObservationFilterTableViewController *ofvc = (ObservationFilterTableViewController *)segue.destinationViewController;
        [ofvc applyThemeWithContainerScheme:self.scheme];
    }
    
    if ([segue.destinationViewController isKindOfClass: LocationFilterTableViewController.class]) {
        LocationFilterTableViewController *ofvc = (LocationFilterTableViewController *)segue.destinationViewController;
        [ofvc applyThemeWithContainerScheme:self.scheme];
    }
}

@end
