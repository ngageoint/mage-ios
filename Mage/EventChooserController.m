//
//  EventChooserController.m
//  MAGE
//
//

#import "EventChooserController.h"
#import "MAGE-Swift.h"
#import "ContactInfo.h"
#import <PureLayout/PureLayout.h>

@interface EventChooserController() <NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *chooseEventTitle;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *refreshingButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshingActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *refreshingView;
@property (strong, nonatomic) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UIView *searchContainer;
@property (weak, nonatomic) IBOutlet UILabel *refreshingStatus;
@property (weak, nonatomic) IBOutlet UILabel *eventInstructions;
@property (strong, nonatomic) NSFetchedResultsController *allEventsController;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@property BOOL checkForms;
@property BOOL eventsFetched;
@property BOOL eventsInitialized;
@property BOOL eventsChanged;
@end

@implementation EventChooserController {

}

- (instancetype) initWithDataSource: (EventTableDataSource *) eventDataSource andDelegate: (id<EventSelectionDelegate>) delegate andScheme:(id<MDCContainerScheming>) containerScheme {
    self = [super initWithNibName:@"EventChooserView" bundle:nil];
    if (!self) return nil;
    
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    
    self.delegate = delegate;
    self.scheme = containerScheme;
    self.eventDataSource = eventDataSource;
    self.eventDataSource.tableView = self.tableView;
    self.eventDataSource.eventSelectionDelegate = self;
    self.eventsInitialized = NO;
    self.eventsChanged = NO;
    self.eventsFetched = NO;
    self.checkForms = NO;
    
    self.allEventsController = [Event caseInsensitiveSortFetchAllWithSortTerm:@"name" ascending:true predicate:[NSPredicate predicateWithFormat:@"TRUEPREDICATE"] groupBy:nil context:[NSManagedObjectContext MR_defaultContext]];
    self.allEventsController.delegate = self;
    NSError *error;
    
    if (![self.allEventsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return self;
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }

    self.view.backgroundColor = self.scheme.colorScheme.primaryColor;
    self.loadingView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.chooseEventTitle.textColor = self.scheme.colorScheme.onPrimaryColor;
    self.eventInstructions.textColor = self.scheme.colorScheme.onPrimaryColor;
    [self.actionButton applyContainedThemeWithScheme:self.scheme];
    self.loadingLabel.textColor = self.scheme.colorScheme.onSurfaceColor;
    self.activityIndicator.color = self.scheme.colorScheme.onSurfaceColor;
    self.tableView.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.refreshingButton.backgroundColor = self.scheme.colorScheme.primaryColor;
    self.refreshingView.backgroundColor = self.scheme.colorScheme.primaryColor;
    self.refreshingButton.tintColor = self.scheme.colorScheme.onPrimaryColor;
    self.refreshingStatus.textColor = self.scheme.colorScheme.onPrimaryColor;
    
    self.searchController.searchBar.barTintColor = self.scheme.colorScheme.onPrimaryColor;
    self.searchController.searchBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
    self.searchController.searchBar.backgroundColor = self.scheme.colorScheme.primaryColor;
    self.searchContainer.backgroundColor = self.scheme.colorScheme.primaryColor;

    self.searchController.searchBar.searchTextField.backgroundColor = self.scheme.colorScheme.surfaceColor;

    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self.tableView setDataSource:self.eventDataSource];
    [self.tableView setDelegate:self.eventDataSource];
    [self.tableView registerNib:[UINib nibWithNibName:@"EventCell" bundle:nil] forCellReuseIdentifier:@"eventCell"];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.translucent = YES;
    self.searchController.delegate = self;
    
    self.refreshingButton.layer.shadowRadius = 3.0f;
    self.refreshingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.refreshingButton.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.refreshingButton.layer.shadowOpacity = 0.5f;
    self.refreshingButton.layer.masksToBounds = NO;
    [self.refreshingButton setHidden:YES];
    
    [self.searchContainer addSubview:self.searchController.searchBar];
    
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f]];
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f]];
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
    [self.searchContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.searchController.searchBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.searchContainer attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
    
    self.definesPresentationContext = YES;
    
    [self.actionButton setTitle:@"Return To Login" forState:UIControlStateNormal];
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.searchController.active) {
        [self.eventDataSource setEventFilter:searchController.searchBar.text withDelegate: self];
    } else {
        [self.eventDataSource setEventFilter:nil withDelegate: nil];
    }
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.eventsFetched == NO && self.eventsInitialized == NO && self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        self.loadingView.alpha = 1.0f;
        self.loadingLabel.text = @"Loading Events";
        self.actionButton.hidden = YES;
    }
    
    self.tableView.estimatedRowHeight = 52;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.eventsChanged = NO;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // This is necessary because on initial load the search bar is 1 pixel short of the width of the screen....
    // DRB 2018-05-09
    CGRect searchBarFrame = self.searchController.searchBar.frame;
    searchBarFrame.size.width = self.tableView.frame.size.width;
    self.searchController.searchBar.frame = searchBarFrame;
}

- (void) didSelectEvent:(Event *) event {
    __weak typeof(self) weakSelf = self;

    // verify the user is still in this event
    Event *fetchedEvent = [Event getEventWithEventId:event.remoteId context:[NSManagedObjectContext MR_defaultContext]];
    if (fetchedEvent == nil) {
    
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unauthorized"
                                                                       message:[NSString stringWithFormat:@"You are no longer part of the event '%@'.  Please contact an administrator if you need access.", event.name]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Refresh Events" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf refreshingButtonTapped:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // show the loading indicator
        self.loadingLabel.text = [NSString stringWithFormat:@"Gathering information for %@", event.name];
        [UIView animateWithDuration:0.75f animations:^{
            weakSelf.loadingView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            weakSelf.loadingView.alpha = 1.0;
        }];
        
        // if the searchcontroller is active, new views will not present themselves...
        // also don't try doing this in viewwilldisappear because it will not work...
        // DRB 2018-05-11
        [self.searchController setActive:NO];
        [self.delegate didSelectEvent:event];
    }
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
    if (type == NSFetchedResultsChangeInsert || type == NSFetchedResultsChangeDelete) {
        self.eventsChanged = YES;
    }
}

- (IBAction)refreshingButtonTapped:(id)sender {
    [self.eventDataSource refreshEventData];
    [self.tableView reloadData];
    [self.refreshingButton setHidden:YES];
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        
        NSString *error =  @"You must be part of an event to use MAGE.  Contact your administrator to be added to an event.";
        
        ContactInfo *info = [[ContactInfo alloc] initWithTitle:@"You are not in any events" andMessage:error];
        User *currentUser = [User fetchCurrentUserWithContext:NSManagedObjectContext.MR_defaultContext];
        if (currentUser != nil) {
            info.username = currentUser.username;
        }
        UITextView *messageText = [[UITextView alloc] initForAutoLayout];
        messageText.attributedText = info.messageWithContactInfo;
        messageText.textAlignment = NSTextAlignmentCenter;
        messageText.font = self.scheme.typographyScheme.body1;
        messageText.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        messageText.scrollEnabled = false;
        messageText.editable = false;
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundView = messageText;
        [messageText autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.tableView];
        
        self.actionButton.hidden = NO;
    } else if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
        [self didSelectEvent:e];
    } else if (self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0) {
        Event *e = [self.eventDataSource.recentFetchedResultsController.fetchedObjects objectAtIndex:0];
        [self didSelectEvent:e];
    }
}

- (void) initializeView {
    NSLog(@"Initializing View");
    
    __weak typeof(self) weakSelf = self;
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        // no events have been fetched at this point
        [self.refreshingView setHidden:YES];
    } else {
        self.eventsInitialized = YES;
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
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count > 1) {
        self.eventInstructions.text = @"Please choose an event.  The observations you create and your reported location will be part of the selected event.";
    } else if ((self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1) ||  (self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0)) {
        self.eventInstructions.text = @"You are a part of one event.  The observations you create and your reported location will be part of this event.";
        if (![[NSUserDefaults standardUserDefaults] showEventChooserOnce]) {
            if (self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 1) {
                Event *e = [self.eventDataSource.recentFetchedResultsController.fetchedObjects objectAtIndex:0];
                [self didSelectEvent:e];
            } else if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1) {
                Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
                [self didSelectEvent:e];
            }
        } else {
            [[NSUserDefaults standardUserDefaults] setShowEventChooserOnce:false];
        }
    }
    
    [self.tableView reloadData];
    
    // TODO set up a timer to update the refresh button to indicate the request is taking a while
    NSTimer *timer = [NSTimer timerWithTimeInterval:10.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        //code
        
        if (weakSelf.eventsFetched) {
            [timer invalidate];
        } else {
            weakSelf.refreshingStatus.text = @"Refreshing Events seems to be taking a while...";
        }
    }];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void) eventsFetchedFromServer {
    NSLog(@"Events were fetched");
    self.eventsFetched = YES;
    __weak typeof(self) weakSelf = self;
    
    [self.refreshingView setHidden:YES];
    
    if (!self.eventsInitialized) {
        self.eventsInitialized = YES;
        [self refreshingButtonTapped:nil];
    } else if (self.eventsChanged) {
        // were new events found that weren't already in the list?
        [self.refreshingButton setHidden:NO];
        UIView *aV = self.refreshingButton;
        CGRect endFrame = aV.frame;
        
        // Move annotation out of view
        aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - self.view.frame.size.height, aV.frame.size.width, aV.frame.size.height);
        
        // Animate drop
        [UIView animateWithDuration:1.0 delay:0 options: UIViewAnimationOptionCurveLinear animations:^{
            
            aV.frame = endFrame;
            
            // Animate squash
        }completion:^(BOOL finished){
            if (finished) {
                [UIView animateWithDuration:0.05 animations:^{
                    aV.transform = CGAffineTransformMakeScale(1.0, 0.8);
                    
                }completion:^(BOOL finished){
                    if (finished) {
                        [UIView animateWithDuration:0.1 animations:^{
                            aV.transform = CGAffineTransformIdentity;
                            
                        }];
                    }
                }];
            }
        }];
        
    }
    
    [UIView animateWithDuration:0.75f animations:^{
        weakSelf.loadingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        weakSelf.loadingView.alpha = 0.0;
    }];
    
    [self.refreshingActivityIndicator stopAnimating];
}

// These methods stop the search bar from moving its frame when clicked
// DRB 2018-05-09
#pragma mark - Search Bar Presentation Methods

BOOL registeredForSearchFrameUpdates = NO;
- (void)willPresentSearchController:(UISearchController *)searchController {
    registeredForSearchFrameUpdates = YES;
    [searchController.searchBar addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)willDismissSearchController:(UISearchController *)searchController{
    if (registeredForSearchFrameUpdates) {
        registeredForSearchFrameUpdates = NO;
        [searchController.searchBar removeObserver:self forKeyPath:@"frame"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.searchController.searchBar) {
        if (!CGSizeEqualToSize(self.searchController.searchBar.frame.size, self.searchContainer.frame.size)) {
            self.searchController.searchBar.superview.clipsToBounds = NO;
            self.searchController.searchBar.frame = CGRectMake(0, 0, self.searchContainer.frame.size.width, self.searchContainer.frame.size.height);
        }
    }
}

#pragma mark

@end
