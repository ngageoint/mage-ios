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
@property (weak, nonatomic) IBOutlet UIView *selectedChoicesView;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray *choices;
@property (strong, nonatomic) NSArray *filteredChoices;
@property (strong, nonatomic) NSMutableArray *selectedChoices;
@property (assign, nonatomic) BOOL multiselect;
@property (strong, nonatomic) NSDictionary *fieldDefinition;
@property (strong, nonatomic) id value;
@property (weak, nonatomic) id<PropertyEditDelegate> delegate;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectedChoicesConstraint;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UILabel *selectedTextLabel;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation SelectEditViewController
static NSString *DROPDOWN_CHOICE_REUSE_ID = @"DROPDOWN_CHOICE_REUSE_ID";

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }

    self.tableView.backgroundColor = containerScheme.colorScheme.backgroundColor;
    self.view.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.selectedChoicesView.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.searchController.searchBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.searchController.searchBar.tintColor = self.scheme.colorScheme.onSecondaryColor;
    self.searchController.searchBar.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.selectedTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.60];
    self.selectedLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.clearButton.tintColor = self.scheme.colorScheme.onSurfaceColor;
    
    self.searchController.searchBar.searchTextField.backgroundColor = self.scheme.colorScheme.surfaceColor;
    
    [self.tableView reloadData];
}

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andValue: value andDelegate:(id<PropertyEditDelegate>) delegate scheme: (id<MDCContainerScheming>) containerScheme  {
    self = [super initWithNibName:@"ObservationEditSelectPickerView" bundle:nil];
    if (self == nil) return nil;
    
    _fieldDefinition = fieldDefinition;
    _delegate = delegate;
    _value = value;
    _scheme = containerScheme;
    self.choices = [NSMutableArray array];
    for (id choice in [self.fieldDefinition objectForKey:@"choices"]) {
        NSString *title = [choice objectForKey:@"title"];
        if (title) {
            [self.choices addObject:title];
        }
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
        
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.accessibilityLabel = @"choices";
    self.tableView.accessibilityIdentifier = @"choices";
    self.tableView.isAccessibilityElement = true;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.selectedLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.selectedLabel.numberOfLines = 0;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;
    self.searchController.searchBar.translucent = YES;

    self.navigationItem.searchController = self.searchController;
    [self applyThemeWithContainerScheme:self.scheme];
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
    
    if (![[self.fieldDefinition objectForKey:@"required"] boolValue]) {
        // Remove the empty select option the server adds for non-required fields
        [self.choices removeObject:@""];
    }
    
    self.filteredChoices = [NSArray arrayWithArray:self.choices];
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    if (self.searchController.active && [self.searchController.searchBar.text length]) {
        return [self.filteredChoices count];
    }
    
    return [self.choices count];
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DROPDOWN_CHOICE_REUSE_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DROPDOWN_CHOICE_REUSE_ID];
    }
    
    NSString *choice = nil;
    if (self.searchController.active && [self.searchController.searchBar.text length]) {
        choice = [self.filteredChoices objectAtIndex:indexPath.row];
    } else {
        choice = [self.choices objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = choice;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.tintColor = self.scheme.colorScheme.primaryColor;
    
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
        
        NSUInteger selectedIndex = 0;
        if (self.searchController.active && [self.searchController.searchBar.text length]) {
            selectedIndex = [self.filteredChoices indexOfObject:selectedChoice];
        } else {
            selectedIndex = [self.choices indexOfObject:selectedChoice];
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
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
    [self notifyDelegate];
}

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchController.searchBar.text];
    self.filteredChoices = [self.choices filteredArrayUsingPredicate:predicate];
    
    [self.tableView reloadData];
}

- (void) notifyDelegate {
    id value = nil;
    if (self.multiselect) {
        value = self.selectedChoices;
    } else {
        if ([self.selectedChoices count]) {
            value = [self.selectedChoices objectAtIndex:0];
        }
    }
    [self.delegate setValue:value forFieldDefinition:self.fieldDefinition];
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
    
    [self.delegate setValue:value forFieldDefinition:self.fieldDefinition];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onCancelTapped:(id) sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onClearTapped:(id) sender {
    NSArray *choices = nil;
    if (self.searchController.active && [self.searchController.searchBar.text length]) {
        choices = self.filteredChoices;
    } else {
        choices = self.choices;
    }

    for (NSString *choice in self.selectedChoices) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[choices indexOfObject:choice] inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [self.selectedChoices removeAllObjects];
    self.selectedLabel.text = @"";
    [self notifyDelegate];
}
@end
