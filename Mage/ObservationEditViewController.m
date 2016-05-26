//
//  ObservationEditViewController.m
//  Mage
//
//

#import "ObservationEditViewController.h"
#import "ObservationEditViewDataStore.h"
#import "ObservationPickerTableViewCell.h"
#import "ObservationEditGeometryTableViewCell.h"
#import "GeometryEditViewController.h"
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)addVoice:(id)sender {
    [self performSegueWithIdentifier:@"recordAudioSegue" sender:sender];
}

- (IBAction)addVideo:(id)sender {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        [myAlertView show];
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [NSArray arrayWithObject:(NSString*)kUTTypeMovie];
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
    
}


- (IBAction) addFromCamera:(id)sender {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Camera"
                                                                       message:@"Your device does not have a camera"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusAuthorized: {
            [self presentCamera];
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self presentCamera];
                }
            }];
            
            break;
        }
        case AVAuthorizationStatusRestricted: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Access Camera"
                                                                           message:@"You've been restricted from using the camera on this device. Please contact the device owner so they can give you access."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];

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
            
            break;
        }
    }
}

- (void) presentCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)addFromGallery:(id)sender {
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
        NSMutableDictionary *imageMetadata = [[info objectForKey:UIImagePickerControllerMediaMetadata] mutableCopy];
        
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
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
        CFStringRef UTI = CGImageSourceGetType(source);
        NSMutableData *destinationData = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) destinationData, UTI, 1, NULL);
        
        if (!destinationData) {
            NSLog(@"Error: Could not create image destination");
        }
        
        // add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
        CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef) imageMetadata);
        BOOL success = NO;
        success = CGImageDestinationFinalize(destination);
        
        success = [destinationData writeToFile:fileToWriteTo atomically:NO];
        
        if (!success) {
            NSLog(@"Error: Could not create data from image destination");
        }
        
        CFRelease(destination);
        CFRelease(source);
        
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
    __weak __typeof__(self) weakSelf = self;
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"geometrySegue"]) {
        GeometryEditViewController *gvc = [segue destinationViewController];
        ObservationEditGeometryTableViewCell *cell = sender;
        [gvc setGeoPoint:cell.geoPoint];
        [gvc setFieldDefinition: cell.fieldDefinition];
        [gvc setObservation:self.observation];
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

- (IBAction)unwindFromGeometryController: (UIStoryboardSegue *) segue {
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
