//
//  FormDefaultsTableViewController.m
//  MAGE
//
//  Created by William Newman on 1/30/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormDefaultsTableViewController.h"
#import "ObservationEditTableViewCell.h"
#import "Theme+UIResponder.h"
#import "EventInformationView.h"
#import "FormDefaultsSectionHeader.h"
#import "UIColor+Mage.h"

@interface FormDefaultsTableViewController ()<FormDefaultsSectionHeaderDelegate, ObservationEditListener>
@end

@implementation FormDefaultsTableViewController

- (instancetype) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCellTypes];
    
    [self.tableView setEstimatedRowHeight:126.0f];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    
    [self registerForThemeChanges];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self setupHeader];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) themeDidChange:(MageTheme)theme {
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.tableView.backgroundColor = [UIColor background];
    [self.tableView reloadData];
}

- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationEditCell" bundle:nil] forCellReuseIdentifier:@"ObservationEditCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDateEditCell" bundle:nil] forCellReuseIdentifier:@"date"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationGeometryEditCell" bundle:nil] forCellReuseIdentifier:@"geometry"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationCheckboxEditCell" bundle:nil] forCellReuseIdentifier:@"checkbox"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationEmailEditCell" bundle:nil] forCellReuseIdentifier:@"email"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationNumberEditCell" bundle:nil] forCellReuseIdentifier:@"numberfield"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationTextAreaEditCell" bundle:nil] forCellReuseIdentifier:@"textarea"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDropdownEditCell" bundle:nil] forCellReuseIdentifier:@"dropdown"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationPasswordEditCell" bundle:nil] forCellReuseIdentifier:@"password"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationTextfieldEditCell" bundle:nil] forCellReuseIdentifier:@"textfield"];
}

- (void) setupHeader {
    EventInformationView *header = [[NSBundle mainBundle] loadNibNamed:@"EventInformationView" owner:self options:nil][0];
    header.nameLabel.text = [self.form objectForKey:@"name"];
    
    NSString *description = [self.form valueForKey:@"description"];
    header.descriptionLabel.hidden = [description length] == 0 ? YES : NO;
    header.descriptionLabel.text = description;
    
    [header setNeedsLayout];
    [header layoutIfNeeded];
    
    CGSize size = [header systemLayoutSizeFittingSize:CGSizeMake(header.frame.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    
    CGRect frame = [header frame];
    frame.size.height = size.height;
    [header setFrame:frame];
    
    header.backgroundColor = [UIColor background];
    self.tableView.tableHeaderView = header;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *fields = [self.form objectForKey:@"fields"];
    return [fields count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    FormDefaultsSectionHeader *header = [[NSBundle mainBundle] loadNibNamed:@"FormDefaultsFormHeader" owner:self options:nil][0];
    header.delegate = self;
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *field = [self fieldAtIndexPath:indexPath];
    
    NSString *cellType = [self getCellTypeForField:field];
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    cell.fieldDefinition = field;
    
    if ([cell respondsToSelector:@selector(setDelegate:)]) {
        [cell setDelegate:self];
    }
    
    if ([cell respondsToSelector:@selector(populateCellWithFormField:andValue:)]) {
        [cell populateCellWithFormField:field andValue:[field valueForKey:@"value"]];
    }
    
    return cell;
}

- (NSString *) getCellTypeForField:(NSDictionary *) field {
    NSString *type = [field objectForKey:@"type"];
    if ([type isEqualToString:@"radio"] || [type isEqualToString:@"multiselectdropdown"]) {
        type = @"dropdown";
    }
    
    return type;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell selectRow];
    NSDictionary *field = [self fieldAtIndexPath:indexPath];
    [self.delegate fieldSelected:field];
}

- (NSDictionary *) fieldAtIndexPath:(NSIndexPath *) indexPath {
    NSArray *fields = [self.form objectForKey:@"fields"];
    return [fields objectAtIndex:indexPath.row];
}

- (void)onResetDefaultsTapped {
    [self.delegate reset];
}

- (void)observationField:(id)field valueChangedTo:(id)value reloadCell:(BOOL)reload {
    [self.delegate fieldEditDone:field value:value reload:reload];
}

- (void) keyboardWillShow: (NSNotification *) notification {
    [self setNavBarButtonsEnabled:NO];
}

- (void) keyboardWillHide: (NSNotification *) notification {
    [self setNavBarButtonsEnabled:YES];
}

- (void) setNavBarButtonsEnabled:(BOOL) enabled {
    if (self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem.enabled = enabled;
    }
    
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = enabled;
    }
}

@end
