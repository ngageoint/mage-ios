//
//  FormPickerViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormPickerViewController.h"
#import "Theme+UIResponder.h"
#import <HexColor.h>

@interface FormPickerViewController ()

@property (strong, nonatomic) id<FormPickedDelegate> delegate;
@property (strong, nonatomic) NSArray *forms;

@end

@implementation FormPickerViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

- (instancetype) initWithDelegate: (id<FormPickedDelegate>) delegate andForms: (NSArray *) forms {
    self = [super init];
    if (!self) return nil;
    
    _delegate = delegate;
    _forms = forms;
    
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForThemeChanges];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add A Form";
    self.navigationItem.title = @"Add A Form";
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (IBAction)closeButtonTapped:(id)sender {
    [self.delegate cancelSelection];
}


#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.forms count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_delegate formPicked: [self.forms objectAtIndex:[indexPath row]]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *form = [self.forms objectAtIndex:[indexPath row]];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    cell.textLabel.text = [form objectForKey:@"name"];
    cell.detailTextLabel.text = [form objectForKey:@"description"];
    cell.imageView.image = [UIImage imageNamed:@"form"];
    cell.imageView.tintColor = [UIColor colorWithHexString:[form objectForKey:@"color"]];
    NSLog(@"%@", form);
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.backgroundColor = [UIColor background];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

@end
