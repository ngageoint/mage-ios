//
//  DropdownEditViewController.m
//  MAGE
//
//  Created by William Newman on 6/1/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DropdownEditViewController.h"

@interface DropdownEditViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *selectedLabel;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@property (strong, nonatomic) NSMutableArray *choices;
@property (strong, nonatomic) NSMutableArray *selectedChoices;
@property (assign, nonatomic) BOOL multiselect;
@end

@implementation DropdownEditViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    
    self.selectedLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.selectedLabel.numberOfLines = 0;
}

- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    self.multiselect = [@"multiselectdropdown" isEqualToString:[self.fieldDefinition objectForKey:@"type"]];
    
    if (self.value) {
        if (self.multiselect) {
            self.selectedChoices = [NSMutableArray arrayWithArray:self.value];
        } else {
            self.selectedChoices = [NSMutableArray arrayWithObject:self.value];
        }
    } else {
        self.selectedChoices = [NSMutableArray array];
    }
    
    self.selectedLabel.text = [self.selectedChoices componentsJoinedByString:@", "];
    
    self.choices = [NSMutableArray array];
    for (id choice in [self.fieldDefinition objectForKey:@"choices"]) {
        NSString *title = [choice objectForKey:@"title"];
        if (title) {
            [self.choices addObject:title];
        }
    }
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    return [self.choices count];
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"choiceCell"];
    
    NSString *choice = [self.choices objectAtIndex:[indexPath row]];
    cell.textLabel.text = choice;
    
    if ([self.selectedChoices containsObject:choice]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    if (!self.multiselect && [self.selectedChoices count]) {
        NSString *selectedChoice = [self.selectedChoices objectAtIndex:0];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.choices indexOfObject:selectedChoice] inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;

        [self.selectedChoices removeObject:selectedChoice];
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *choice = cell.textLabel.text;
    
    if ([self.selectedChoices containsObject:choice]) {
        [self.selectedChoices removeObject:choice];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [self.selectedChoices addObject:choice];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    self.selectedLabel.text = [self.selectedChoices componentsJoinedByString:@", "];
}

- (IBAction) onSaveTapped:(id) sender {
    id value = nil;
    if (self.multiselect) {
        value = self.selectedChoices;
    } else {
        if ([self.selectedChoices count]) {
            value = [self.selectedChoices objectAtIndex:0];
        }
    }
    
    [self.propertyEditDelegate setValue:value forFieldDefinition:self.fieldDefinition];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onCancelTapped:(id) sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onClearTapped:(id) sender {
    for (NSString *choice in self.selectedChoices) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.choices indexOfObject:choice] inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [self.selectedChoices removeAllObjects];
    self.selectedLabel.text = @"";
}
@end
