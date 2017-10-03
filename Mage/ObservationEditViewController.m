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
@property (nonatomic) BOOL didSetConstraints;

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

- (void) updateViewConstraints {
    [super updateViewConstraints];
    [self initConstraints];
}

- (void)initConstraints {
    if (!self.didSetConstraints) {
        self.didSetConstraints = YES;
        
        self.tableContainerView.subviews[0].translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *views = @{@"subview" : self.tableContainerView.subviews[0]};
        
        [self.tableContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subview]|" options:0 metrics:nil views:views]];
        [self.tableContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|" options:0 metrics:nil views:views]];
    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableViewController = [[ObservationEditTableViewController alloc] initWithObservation:self.observation andIsNew: self.newObservation andDelegate: self];
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

- (BOOL) validate {
    return [self.tableViewController validate];
}

- (void) refreshObservation {
    [self.tableViewController refreshObservation];
}

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

- (void) deleteObservation {
    [self.delegate deleteObservation];
}

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

- (void) attachmentSelected:(Attachment *)attachment {
    [self.delegate attachmentSelected: attachment];
}

@end
