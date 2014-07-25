//
//  MageNavigationMenuViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MageNavigationMenuViewController.h"
#import "UIViewController+RESideMenu.h"
#import "MapViewController.h"

@interface MageNavigationMenuViewController ()

@property (strong, readwrite, nonatomic) UITableView *tableView;

@end

@implementation MageNavigationMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height - 54 * 5) / 2.0f, self.view.frame.size.width, 54 * 5) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.opaque = NO;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.bounces = NO;
        tableView.scrollsToTop = NO;
        tableView;
    });
    [self.view addSubview:self.tableView];
}

#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected row at path row: %ld", (long)indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        // Map
        case 0: {
			id viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mapViewController"];
			[viewController setManagedObjectContext:_managedObjectContext];
            [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:viewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
		}
        // Observations
        case 1: {
            id viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"observationViewController"];
			[viewController setManagedObjectContext:_managedObjectContext];
            [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:viewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        }
        // People
        case 2: {
			id viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"peopleViewController"];
			[viewController setManagedObjectContext:_managedObjectContext];
            [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:viewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
		}
        // Settings
        case 3:
            [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"settingsViewController"]]
                                                         animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        // Logout
        case 4:
            [self performSegueWithIdentifier:@"unwindToInitialViewSegue" sender:self];
            break;

        default:
            break;
    }
}

#pragma mark -
#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:21];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.highlightedTextColor = [UIColor lightGrayColor];
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    NSArray *titles = @[@"Map", @"Observations", @"People", @"Settings", @"Log Out"];
//    NSArray *images = @[@"IconHome", @"IconCalendar", @"IconProfile", @"IconSettings", @"IconEmpty"];
    cell.textLabel.text = titles[indexPath.row];
//    cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
    
    return cell;
}


@end
