//
//  ObservationEditViewController.m
//  Mage
//
//

#import "ObservationEditViewController.h"
#import "ObservationEditTableViewController.h"
#import "Observation.h"
#import "NSDate+Iso8601.h"

@import PhotosUI;

@interface ObservationEditViewController () <ObservationEditFieldDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) ObservationEditTableViewController *tableViewController;
@property (weak, nonatomic) IBOutlet UIView *tableContainerView;

@end

@implementation ObservationEditViewController

- (instancetype) initWithDelegate: (id<ObservationEditViewControllerDelegate>) delegate andObservation: (Observation *) observation andNew: (BOOL) newObservation {
    self = [super init];
    if (!self) return nil;
    
    _delegate = delegate;
    _observation = observation;
    _newObservation = newObservation;
    
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableViewController = [[ObservationEditTableViewController alloc] initWithObservation:self.observation andDelegate: self];
    [self addChildViewController:self.tableViewController];
    [self.tableContainerView addSubview:self.tableViewController.view];
    [self.tableViewController didMoveToParentViewController:self];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if (self.newObservation) {
        self.navigationItem.title = @"Create Observation";
    } else {
        self.navigationItem.title = @"Edit Observation";
    }
    
    self.tableViewController.observation = self.observation;
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
    
    if (!self.observation.geometryData) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Location Unknown"
                                     message:@"MAGE was unable to determine your location.  Please manually set the location of the new observation."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) refreshObservation {
    [self.tableViewController refreshObservation];
}

//- (IBAction) cancel:(id)sender {
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Discard Changes"
//                                                                   message:@"Do you want to discard your changes?"
//                                                            preferredStyle:UIAlertControllerStyleAlert];
//    
//    [alert addAction:[UIAlertAction actionWithTitle:@"Yes, Discard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self.delegate editCanceled];
//    }]];
//    
//    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
//    
//    [self presentViewController:alert animated:YES completion:nil];
//}

- (IBAction) addVoice:(id)sender {
    [self.delegate addVoiceAttachment];
}

- (IBAction) addVideo:(id)sender {
    [self.delegate addVideoAttachment];
}

- (IBAction) addFromCamera:(id)sender {
    [self.delegate addCameraAttachment];
}

- (IBAction) addFromGallery:(id)sender {
    [self.delegate addGalleryAttachment];
}

//- (IBAction) saveObservation:(id)sender {
//    [self setNavBarButtonsEnabled:NO];
//    
//    if (![self.tableViewController validate]) {
//        [self setNavBarButtonsEnabled:YES];
//        return;
//    }
//        
//    self.observation.timestamp = [NSDate dateFromIso8601String:[self.observation.properties objectForKey:@"timestamp"]];
//    
//    NSMutableDictionary *error = [self.observation.error mutableCopy];
//    if (error) {
//        [error removeAllObjects];
//        self.observation.error = error;
//    }
//    
//    [_delegate editComplete];
//    
//}

-(void) keyboardWillShow: (NSNotification *) notification {
    [self setNavBarButtonsEnabled:NO];
}

-(void) keyboardWillHide: (NSNotification *) notification {
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

- (void) fieldSelected: (NSDictionary *) field {
    [self.delegate fieldSelected:field];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editTableViewSegue"]) {
        self.tableViewController = [segue destinationViewController];
        self.tableViewController.observation = self.observation;
    }
}


@end
