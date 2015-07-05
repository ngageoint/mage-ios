//
//  ObservationEditViewController.m
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditViewController.h"
#import "ObservationEditViewDataStore.h"
#import "ObservationPickerTableViewCell.h"
#import "ObservationEditGeometryTableViewCell.h"
#import "GeometryEditViewController.h"
#import <Observation+helper.h>
#import <HttpManager.h>
#import <AVFoundation/AVFoundation.h>
#import <Attachment+helper.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioRecordingDelegate.h"
#import "MediaViewController.h"
#import "ImageViewerViewController.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationEditViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AudioRecordingDelegate, AttachmentSelectionDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet ObservationEditViewDataStore *editDataStore;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableBottomConstraint;

@end

@implementation ObservationEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = item;
    
    self.managedObjectContext = [NSManagedObjectContext MR_newMainQueueContext];
    self.managedObjectContext.parentContext = [NSManagedObjectContext MR_defaultContext];
    
    // if self.observation is null create a new one
    if (self.observation == nil) {
        self.observation = [Observation observationWithLocation:self.location inManagedObjectContext:self.managedObjectContext];
    } else {
        self.observation = [self.observation MR_inContext:self.managedObjectContext];
    }
    
    self.observation.dirty = [NSNumber numberWithBool:YES];
    self.editDataStore.observation = self.observation;
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"view will appear");
    [super viewWillAppear:animated];
}

-(void) cancel:(id)sender {
    self.managedObjectContext = nil;
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


- (IBAction)addFromCamera:(id)sender {
    
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
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
    
}


- (IBAction)addFromGallery:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
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
        UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
        
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
        
        NSData *imageData = UIImagePNGRepresentation(chosenImage);
        BOOL success = [imageData writeToFile:fileToWriteTo atomically:NO];
        NSLog(@"successfully wrote file %d", success);
        
        NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
        [attachmentJson setValue:@"image/png" forKey:@"contentType"];
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

- (IBAction)saveObservation:(id)sender {
    [self.editDataStore.editTable endEditing:YES];
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"saved the observation: %@", self.observation);
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
        ImageViewerViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

- (IBAction)unwindFromGeometryController: (UIStoryboardSegue *) segue {
    GeometryEditViewController *vc = [segue sourceViewController];
    [self.editDataStore observationField:vc.fieldDefinition valueChangedTo:vc.geoPoint reloadCell:YES];
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}


@end
