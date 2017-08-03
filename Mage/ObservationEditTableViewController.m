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
@property (weak, nonatomic) IBOutlet ObservationEditViewDataStore *editDataStore;
@end

@implementation ObservationEditTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setEstimatedRowHeight:126.0f];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.observation.location) {
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

- (void) setObservation:(Observation *)observation {
    _observation = observation;
    self.editDataStore.observation = observation;
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"geometrySegue"]) {
        GeometryEditViewController *gvc = [segue destinationViewController];
        ObservationEditGeometryTableViewCell *cell = sender;
        gvc.fieldDefinition = cell.fieldDefinition;
        gvc.observation = self.observation;
        gvc.propertyEditDelegate = self;
    } else if ([segue.identifier isEqualToString:@"selectSegue"]) {
        SelectEditViewController *viewController = [segue destinationViewController];
        ObservationEditSelectTableViewCell *cell = sender;
        viewController.fieldDefinition = cell.fieldDefinition;
        viewController.value = cell.value;
        viewController.propertyEditDelegate = self;
    } else if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
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
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.observation.managedObjectContext];
                                attachment.observation = self.observation;
                                
                                [self.tableView reloadData];
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
        
        [self.tableView reloadData];
        
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void) recordingAvailable:(Recording *)recording {
    NSMutableDictionary *attachmentJson = [NSMutableDictionary dictionary];
    [attachmentJson setValue:recording.mediaType forKey:@"contentType"];
    [attachmentJson setValue:recording.filePath forKey:@"localPath"];
    [attachmentJson setValue:recording.fileName forKey:@"name"];
    [attachmentJson setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
    
    Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:self.observation.managedObjectContext];
    attachment.observation = self.observation;
    
    [self.tableView reloadData];
}



@end
