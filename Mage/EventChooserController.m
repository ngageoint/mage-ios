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

@interface EventChooserController() <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *chooseEventTitle;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *refreshingButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshingActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *refreshingView;

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
    
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self registerForThemeChanges];
    [self.tableView setDataSource:self.eventDataSource];
    [self.tableView setDelegate:self.eventDataSource];
    [self.tableView registerNib:[UINib nibWithNibName:@"EventCell" bundle:nil] forCellReuseIdentifier:@"eventCell"];
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

-(void) didSelectEvent:(Event *) event {
    
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

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    NSLog(@"Events changed");
    eventsChanged = YES;
}

- (void) initializeView {
    NSLog(@"Initializing View");
    eventsInitialized = YES;
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        // no events have been fetched at this point
        [self.refreshingView setHidden:YES];
    } else {
        if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 1 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
            Event *e = [self.eventDataSource.otherFetchedResultsController.fetchedObjects objectAtIndex:0];
            [Server setCurrentEventId:e.remoteId];
        }
        __weak typeof(self) weakSelf = self;
        
        [UIView animateWithDuration:0.75f animations:^{
            weakSelf.loadingView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            weakSelf.loadingView.alpha = 0.0;
        }];
    }
    [self.tableView reloadData];
    
    // TODO set up a timer to update the refresh button to indicate the request is taking a while
    
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
