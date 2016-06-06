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
#import <HttpManager.h>
#import <AVFoundation/AVFoundation.h>
#import "Attachment.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AudioRecordingDelegate.h"
#import "MediaViewController.h"
#import "AttachmentViewController.h"
#import "AttachmentSelectionDelegate.h"
#import "Server.h"
#import "Event.h"
#import <ImageIO/ImageIO.h>
#import "ObservationEditTextFieldTableViewCell.h"

@import PhotosUI;

@interface ObservationEditViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AudioRecordingDelegate, AttachmentSelectionDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UITableView *editTable;
@property (weak, nonatomic) IBOutlet ObservationEditViewDataStore *editDataStore;
@end

@implementation ObservationEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = item;
    
    self.managedObjectContext = [NSManagedObjectContext MR_newMainQueueContext];
    [self.managedObjectContext MR_setWorkingName:@"Observation Edit Context"];
    self.managedObjectContext.parentContext = [NSManagedObjectContext MR_defaultContext];
    
    // if self.observation is null create a new one
    if (self.observation == nil) {
        self.navigationItem.title = @"Create Observation";
        self.observation = [Observation observationWithLocation:self.location inManagedObjectContext:self.managedObjectContext];
    } else {
        self.navigationItem.title = @"Edit Observation";
        self.observation = [self.observation MR_inContext:self.managedObjectContext];
    }
    
    self.observation.dirty = [NSNumber numberWithBool:YES];
    self.editDataStore.observation = self.observation;
    
    [self.editTable setEstimatedRowHeight:44.0f];
    [self.editTable setRowHeight:UITableViewAutomaticDimension];
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
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) cancel:(id)sender {
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
        picker.delegate = weakSelf;
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
        picker.delegate = weakSelf;
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
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*) kUTTypeImage, nil];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        NSString *moviePath = [videoUrl path];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
            [picker dismissViewControllerAnimated:YES completion:NULL];
            
            AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
            if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetLowQuality];
                NSString *mp4Path = [[moviePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"];

                exportSession.outputURL = [NSURL fileURLWithPath:mp4Path];
                exportSession.outputFileType = AVFileTypeMPEG4;
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    switch ([exportSession status]) {
                        case AVAssetExportSessionStatusFailed:
                            NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                            break;
                        case AVAssetExportSessionStatusCancelled:
                            NSLog(@"Export canceled");
                            break;
                        case AVAssetExportSessionStatusCompleted: {
                            NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
                            [attachmentJson setValue:@"video/mp4" forKey:@"contentType"];
                            [attachmentJson setValue:mp4Path forKey:@"localPath"];
                            [attachmentJson setValue:[mp4Path lastPathComponent] forKey:@"name"];
                            [attachmentJson setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
                            
                            Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.managedObjectContext];
                            attachment.observation = self.observation;
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                [self.editDataStore.editTable beginUpdates];
                                [self.editDataStore.editTable reloadData];
                                [self.editDataStore.editTable endUpdates];
                            }];

                        }
                        default:
                            break;
                    }
                }];
            }
        }
    } else {
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        UIImageWriteToSavedPhotosAlbum(chosenImage, nil, nil, nil);
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyymmdd_HHmmss"];
        
        NSString *attachmentsDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0] stringByAppendingPathComponent:@"/attachments"];
        NSString *fileToWriteTo = [attachmentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"MAGE_%@.png", [dateFormatter stringFromDate: [NSDate date]]]];
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isDirectory;
        if (![manager fileExistsAtPath:attachmentsDirectory isDirectory:&isDirectory] || !isDirectory) {
            NSError *error = nil;
            NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                             forKey:NSFileProtectionKey];
            [manager createDirectoryAtPath:attachmentsDirectory
               withIntermediateDirectories:YES
                                attributes:attr
                                     error:&error];
            if (error)
                NSLog(@"Error creating directory path: %@", [error localizedDescription]);
        }
        
        NSData *imageData = UIImageJPEGRepresentation(chosenImage, 1.0f);
        BOOL success = [imageData writeToFile:fileToWriteTo atomically:NO];
        if (!success) {
            NSLog(@"Error: Could not write image to destination");
        }

        NSLog(@"successfully wrote file %d", success);
        
        NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
        [attachmentJson setValue:@"image/jpeg" forKey:@"contentType"];
        [attachmentJson setValue:fileToWriteTo forKey:@"localPath"];
        [attachmentJson setValue:[NSString stringWithFormat: @"MAGE_%@.png", [dateFormatter stringFromDate: [NSDate date]]] forKey:@"name"];
        [attachmentJson setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
        
        Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.managedObjectContext];
        attachment.observation = self.observation;
        
        [self.editDataStore.editTable beginUpdates];
        [self.editDataStore.editTable reloadData];
        [self.editDataStore.editTable endUpdates];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void) recordingAvailable:(Recording *)recording {
    NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
    [attachmentJson setValue:recording.mediaType forKey:@"contentType"];
    [attachmentJson setValue:recording.filePath forKey:@"localPath"];
    [attachmentJson setValue:recording.fileName forKey:@"name"];
    [attachmentJson setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
    
    Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.managedObjectContext];
    attachment.observation = self.observation;
    
    [self.editDataStore.editTable beginUpdates];
    [self.editDataStore.editTable reloadData];
    [self.editDataStore.editTable endUpdates];
}

- (IBAction) saveObservation:(id)sender {
    if (![self.editDataStore validate]) {
        return;
    }
    
    [self.editDataStore.editTable endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave) {
            NSLog(@"Error saving observation to persistent store, context did not save");
        }
        
        if (error) {
            NSLog(@"Error saving observation to persistent store %@", error);
        }
        
        NSLog(@"saved the observation: %@", weakSelf.observation);
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

-(void) keyboardWillShow: (NSNotification *) notification {
    if (self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }
    
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

-(void) keyboardWillHide: (NSNotification *) notification {
    if (self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
    
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void) setValue:(id) value forFieldDefinition:(NSDictionary *) fieldDefinition {
    [self.editDataStore observationField:fieldDefinition valueChangedTo:value reloadCell:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"geometrySegue"]) {
        GeometryEditViewController *gvc = [segue destinationViewController];
        ObservationEditGeometryTableViewCell *cell = sender;
        [gvc setGeoPoint:cell.geoPoint];
        [gvc setFieldDefinition: cell.fieldDefinition];
        [gvc setObservation:self.observation];
    } else if ([segue.identifier isEqualToString:@"selectSegue"]) {
        SelectEditViewController *viewController = [segue destinationViewController];
        ObservationEditSelectTableViewCell *cell = sender;
        viewController.fieldDefinition = cell.fieldDefinition;
        viewController.value = cell.value;
        viewController.propertyEditDelegate = self;
    } else if ([segue.identifier isEqualToString:@"recordAudioSegue"]) {
        MediaViewController *mvc = [segue destinationViewController];
        mvc.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

- (IBAction) unwindFromGeometryController: (UIStoryboardSegue *) segue {
    GeometryEditViewController *vc = [segue sourceViewController];
    if ([[vc.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.observation.geometry = vc.geoPoint;
        [self.editTable reloadData];
    } else {
        [self.editDataStore observationField:vc.fieldDefinition valueChangedTo:vc.geoPoint reloadCell:YES];
    }
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}


@end
