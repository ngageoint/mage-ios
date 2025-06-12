//
//  EventInformationController.m
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventInformationController.h"
#import "EventInformationView.h"
#import <HexColors.h>

@interface EventInformationController ()
@property (strong, nonatomic) NSArray<Form *>* forms;
@property (strong, nonatomic) id<AppContainerScheming> scheme;
@end

@implementation EventInformationController

static const NSInteger FORMS_SECTION = 0;

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.scheme = containerScheme;
    return self;
}

- (void) applyThemeWithContainerScheme: (id<AppContainerScheming>) containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.title = @"Event Information";
        
    EventInformationView *header = [[NSBundle mainBundle] loadNibNamed:@"EventInformationView" owner:self options:nil][0];
    [header applyThemeWithContainerScheme:self.scheme];
    header.nameLabel.text = self.event.name;
    header.descriptionLabel.hidden = [self.event.eventDescription length] == 0 ? YES : NO;
    header.descriptionLabel.text = self.event.eventDescription;
    self.tableView.tableHeaderView = header;
    
    self.forms = self.event.nonArchivedForms;
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) willMoveToParentViewController:(UIViewController *)parent {
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIView *header = self.tableView.tableHeaderView;
    CGSize size = [header systemLayoutSizeFittingSize:CGSizeMake(header.frame.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    if (header.frame.size.height != size.height) {
        CGRect frame = [header frame];
        frame.size.height = size.height;
        [header setFrame:frame];
        self.tableView.tableHeaderView = header;
        [self.tableView layoutIfNeeded];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.forms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    Form* form = [self.forms objectAtIndex:indexPath.row];
    cell.textLabel.text = [form name];
    cell.detailTextLabel.text = [form formDescription];
    cell.imageView.image = [UIImage systemImageNamed:@"doc.text.fill"];
    
    if ([form color] != nil) {
        cell.imageView.tintColor = [UIColor hx_colorWithHexRGBAString:[form color]];
    } else {
        cell.imageView.tintColor = self.scheme.colorScheme.primaryColor;
    }
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == FORMS_SECTION) {
        return @"Forms";
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Form *form = [self.forms objectAtIndex:indexPath.row];
    [self.delegate formSelected:form];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    }
}

@end
