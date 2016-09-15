//
//  MeViewController.m
//  MAGE
//
//

#import "MeViewController.h"
#import "UIImage+Resize.h"
#import "ManagedObjectContextHolder.h"
#import "Observations.h"
#import "User.h"
#import <MapKit/MapKit.h>
#import <AVFoundation/AVFoundation.h>

#import "Locations.h"
#import "MapDelegate.h"
#import "Location.h"
#import "ObservationDataStore.h"
#import "AttachmentViewController.h"
#import <AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <MageServer.h>
#import <HttpManager.h>
#import "LocationAnnotation.h"
#import "GPSLocation.h"
#import <GeoPoint.h>
#import "AttachmentSelectionDelegate.h"

@import PhotosUI;

@interface MeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AttachmentSelectionDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIView *phoneView;
@property (weak, nonatomic) IBOutlet UITextView *phoneNumber;
@property (weak, nonatomic) IBOutlet UIView *emailView;
@property (weak, nonatomic) IBOutlet UITextView *email;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MeViewController

bool currentUserIsMe = NO;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if (self.user == nil) {
        self.user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        currentUserIsMe = YES;
        self.title = @"Me";
    } else {
        currentUserIsMe = NO;
        self.title = self.user.name;
    }

    // TODO put in storyboard
//    self.avatar.layer.cornerRadius = 4;
//    self.avatar.layer.borderColor = [[UIColor whiteColor] CGColor];
//    self.avatar.layer.borderWidth = 4;
//    self.avatar.layer.masksToBounds = YES;

    self.name.text = self.user.name;
    
    self.phoneNumber.text = self.user.phone;
    self.phoneView.hidden = self.user.phone ? NO : YES;

    self.email.text = self.user.email;
    self.emailView.hidden = self.user.email ? NO : YES;
    
    Observations *observations = [Observations observationsForUser:self.user];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:observations];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        Locations *locations = [Locations locationsForUser:self.user];
        [self.mapDelegate setLocations:locations];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString* avatarFile = [documentsDirectory stringByAppendingPathComponent:self.user.avatarUrl];
    if([[NSFileManager defaultManager] fileExistsAtPath:avatarFile]) {
        self.avatar.image = [UIImage imageWithContentsOfFile:avatarFile];
    }
    
    CLLocation *location = nil;
    if (currentUserIsMe) {
        NSArray *lastLocation = [GPSLocation fetchLastXGPSLocations:1];
        if (lastLocation.count != 0) {
            GPSLocation *gpsLocation = [lastLocation objectAtIndex:0];
            location = ((GeoPoint *) gpsLocation.geometry).location;
            [self.mapDelegate updateGPSLocation:gpsLocation forUser:self.user andCenter:NO];
        }
    }
    
    
    if (!location) {
        NSArray *locations = [self.mapDelegate.locations.fetchedResultsController fetchedObjects];
        if ([locations count]) {
            location = ((GeoPoint *) [[locations objectAtIndex:0] geometry]).location;
        }
    }
    
    if (location) {
        // Zoom and center the map
        CLLocationDistance latitudeMeters = 500;
        CLLocationDistance longitudeMeters = 500;
        double accuracy = location.horizontalAccuracy;
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, latitudeMeters, longitudeMeters);
        MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
        [self.mapDelegate selectedUser:self.user region:viewRegion];
    }
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (IBAction)portraitClick:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Avatar"
                                                                   message:@"Change or view your avatar"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"View Avatar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performSegueWithIdentifier:@"viewAvatarSegue" sender:self];
    }]];
    
    if (currentUserIsMe) {
        [alert addAction:[UIAlertAction actionWithTitle:@"New Avatar Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf checkCameraPermissionsWithCompletion:^(BOOL granted) {
                if (granted) {
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = weakSelf;
                    picker.allowsEditing = YES;
                    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                    
                    [weakSelf presentViewController:picker animated:YES completion:NULL];                }
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"New Avatar From Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf checkGalleryPermissionsWithCompletion:^(BOOL granted) {
                if (granted) {
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = weakSelf;
                    picker.allowsEditing = YES;
                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    
                    [weakSelf presentViewController:picker animated:YES completion:NULL];
                }
            }];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = self.view.frame;
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }

    [self presentViewController:alert animated:YES completion:nil];
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

- (void) checkGalleryPermissionsWithCompletion:(void (^)(BOOL granted)) complete {
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    switch (authorizationStatus) {
        case PHAuthorizationStatusAuthorized: {
            complete(YES);
            break;
        }
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    complete(YES);
                } else {
                    complete(NO);
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
            
            complete(NO);
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
            
            complete(NO);
            break;
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];

    self.avatar.image = chosenImage;
    
    NSData *imageData = UIImageJPEGRepresentation(chosenImage, 1.0f);
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *userAvatarPath = [NSString stringWithFormat:@"%@/userAvatars/%@", documentsDirectory, self.user.remoteId];
    BOOL success = [imageData writeToFile:userAvatarPath atomically:NO];

    if (!success) {
        NSLog(@"Error: Could not write image file to destination");
    }
    
    [picker dismissViewControllerAnimated:YES completion:NULL];

    HttpManager *manager = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", [MageServer baseURL], @"api/users", self.user.remoteId];
    
    NSMutableURLRequest *request = [manager.sessionManager.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"avatar" fileName:@"avatar.jpeg" mimeType:@"image/jpeg"];
    } error:nil];
    
    NSProgress *progress = nil;
    
    NSURLSessionUploadTask *uploadTask = [manager.sessionManager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
    }];
    
    [uploadTask resume];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"viewAvatarSegue"]) {
        AttachmentViewController *vc = [segue destinationViewController];
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        NSURL *avatarUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, self.user.avatarUrl]];
        [vc setMediaUrl: avatarUrl];
        [vc setContentType:@"image"];
        [vc setTitle:@"Avatar"];
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Observation *observation = [self.observationDataStore observationAtIndexPath:indexPath];
        [destination setObservation:observation];
    } else if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

@end
