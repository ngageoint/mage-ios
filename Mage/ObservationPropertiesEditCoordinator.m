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
#import "MapUtils.h"
#import "SFLineString.h"
#import "GeometryEditCoordinator.h"
#import "ObservationImage.h"
#import "MAGE-Swift.h"

@interface ObservationPropertiesEditCoordinator() <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ObservationEditViewControllerDelegate, AudioRecordingDelegate, PropertyEditDelegate, ObservationEditFieldDelegate, GeometryEditDelegate, AttachmentViewDelegate>

@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (weak, nonatomic) Observation *observation;
@property (nonatomic) BOOL newObservation;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) ObservationEditViewController *editController;
@property (strong, nonatomic) NSDictionary *currentEditField;
@property (strong, nonatomic) id currentEditValue;
@property (strong, nonatomic) id<ObservationPropertiesEditDelegate> delegate;

@end

@implementation ObservationPropertiesEditCoordinator

static const NSInteger kImageQualitySmall = 0;
static const NSInteger kImageQualityMedium = 1;
static const NSInteger kImageQualityLarge = 2;

static const NSInteger kImageMaxDimensionSmall = 320;
static const NSInteger kImageMaxDimensionMedium = 640;
static const NSInteger kImageMaxDimensionLarge = 2048;

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
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(editComplete)];
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
    if ([self.editController validate]) {
        [self.editController.navigationItem.rightBarButtonItem setEnabled:NO];
        [_delegate propertiesEditComplete];
    }
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

- (void) invalidValue:(id)value forFieldDefinition:(NSDictionary *)fieldDefinition {
}

#pragma

#pragma mark - ObservationEditViewControllerDelegate methods

- (void) fieldSelected:(NSDictionary *)field {
    self.currentEditField = field;
    NSArray *obsForms = [self.observation.properties objectForKey:@"forms"];
    NSNumber *formIndex = [field valueForKey:@"formIndex"];
    id name = [field valueForKey:@"name"];
    id value = self.currentEditValue = formIndex ? [[obsForms objectAtIndex:[formIndex integerValue]] objectForKey:name] : nil;
    if ([[field objectForKey:@"type"] isEqualToString:@"dropdown"] || [[field objectForKey:@"type"] isEqualToString:@"multiselectdropdown"] || [[field objectForKey:@"type"] isEqualToString:@"radio"]) {
        SelectEditViewController *editSelect = [[SelectEditViewController alloc] initWithFieldDefinition:field andValue: value andDelegate: self];
        editSelect.title = [field valueForKey:@"title"];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
        [editSelect.navigationItem setLeftBarButtonItem:backButton];
        [editSelect.navigationItem setRightBarButtonItem:doneButton];
        [self.navigationController pushViewController:editSelect animated:YES];
    } else if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
        if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
            SFGeometry *geometry = [self.observation getGeometry];
            GeometryEditCoordinator *editCoordinator = [[GeometryEditCoordinator alloc] initWithFieldDefinition:field andGeometry: geometry andPinImage:[ObservationImage imageForObservation:self.observation] andDelegate:self andNavigationController:self.navigationController];
            [self.childCoordinators addObject:editCoordinator];
            [editCoordinator start];
        } else {
            GeometryEditCoordinator *editCoordinator = [[GeometryEditCoordinator alloc] initWithFieldDefinition:field andGeometry: value andPinImage:nil andDelegate:self andNavigationController:self.navigationController];
            [self.childCoordinators addObject:editCoordinator];
            [editCoordinator start];
        }
    }
}

- (void) geometryEditComplete:(SFGeometry *)geometry coordinator:(id)coordinator {
    self.currentEditValue = geometry;
    [self fieldEditDone:NO];
    [self.childCoordinators removeObject:coordinator];
}

- (void) geometryEditCancel:(id)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void) attachmentSelected:(Attachment *)attachment {
    AttachmentViewCoordinator *attachmentCoordinator = [[AttachmentViewCoordinator alloc] initWithRootViewController:self.navigationController attachment:attachment delegate:self];
    [self.childCoordinators addObject:attachmentCoordinator];
    [attachmentCoordinator start];
}

- (void) doneViewingWithCoordinator:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void) fieldEditDone {
    [self fieldEditDone:YES];
}

- (void) fieldEditDone:(BOOL) popViewController {
    NSDictionary *field = self.currentEditField;
    id value = self.currentEditValue;
    
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.observation.geometry = value;
    } else if ([[field objectForKey:@"name"] isEqualToString:@"timestamp"]) {
        NSMutableDictionary *properties = [self.observation.properties mutableCopy];
        if (value == nil) {
            [properties removeObjectForKey:@"timestamp"];
        } else {
            [properties setObject:value forKey:@"timestamp"];
        }
        
        self.observation.properties = [properties copy];
    } else {
        NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
        NSNumber *number = [field objectForKey:@"formIndex"];
        NSUInteger formIndex = [number integerValue];
        NSMutableDictionary *newProperties = [self.observation.properties mutableCopy];
        NSMutableArray *forms = [[newProperties objectForKey:@"forms"] mutableCopy];
        NSMutableDictionary *newFormProperties = [[forms objectAtIndex:formIndex] mutableCopy];
        if (value == nil) {
            [newFormProperties removeObjectForKey:fieldKey];
        } else {
            [newFormProperties setObject:value forKey:fieldKey];
        }
        [forms replaceObjectAtIndex:formIndex withObject:newFormProperties];
        [newProperties setObject:[forms copy] forKey:@"forms"];
        
        self.observation.properties = [newProperties copy];
    }
    
    if (popViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) fieldEditCanceled {
    self.currentEditValue = nil;
    self.currentEditField = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) deleteObservation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Observation"
                                                                   message:@"Are you sure you want to delete this observation?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes, Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [_delegate deleteObservation];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    
    [self.navigationController.visibleViewController presentViewController:alert animated:YES completion:nil];

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
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.observation.managedObjectContext];
        attachment.observation = self.observation;
        
        [self.editController refreshObservation];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyymmdd_HHmmss"];
    
    NSString *attachmentsDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0] stringByAppendingPathComponent:@"/attachments"];
    
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl = (NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        NSString *moviePath = [videoUrl path];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
            [picker dismissViewControllerAnimated:YES completion:NULL];
            
            NSString *videoQuality = [self videoUploadQuality];
            AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
            if ([compatiblePresets containsObject:videoQuality]) {
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:videoQuality];
                NSString *fileToWriteTo = [attachmentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"MAGE_%@.mp4", [dateFormatter stringFromDate: [NSDate date]]]];

                exportSession.outputURL = [NSURL fileURLWithPath:fileToWriteTo];
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
                            [attachmentJson setValue:fileToWriteTo forKey:@"localPath"];
                            [attachmentJson setValue:[fileToWriteTo lastPathComponent] forKey:@"name"];
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
        
        NSString *fileToWriteTo = [attachmentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat: @"MAGE_%@.jpeg", [dateFormatter stringFromDate: [NSDate date]]]];
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
        
        NSData *imageData = [self jpegFromImage:chosenImage withMetaData:info[UIImagePickerControllerMediaMetadata]];
        BOOL success = [imageData writeToFile:fileToWriteTo atomically:NO];
        if (!success) {
            NSLog(@"Error: Could not write image to destination");
        }
        
        NSLog(@"successfully wrote file %d", success);
        
        NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
        [attachmentJson setValue:@"image/jpeg" forKey:@"contentType"];
        [attachmentJson setValue:fileToWriteTo forKey:@"localPath"];
        [attachmentJson setValue:[NSString stringWithFormat: @"MAGE_%@.jpeg", [dateFormatter stringFromDate: [NSDate date]]] forKey:@"name"];
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
        [weakSelf.navigationController.visibleViewController.navigationController pushViewController:recorder animated:YES];// presentViewController:recorder animated:YES completion:NULL];
    }];
}

- (NSString *) videoUploadQuality {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *videoDefaults = [defaults dictionaryForKey:@"videoUploadQualities"];
    NSString *videoUploadQualityPreference = [defaults valueForKey:[videoDefaults valueForKey:@"preferenceKey"]];
    NSString *videoQuality = AVAssetExportPresetHighestQuality;
    if ([videoUploadQualityPreference isEqualToString:AVAssetExportPresetLowQuality]) {
        videoQuality = AVAssetExportPresetLowQuality;
    } else if ([videoUploadQualityPreference isEqualToString:AVAssetExportPresetMediumQuality]) {
        videoQuality = AVAssetExportPresetMediumQuality;
    }
    
    return videoQuality;
}

- (NSData *) jpegFromImage:(UIImage *) image withMetaData:(NSDictionary *) metadata {
    UIImage *scaledImage = [self scaledImageWithImage:image];
    NSData *imageData = UIImageJPEGRepresentation(scaledImage, 1.0f);
    [self writeMetadataIntoImageData:imageData metadata:[metadata mutableCopy]];
    
    return imageData;
}

- (UIImage *) scaledImageWithImage:(UIImage *)image {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *imageDefaults = [defaults dictionaryForKey:@"imageUploadSizes"];
    NSInteger imageUploadQuality = [[defaults valueForKey:[imageDefaults valueForKey:@"preferenceKey"]] integerValue];
    
    CGFloat largestDimension = MAX(image.size.width, image.size.height);
    
    CGSize size = CGSizeZero;
    if (imageUploadQuality == kImageQualitySmall && largestDimension > kImageMaxDimensionSmall) {
        CGFloat scale = kImageMaxDimensionSmall / largestDimension;
        size = CGSizeMake(image.size.width * scale, image.size.height * scale);
    } else if (imageUploadQuality == kImageQualityMedium && largestDimension > kImageMaxDimensionMedium) {
        CGFloat scale = kImageMaxDimensionMedium / largestDimension;
        size = CGSizeMake(image.size.width * scale, image.size.height * scale);
    } else if (imageUploadQuality == kImageQualityLarge && largestDimension > kImageMaxDimensionLarge) {
        CGFloat scale = kImageMaxDimensionLarge / largestDimension;
        size = CGSizeMake(image.size.width * scale, image.size.height * scale);
    } else {
        // original
        return image;
    }
    
    UIGraphicsImageRendererFormat *format = [[UIGraphicsImageRendererFormat alloc] init];
    format.scale = 1.0;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *newImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext*_Nonnull myContext) {
        [image drawInRect:(CGRect) {.origin = CGPointZero, .size = size}];
    }];
    
    return newImage;
}

- (NSData *) writeMetadataIntoImageData:(NSData *) imageData metadata:(NSMutableDictionary *) metadata {
    // create an imagesourceref
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    
    // this is the type of image (e.g., public.jpeg)
    CFStringRef UTI = CGImageSourceGetType(source);
    
    // create a new data object and write the new image into it
    NSMutableData *destinationData = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) destinationData, UTI, 1, NULL);
    if (!destination) {
        NSLog(@"Error: Could not create image destination");
    }
    
    // add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef) metadata);
    BOOL success = NO;
    success = CGImageDestinationFinalize(destination);
    if (!success) {
        NSLog(@"Error: Could not create data from image destination");
    }
    
    CFRelease(destination);
    CFRelease(source);
    
    return destinationData;
}

@end
