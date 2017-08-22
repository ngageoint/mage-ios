//
//  ObservationFieldEditCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 8/17/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationPropertiesEditCoordinator.h"
#import "ObservationEditViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "AudioRecorderViewController.h"
#import "AudioRecordingDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import <ImageIO/ImageIO.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SelectEditViewController.h"
#import "GeometryEditViewController.h"
#import "ExternalDevice.h"
#import "AttachmentViewController.h"

@interface ObservationPropertiesEditCoordinator() <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ObservationEditViewControllerDelegate, AudioRecordingDelegate, PropertyEditDelegate, ObservationEditFieldDelegate>

@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) Observation *observation;
@property (nonatomic) BOOL newObservation;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) ObservationEditViewController *editController;
@property (strong, nonatomic) NSDictionary *currentEditField;
@property (strong, nonatomic) id currentEditValue;
@property (strong, nonatomic) id<ObservationPropertiesEditDelegate> delegate;

@end

@implementation ObservationPropertiesEditCoordinator

- (instancetype) initWithObservation: (Observation *) observation  andNewObservation: (BOOL) newObservation andNavigationController:(UINavigationController *)navigationController andDelegate: (id<ObservationPropertiesEditDelegate>) delegate {
    self = [super init];
    if (!self) return nil;
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _observation = observation;
    _navigationController = navigationController;
    _newObservation = newObservation;
    _delegate = delegate;
    
    return self;
}

- (void) start {
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(editCanceled)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:_delegate action:@selector(propertiesEditComplete)];
    self.editController = [[ObservationEditViewController alloc] initWithDelegate:self andObservation:self.observation andNew:self.newObservation];
    [self.editController.navigationItem setLeftBarButtonItem:back];
    [self.editController.navigationItem setRightBarButtonItem:doneButton];
    
    CATransition *transition = [CATransition animation];
    transition.duration = .3f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController pushViewController:self.editController animated:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void) editComplete {
    [_delegate propertiesEditComplete];
}

- (void) editCanceled {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Discard Changes"
                                                                   message:@"Do you want to discard your changes?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes, Discard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [_delegate propertiesEditCanceled];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    
    [self.navigationController.visibleViewController presentViewController:alert animated:YES completion:nil];

}

#pragma mark - PropertyEditDelegate

- (void) setValue:(id)value forFieldDefinition:(NSDictionary *)fieldDefinition {
    self.currentEditValue = value;
}

#pragma

#pragma mark - ObservationEditViewControllerDelegate methods

- (void) fieldSelected:(NSDictionary *)field {
    self.currentEditField = field;
    
    if ([[field objectForKey:@"type"] isEqualToString:@"dropdown"]) {
        SelectEditViewController *editSelect = [[SelectEditViewController alloc] initWithFieldDefinition:field andDelegate: self];
        editSelect.title = [field valueForKey:@"title"];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
        [editSelect.navigationItem setLeftBarButtonItem:backButton];
        [editSelect.navigationItem setRightBarButtonItem:doneButton];
        [self.navigationController pushViewController:editSelect animated:YES];
    } else if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
        GeometryEditViewController *editGeometry = [[GeometryEditViewController alloc] initWithFieldDefinition: field andObservation: self.observation andDelegate: self];
        editGeometry.title = [field valueForKey:@"title"];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
        [editGeometry.navigationItem setLeftBarButtonItem:backButton];
        [editGeometry.navigationItem setRightBarButtonItem:doneButton];
        [self.navigationController pushViewController:editGeometry animated:YES];
    }
}

- (void) attachmentSelected:(Attachment *)attachment {
    AttachmentViewController *vc = [[AttachmentViewController alloc] init];
    [vc setAttachment:attachment];
    [vc setTitle:@"Attachment"];
    [self.navigationController pushViewController:vc animated:YES];
    
    //    AttachmentViewController *vc = [segue destinationViewController];
    //    [vc setAttachment:attachment];
    //    [vc setTitle:@"Attachment"];
}

- (void) fieldEditDone {
    [self.observation.properties objectForKey:@"forms"];
    
    NSDictionary *field = self.currentEditField;
    id value = self.currentEditValue;
    
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.observation.geometry = value;
    } else if ([[field objectForKey:@"name"] isEqualToString:@"timestamp"]) {
        if (value == nil) {
            [self.observation.properties removeObjectForKey:@"timestamp"];
        } else {
            [self.observation.properties setObject:value forKey:@"timestamp"];
        }
    } else {
        NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
        NSNumber *number = [field objectForKey:@"formIndex"];
        NSUInteger formIndex = [number integerValue];
        NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:self.observation.properties];
        NSMutableArray *forms = [newProperties objectForKey:@"forms"];
        NSMutableDictionary *newFormProperties = [[NSMutableDictionary alloc] initWithDictionary:[forms objectAtIndex:formIndex]];
        if (value == nil) {
            [newFormProperties removeObjectForKey:fieldKey];
        } else {
            [newFormProperties setObject:value forKey:fieldKey];
        }
        [forms replaceObjectAtIndex:formIndex withObject:newFormProperties];
        [newProperties setObject:forms forKey:@"forms"];
        
        
        self.observation.properties = newProperties;
    }
    
    
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) fieldEditCanceled{
    self.currentEditValue = nil;
    self.currentEditField = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) addVoiceAttachment {
    __weak typeof(self) weakSelf = self;
    [ExternalDevice checkMicrophonePermissionsForViewController:self.navigationController.visibleViewController withCompletion:^(BOOL granted) {
        if (granted) {
            [weakSelf presentVoiceRecorder];
        }
    }];
}

- (void) addVideoAttachment {
    __weak typeof(self) weakSelf = self;
    [ExternalDevice checkCameraPermissionsForViewController: self.navigationController.visibleViewController withCompletion:^(BOOL granted) {
        if (granted) {
            [ExternalDevice checkMicrophonePermissionsForViewController: weakSelf.navigationController.visibleViewController withCompletion:^(BOOL granted) {
                if (granted) {
                    [weakSelf presentVideo];
                }
            }];
        }
    }];
}

- (void) addCameraAttachment {
    __weak typeof(self) weakSelf = self;
    [ExternalDevice checkCameraPermissionsForViewController: self.navigationController.visibleViewController withCompletion:^(BOOL granted) {
        if (granted) {
            [weakSelf presentCamera];
        }
    }];
}

- (void) addGalleryAttachment {
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
            
            [self.navigationController.visibleViewController presentViewController:alert animated:YES completion:nil];
            
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
            
            [self.navigationController.visibleViewController presentViewController:alert animated:YES completion:nil];
            
            break;
        }
    }
}

#pragma

#pragma mark - AudioRecordingDelegate methods

- (void) recordingAvailable:(Recording *)recording {
    NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
    [attachmentJson setValue:recording.mediaType forKey:@"contentType"];
    [attachmentJson setValue:recording.filePath forKey:@"localPath"];
    [attachmentJson setValue:recording.fileName forKey:@"name"];
    [attachmentJson setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
    
    Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.observation.managedObjectContext];
    attachment.observation = self.observation;
    
    [self.editController refreshObservation];
}

#pragma

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
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.observation.managedObjectContext];
                                attachment.observation = self.observation;
                                
                                [self.editController refreshObservation];
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
        
        Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.observation.managedObjectContext];
        attachment.observation = self.observation;
        
        [self.editController refreshObservation];
        
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void) presentGallery {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    picker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*) kUTTypeImage, nil];
    
    [self.navigationController.visibleViewController presentViewController:picker animated:YES completion:NULL];
}

- (void) presentCamera {
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [weakSelf.navigationController.visibleViewController presentViewController:picker animated:YES completion:NULL];
    }];
}

- (void) presentVideo {
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [NSArray arrayWithObject:(NSString*) kUTTypeMovie];
        
        [weakSelf.navigationController.visibleViewController presentViewController:picker animated:YES completion:NULL];
    }];
}

- (void) presentVoiceRecorder {
    __weak typeof(self) weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        AudioRecorderViewController *recorder = [[AudioRecorderViewController alloc] init];
        recorder.delegate = weakSelf;
        [weakSelf.navigationController.visibleViewController presentViewController:recorder animated:YES completion:^{
            NSLog(@"recorder shown");
        }];
    }];
}


@end
