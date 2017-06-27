//
//  ObservationEditViewController.m
//  Mage
//
//

#import "ObservationEditViewController.h"
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

@interface ObservationEditViewController ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) ObservationEditTableViewController *tableViewController;
@end

@implementation ObservationEditViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.managedObjectContext = [NSManagedObjectContext MR_newMainQueueContext];
    self.managedObjectContext.parentContext = [NSManagedObjectContext MR_rootSavingContext];
    [self.managedObjectContext MR_setWorkingName:@"Observation Edit Context"];
    
    // if self.observation is null create a new one
    if (self.observation == nil) {
        self.navigationItem.title = @"Create Observation";
        self.observation = [Observation observationWithLocation:self.location inManagedObjectContext:self.managedObjectContext];
        
        // fill in defaults
        NSMutableDictionary *properties = [self.observation.properties mutableCopy];
        Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
        NSArray *fields = [event.form objectForKey:@"fields"];
        for (NSDictionary *field in fields) {
            id value = [field objectForKey:@"value"];
            
            if (value) {
                [properties setObject:value forKey:[field objectForKey:@"name"]];
            }
        }
        self.observation.properties = properties;
        
    } else {
        self.navigationItem.title = @"Edit Observation";
        self.observation = [self.observation MR_inContext:self.managedObjectContext];
    }
    
    self.observation.dirty = [NSNumber numberWithBool:YES];
    
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
    
    if (!self.observation.geometry) {
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

- (IBAction) cancel:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Discard Changes"
                                                                   message:@"Do you want to discard your changes?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes, Discard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction) addVoice:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self checkMicrophonePermissionsWithCompletion:^(BOOL granted) {
        if (granted) {
            [weakSelf presentVoiceRecorder:sender];
        }
    }];
}

- (void) presentVoiceRecorder :(id) sender {
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [weakSelf performSegueWithIdentifier:@"recordAudioSegue" sender:sender];
    }];
}

- (IBAction) addVideo:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self checkCameraPermissionsWithCompletion:^(BOOL granted) {
        if (granted) {
            [weakSelf checkMicrophonePermissionsWithCompletion:^(BOOL granted) {
                if (granted) {
                    [weakSelf presentVideo];
                }
            }];
        }
    }];
}

- (void) presentVideo {
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = weakSelf.tableViewController;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [NSArray arrayWithObject:(NSString*) kUTTypeMovie];
        
        [weakSelf presentViewController:picker animated:YES completion:NULL];
    }];
}

- (IBAction) addFromCamera:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self checkCameraPermissionsWithCompletion:^(BOOL granted) {
        if (granted) {
            [weakSelf presentCamera];
        }
    }];
}

- (void) presentCamera {
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = weakSelf.tableViewController;
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [weakSelf presentViewController:picker animated:YES completion:NULL];
    }];
}

- (void) checkCameraPermissionsWithCompletion:(void (^)(BOOL granted)) complete {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Camera"
                                                                       message:@"Your device does not have a camera"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        complete(NO);
        return;
    }
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusAuthorized: {
            complete(YES);
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:complete];
            break;
        }
        case AVAuthorizationStatusRestricted: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Camera"
                                                                           message:@"You've been restricted from using the camera on this device. Please contact the device owner so they can give you access."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            complete(NO);
            break;
        }
        default: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Camera"
                                                                           message:@"MAGE has been denied access to the camera.  Please open Settings, and allow access to the camera."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:url];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            complete(NO);
            break;
        }
    }
    
}

- (void) checkMicrophonePermissionsWithCompletion:(void (^)(BOOL granted)) complete {
    if (![[AVAudioSession sharedInstance] isInputAvailable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Microphone"
                                                                       message:@"Your device does not have a microphone"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        complete(NO);
        return;
    }
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authorizationStatus) {
        case AVAuthorizationStatusAuthorized: {
            complete(YES);
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:complete];
            break;
        }
        case AVAuthorizationStatusRestricted: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Microphone"
                                                                           message:@"You've been restricted from using the microphone on this device. Please contact the device owner so they can give you access."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            complete(NO);
            break;
        }
        default: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Microphone"
                                                                           message:@"MAGE has been denied access to the microphone.  Please open Settings, and allow access to the microphone."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:url];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            complete(NO);
            break;
        }
    }
    
}

- (IBAction) addFromGallery:(id)sender {
    
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    switch (authorizationStatus) {
        case PHAuthorizationStatusAuthorized: {
            [self presentGallery];
            break;
        }
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [self presentGallery];
                }
            }];
            
            break;
        }
        case PHAuthorizationStatusRestricted: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Gallery"
                                                                           message:@"You've been restricted from using the gallery on this device. Please contact the device owner so they can give you access."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            break;
        }
        default: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Gallery"
                                                                           message:@"MAGE has been denied access to the gallery.  Please open Settings, and allow access to the gallery."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:url];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            break;
        }
    }
}

- (void) presentGallery {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self.tableViewController;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*) kUTTypeImage, nil];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction) saveObservation:(id)sender {
    [self setNavBarButtonsEnabled:NO];
    
    if (![self.tableViewController validate]) {
        [self setNavBarButtonsEnabled:YES];
        return;
    }
        
    self.observation.timestamp = [NSDate dateFromIso8601String:[self.observation.properties objectForKey:@"timestamp"]];
    self.observation.user = [User fetchCurrentUserInManagedObjectContext:self.managedObjectContext];
    
    NSMutableDictionary *error = [self.observation.error mutableCopy];
    if (error) {
        [error removeAllObjects];
        self.observation.error = error;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave) {
            NSLog(@"Error saving observation to persistent store, context did not save");
        }
        
        if (error) {
            NSLog(@"Error saving observation to persistent store %@", error);
        }
        
        NSLog(@"saved the observation: %@", weakSelf.observation.remoteId);
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"recordAudioSegue"]) {
        MediaViewController *mvc = [segue destinationViewController];
        mvc.delegate = self.tableViewController;
    } else if ([segue.identifier isEqualToString:@"editTableViewSegue"]) {
        self.tableViewController = [segue destinationViewController];
        self.tableViewController.observation = self.observation;
    }
}


@end
