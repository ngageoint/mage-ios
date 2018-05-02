//
//  EventChooserController.m
//  MAGE
//
//

#import "EventChooserController.h"
#import "Event.h"
#import "Form.h"
#import "Mage.h"
#import "Server.h"
#import "UserUtility.h"
#import "Theme+UIResponder.h"

@interface EventChooserController() <NSFetchedResultsControllerDelegate, UISearchResultsUpdating>

@property (weak, nonatomic) IBOutlet UILabel *chooseEventTitle;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *refreshingButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshingActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *refreshingView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *refreshingViewHeight;
@property (strong, nonatomic) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UIView *searchContainer;

@end

@implementation EventChooserController

BOOL checkForms = NO;
BOOL eventsFetched = NO;
BOOL eventsInitialized = NO;
BOOL eventsChanged = NO;

- (instancetype) initWithDataSource: (EventTableDataSource *) eventDataSource andDelegate: (id<EventSelectionDelegate>) delegate {
    self = [super initWithNibName:@"EventChooserView" bundle:nil];
    if (!self) return nil;
    
    self.delegate = delegate;
    self.eventDataSource = eventDataSource;
    self.eventDataSource.tableView = self.tableView;
    self.eventDataSource.eventSelectionDelegate = self;
    
    return self;
}

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.loadingView.backgroundColor = [UIColor background];
    self.chooseEventTitle.textColor = [UIColor brand];
    self.actionButton.backgroundColor = [UIColor themedButton];
    self.loadingLabel.textColor = [UIColor brand];
    self.activityIndicator.color = [UIColor brand];
    self.tableView.backgroundColor = [UIColor background];
    
    self.searchController.searchBar.barTintColor = [UIColor dialog];
    self.searchController.searchBar.tintColor = [UIColor flatButton];
    self.searchController.searchBar.barStyle = UIBarStyleBlack;

    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self registerForThemeChanges];
    [self.tableView setDataSource:self.eventDataSource];
    [self.tableView setDelegate:self.eventDataSource];
    [self.tableView registerNib:[UINib nibWithNibName:@"EventCell" bundle:nil] forCellReuseIdentifier:@"eventCell"];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.barTintColor = [UIColor whiteColor];
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, CGFLOAT_MIN)];
    [self.searchContainer addSubview:self.searchController.searchBar];
    
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f]];
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
    
    self.definesPresentationContext = YES;
}

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.searchController.active) {
        [self.eventDataSource setEventFilter:searchController.searchBar.text withDelegate: self];
    } else {
        [self.eventDataSource setEventFilter:nil withDelegate: nil];
    }
    [self.tableView reloadData];
}

- (BOOL) isIphoneX {
    if (@available(iOS 11.0, *)) {
        return self.view.safeAreaInsets.top > 0.0;
    } else {
        return NO;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (eventsFetched == NO && eventsInitialized == NO && self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        self.loadingView.alpha = 1.0f;
        self.loadingLabel.text = @"Loading Events";
        self.actionButton.hidden = YES;
    }
    
    self.tableView.estimatedRowHeight = 52;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    eventsChanged = NO;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.searchContainer layoutIfNeeded];
    [self.searchController.searchBar sizeToFit];
    if ([self isIphoneX]) {
        self.refreshingViewHeight.constant = 56.0f;
        [self.view layoutIfNeeded];
    }
}

- (void) didSelectEvent:(Event *) event {
    
    [self.delegate didSelectEvent:event];
    __weak typeof(self) weakSelf = self;

    // show the loading indicator
    self.loadingLabel.text = [NSString stringWithFormat:@"Gathering information for %@", event.name];
    [UIView animateWithDuration:0.75f animations:^{
        weakSelf.loadingView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        weakSelf.loadingView.alpha = 1.0;
    }];
}

- (void)actionButtonTapped {
    [self.delegate actionButtonTapped];
}

- (IBAction)actionButtonTapped:(id)sender {
    [self.delegate actionButtonTapped];
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"controller changed content");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    
    NSLog(@"Events changed");
    eventsChanged = YES;
}

- (void) initializeView {
    NSLog(@"Initializing View");
    eventsInitialized = YES;
    
    __weak typeof(self) weakSelf = self;
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        // no events have been fetched at this point
        [self.refreshingView setHidden:YES];
    } else {
        if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
            Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
            [Server setCurrentEventId:e.remoteId];
        }
        
        [UIView animateWithDuration:0.75f animations:^{
            weakSelf.loadingView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            weakSelf.loadingView.alpha = 0.0;
        }];
    }
    [self.tableView reloadData];
    
    // TODO set up a timer to update the refresh button to indicate the request is taking a while
    NSTimer *timer = [NSTimer timerWithTimeInterval:10.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        //code
        if (eventsFetched) {
            [timer invalidate];
        } else {
            [weakSelf.refreshingButton setTitle:@"Refreshing Events seems to be taking a while..." forState:UIControlStateNormal];
        }
    }];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void) eventsFetched {
    NSLog(@"Events were fetched");
    eventsFetched = YES;
    __weak typeof(self) weakSelf = self;
    
    // were new events found that weren't already in the list?
    if (eventsChanged) {
        [self.refreshingButton setTitle:@"Tap To Refresh Your Events" forState:UIControlStateNormal];
    } else {
        [self.refreshingView setHidden:YES];
    }
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 20, self.tableView.bounds.size.width - 32, 0)];
        messageLabel.text = @"You are not in any events.  You must be part of an event to use MAGE.  Contact your administrator to be added to an event.";
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:20];
        messageLabel.textColor = [UIColor secondaryText];
        [messageLabel sizeToFit];
        
        UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        [messageView addSubview:messageLabel];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundView = messageView;
        
        self.actionButton.hidden = NO;
    } else if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
        [Server setCurrentEventId:e.remoteId];
    }
    [self.tableView reloadData];
    
    [UIView animateWithDuration:0.75f animations:^{
        weakSelf.loadingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        weakSelf.loadingView.alpha = 0.0;
    }];
    
    [self.refreshingActivityIndicator stopAnimating];
}

@end
