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
#import <MageSessionManager.h>
#import "LocationAnnotation.h"
#import "GPSLocation.h"
#import <GeoPoint.h>
#import "AttachmentSelectionDelegate.h"

@import PhotosUI;

@interface MeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AttachmentSelectionDelegate>

@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIView *phoneView;
@property (weak, nonatomic) IBOutlet UITextView *phoneNumber;
@property (weak, nonatomic) IBOutlet UIView *emailView;
@property (weak, nonatomic) IBOutlet UITextView *email;

@property (assign, nonatomic) BOOL currentUserIsMe;

@end

@implementation MeViewController


- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 160;
    
    if (self.user == nil) {
        self.user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        self.currentUserIsMe = YES;
        self.navigationItem.title = @"Me";
    } else {
        self.currentUserIsMe = NO;
        self.navigationItem.title = self.user.name;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.name.text = self.user.name;
    
    self.phoneNumber.text = self.user.phone;
    self.phoneView.hidden = self.user.phone ? NO : YES;
    
    self.email.text = self.user.email;
    self.emailView.hidden = self.user.email ? NO : YES;
    
    [self.observationDataStore startFetchControllerWithObservations:[Observations observationsForUser:self.user]];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:[Observations observationsForUser:self.user]];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        Locations *locations = [Locations locationsForUser:self.user];
        [self.mapDelegate setLocations:locations];
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString* avatarFile = [documentsDirectory stringByAppendingPathComponent:self.user.avatarUrl];
    if(self.user.avatarUrl && [[NSFileManager defaultManager] fileExistsAtPath:avatarFile]) {
        self.avatar.image = [UIImage imageWithContentsOfFile:avatarFile];
    }
    
    CLLocation *location = nil;
    if (self.currentUserIsMe) {
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
    
    [self sizeHeaderToFit];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // TODO make sure callback stop when I am not on this view
    self.observationDataStore.observations.delegate = nil;
}

- (void) sizeHeaderToFit {
    UIView *headerView = self.tableView.tableHeaderView;
    
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
    
    CGSize size = [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    CGRect frame = [headerView frame];
    frame.size.height = size.height;
    [headerView setFrame:frame];    
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
    
    if (self.currentUserIsMe) {
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

    MageSessionManager *manager = [MageSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", [MageServer baseURL], @"api/users", self.user.remoteId];
    
    NSMutableURLRequest *request = [[manager httpRequestSerializer] multipartFormRequestWithMethod:@"PUT" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"avatar" fileName:@"avatar.jpeg" mimeType:@"image/jpeg"];
    } error:nil];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
    }];
    
    [manager addTask:uploadTask];
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
