//
//  DropdownEditTableViewController.m
//  Mage
//
//  Created by Dan Barela on 8/21/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DropdownEditTableViewController.h"
#import "ValueTableViewCell.h"

@interface DropdownEditTableViewController ()

@end

@implementation DropdownEditTableViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *choices = [self.fieldDefinition objectForKey:@"choices"];
    return choices.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"valueTableCell" forIndexPath:indexPath];
    NSArray *choices = [self.fieldDefinition objectForKey:@"choices"];
    cell.valueLabel.text = [choices[indexPath.row] objectForKey:@"title"];
    if ([cell.valueLabel.text isEqualToString:_value]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *choices = [self.fieldDefinition objectForKey:@"choices"];
    long row = [indexPath row];
    _value = [choices[indexPath.row] objectForKey:@"title"];
    [self performSegueWithIdentifier:@"unwindToEditController" sender:self];
    
}

@end
