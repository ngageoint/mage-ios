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
#import "UIColor+UIColor_Mage.h"

@implementation EventChooserController

BOOL checkForms = NO;
BOOL eventsFetched = NO;

- (instancetype) initWithDataSource: (EventTableDataSource *) eventDataSource andDelegate: (id<EventSelectionDelegate>) delegate {
    self = [super initWithNibName:@"EventChooserView" bundle:nil];
    if (!self) return nil;
    
    self.delegate = delegate;
    self.eventDataSource = eventDataSource;
    self.eventDataSource.tableView = self.tableView;
    self.eventDataSource.eventSelectionDelegate = self;
    
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor primaryColor];
    self.loadingView.backgroundColor = [UIColor primaryColor];
    self.actionButton.backgroundColor = [UIColor darkerPrimary];
    [self.actionButton setTitleColor:[UIColor secondaryColor] forState:UIControlStateNormal];
    [self.tableView setDataSource:self.eventDataSource];
    [self.tableView setDelegate:self.eventDataSource];
    [self.tableView registerNib:[UINib nibWithNibName:@"EventCell" bundle:nil] forCellReuseIdentifier:@"eventCell"];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (eventsFetched == NO && self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        self.loadingView.alpha = 1.0f;
        self.loadingLabel.text = @"Loading Events";
        self.actionButton.hidden = YES;
    }
    
    self.tableView.estimatedRowHeight = 52;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

-(void) didSelectEvent:(Event *) event {
    
    [self.delegate didSelectEvent:event];
    
    // show the loading indicator
    self.loadingLabel.text = [NSString stringWithFormat:@"Gathering information for %@", event.name];
    [UIView animateWithDuration:0.75f animations:^{
        self.loadingView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.loadingView.alpha = 1.0;
    }];
}

- (void)actionButtonTapped {
    [self.delegate actionButtonTapped];
}

- (void) eventsFetched {
    NSLog(@"Events were fetched");
    eventsFetched = YES;
    
    [UIView animateWithDuration:0.75f animations:^{
        self.loadingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.loadingView.alpha = 0.0;
    }];
    
    if (self.eventDataSource.otherFetchedResultsController.fetchedObjects.count == 0 && self.eventDataSource.recentFetchedResultsController.fetchedObjects.count == 0) {
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.tableView.bounds.size.width, 0)];
        messageLabel.text = @"You are not in any events.  You must be part of an event to use MAGE.  Contact your administrator to be added to an event.";
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:20];
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
}

@end
