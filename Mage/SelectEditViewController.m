//
//  DropdownEditViewController.m
//  MAGE
//
//  Created by William Newman on 6/1/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SelectEditViewController.h"

@interface SelectEditViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *selectedLabel;
@property (weak, nonatomic) IBOutlet UIView *searchBarContainer;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray *choices;
@property (strong, nonatomic) NSArray *filteredChoices;
@property (strong, nonatomic) NSMutableArray *selectedChoices;
@property (assign, nonatomic) BOOL multiselect;
@end

@implementation SelectEditViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    
    self.selectedLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.selectedLabel.numberOfLines = 0;
    
    self.definesPresentationContext = YES;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.searchBarContainer addSubview:self.searchController.searchBar];
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
    
    if (![[self.fieldDefinition objectForKey:@"required"] boolValue]) {
        // Remove the empty select option the server adds for non-required fields
        [self.choices removeObject:@""];
    }
    
    self.filteredChoices = [NSArray arrayWithArray:self.choices];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.searchController.searchBar sizeToFit];
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    if (self.searchController.active && [self.searchController.searchBar.text length]) {
        return [self.filteredChoices count];
    }
    
    return [self.choices count];
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"choiceCell"];
    
    NSString *choice = nil;
    if (self.searchController.active && [self.searchController.searchBar.text length]) {
        choice = [self.filteredChoices objectAtIndex:indexPath.row];
    } else {
        choice = [self.choices objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = choice;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    
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

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchController.searchBar.text];
    self.filteredChoices = [self.choices filteredArrayUsingPredicate:predicate];
    
    [self.tableView reloadData];
}

- (IBAction) onApplyTapped:(id) sender {
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
