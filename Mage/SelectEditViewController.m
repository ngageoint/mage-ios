//
//  DropdownEditViewController.m
//  MAGE
//
//  Created by William Newman on 6/1/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SelectEditViewController.h"
#import "Theme+UIResponder.h"

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
@property (strong, nonatomic) id<PropertyEditDelegate> delegate;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectedChoicesConstraint;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UILabel *selectedTextLabel;

@end

@implementation SelectEditViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.view.backgroundColor = [UIColor background];
    self.selectedChoicesView.backgroundColor = [[UIColor background] colorWithAlphaComponent:.87];
    self.searchController.searchBar.tintColor = [UIColor navBarPrimaryText];
    self.searchController.searchBar.backgroundColor = [UIColor primary];
    self.searchController.searchBar.searchTextField.backgroundColor = [[UIColor background] colorWithAlphaComponent:.87];
    self.selectedTextLabel.textColor = [UIColor secondaryText];
    self.selectedLabel.textColor = [UIColor primaryText];
    self.clearButton.tintColor = [UIColor flatButton];
    [self.tableView reloadData];
}

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andValue: value andDelegate:(id<PropertyEditDelegate>) delegate {
    self = [super initWithNibName:@"ObservationEditSelectPickerView" bundle:nil];
    if (self == nil) return nil;
    
    _fieldDefinition = fieldDefinition;
    _delegate = delegate;
    _value = value;
    
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
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DropdownChoiceCell" bundle:nil] forCellReuseIdentifier:@"DropdownChoiceCell"];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;

    self.selectedLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.selectedLabel.numberOfLines = 0;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController.hidesNavigationBarDuringPresentation = NO;

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
    } else {
        self.definesPresentationContext = YES;
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.selectedChoicesConstraint.constant = self.navigationController.navigationBar.frame.size.height + 20;
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    
    [self registerForThemeChanges];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DropdownChoiceCell"];
    
    NSString *choice = nil;
    if (self.searchController.active && [self.searchController.searchBar.text length]) {
        choice = [self.filteredChoices objectAtIndex:indexPath.row];
    } else {
        choice = [self.choices objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = choice;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    
    cell.textLabel.textColor = [UIColor primaryText];
    cell.backgroundColor = [UIColor background];
    cell.tintColor = [UIColor flatButton];
    
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
