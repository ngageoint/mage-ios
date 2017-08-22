//
//  ObservationEditViewController.m
//  Mage
//
//

#import "ObservationEditTableViewController.h"
#import "ObservationEditViewDataStore.h"
#import "ObservationEditSelectTableViewCell.h"
#import "ObservationEditGeometryTableViewCell.h"
#import "GeometryEditViewController.h"
#import "SelectEditViewController.h"
#import "Observation.h"
#import <MageSessionManager.h>
#import <AVFoundation/AVFoundation.h>
#import "Attachment.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AudioRecordingDelegate.h"
#import "MediaViewController.h"
#import "AttachmentViewController.h"
#import "AttachmentSelectionDelegate.h"
#import "Server.h"
#import "Event.h"
#import "User.h"
#import <ImageIO/ImageIO.h>
#import "ObservationEditTextFieldTableViewCell.h"
#import "NSDate+Iso8601.h"

@import PhotosUI;

@interface ObservationEditTableViewController () <AttachmentSelectionDelegate>
@property (strong, nonatomic) IBOutlet ObservationEditViewDataStore *editDataStore;
@property (strong, nonatomic) id<ObservationEditFieldDelegate> delegate;
@end

@implementation ObservationEditTableViewController

- (instancetype) initWithObservation: (Observation *) observation andDelegate:(id<ObservationEditFieldDelegate>)delegate {
    self = [super init];
    if (!self) return nil;
    
    _observation = observation;
    _delegate = delegate;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCellTypes];
    
    _editDataStore = [[ObservationEditViewDataStore alloc] initWithObservation:self.observation andDelegate:self.delegate];
    _editDataStore.attachmentSelectionDelegate = self;

    [self.tableView setDelegate:_editDataStore];
    [self.tableView setDataSource:_editDataStore];
    [self.tableView setEstimatedRowHeight:126.0f];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self.observation getGeometry] == nil) {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Location Unknown"
                                     message:@"MAGE was unable to determine your location.  Please manually set the location of the new observation."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserDefaults:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

}

- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationEditCell" bundle:nil] forCellReuseIdentifier:@"ObservationEditCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDateEditCell" bundle:nil] forCellReuseIdentifier:@"date"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationGeometryEditCell" bundle:nil] forCellReuseIdentifier:@"geometry"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationCheckboxEditCell" bundle:nil] forCellReuseIdentifier:@"checkbox"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationEmailEditCell" bundle:nil] forCellReuseIdentifier:@"email"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationNumberEditCell" bundle:nil] forCellReuseIdentifier:@"number"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationTextAreaEditCell" bundle:nil] forCellReuseIdentifier:@"textarea"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationAttachmentEditCell" bundle:nil] forCellReuseIdentifier:@"attachment"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDropdownEditCell" bundle:nil] forCellReuseIdentifier:@"dropdown"];
//    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDropdownEditCell" bundle:nil] forCellReuseIdentifier:@"radio"];
//    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationDropdownEditCell" bundle:nil] forCellReuseIdentifier:@"multiselectdropdown"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationPasswordEditCell" bundle:nil] forCellReuseIdentifier:@"password"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationTextfieldEditCell" bundle:nil] forCellReuseIdentifier:@"textfield"];
}

- (void) updateUserDefaults: (NSNotification *) notification {
    [self.tableView reloadData];
}

- (void) setValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition {
    [self.editDataStore observationField:fieldDefinition valueChangedTo:value reloadCell:YES];
}

- (BOOL) validate {
    [self.tableView endEditing:YES];

    return [self.editDataStore validate];
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    
    [self.delegate attachmentSelected:attachment];
}


- (void) refreshObservation {
    [self.tableView reloadData];
}

@end
