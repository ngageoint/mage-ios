//
//  MeViewController.m
//  MAGE
//
//

@import AFNetworking;

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
#import "MageServer.h"
#import "MageSessionManager.h"
#import "LocationAnnotation.h"
#import "LocationAccuracy.h"
#import "GPSLocation.h"
#import "AttachmentSelectionDelegate.h"
#import "SFGeometryUtils.h"
#import "ObservationViewController.h"
#import "Theme+UIResponder.h"
#import <HexColors/HexColor.h>
#import <mgrs/MGRS.h>

@import PhotosUI;

@interface MeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AttachmentSelectionDelegate, NSFetchedResultsControllerDelegate, ObservationSelectionDelegate, UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIView *phoneView;
@property (weak, nonatomic) IBOutlet UITextView *phoneNumber;
@property (weak, nonatomic) IBOutlet UIView *emailView;
@property (weak, nonatomic) IBOutlet UITextView *email;
@property (weak, nonatomic) IBOutlet UIView *avatarBorder;
@property (weak, nonatomic) IBOutlet UITextView *location;
@property (weak, nonatomic) IBOutlet UITextView *locationIcon;
@property (weak, nonatomic) IBOutlet UITextView *phoneIcon;
@property (weak, nonatomic) IBOutlet UITextView *emailIcon;

@property (assign, nonatomic) BOOL currentUserIsMe;
@property (nonatomic, strong) id previewingContext;
@property (nonatomic, strong) CLLocation *userLastLocation;

@end

@implementation MeViewController

- (void) themeDidChange:(MageTheme)theme {
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    self.tableView.tableHeaderView.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor background];
    self.name.textColor = [UIColor primaryText];
    self.avatar.tintColor = [UIColor inactiveIcon];
    self.avatarBorder.backgroundColor = [UIColor background];
    
    self.phoneIcon.textColor = [UIColor secondaryText];
    self.phoneIcon.font = [UIFont fontWithName:@"FontAwesome" size:15];
    self.phoneIcon.text = @"\U0000f095";
    self.emailIcon.textColor = [UIColor secondaryText];
    self.emailIcon.font = [UIFont fontWithName:@"FontAwesome" size:15];
    self.emailIcon.text = @"\U0000f0e0";
    self.locationIcon.textColor = [UIColor secondaryText];
    self.locationIcon.font = [UIFont fontWithName:@"FontAwesome" size:15];
    self.locationIcon.text = @"\U0000f0ac";
    self.location.textColor = [UIColor flatButton];
    self.email.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor flatButton]};
    self.phoneNumber.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor flatButton]};
    self.location.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor flatButton]};
    [UIColor themeMap:self.map];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationItem setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeAlways];
    } else {
        // Fallback on earlier versions
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ObservationCell" bundle:nil] forCellReuseIdentifier:@"obsCell"];
    self.observationDataStore.observationSelectionDelegate = self;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 160;
    
    if (self.user == nil) {
        self.user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        self.currentUserIsMe = YES;
    } else {
        self.currentUserIsMe = NO;
    }
    self.navigationItem.title = self.user.name;
    
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    
    [self registerForThemeChanges];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserDefaults:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mapDelegate setupListeners];
    self.name.text = self.user.name;
    
    self.phoneNumber.text = self.user.phone;
    self.phoneView.hidden = self.user.phone ? NO : YES;
    
    self.email.text = self.user.email;
    self.emailView.hidden = self.user.email ? NO : YES;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.location addGestureRecognizer:singleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(locationLongPress:)];
    [self.location addGestureRecognizer:longPress];
    
    [self.observationDataStore startFetchControllerWithObservations:[Observations observationsForUser:self.user]];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:[Observations observationsForUser:self.user]];
        Locations *locations = [Locations locationsForUser:self.user];
        [self.mapDelegate setLocations:locations];
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString* avatarFile = [documentsDirectory stringByAppendingPathComponent:self.user.avatarUrl];
    if(self.user.avatarUrl && [[NSFileManager defaultManager] fileExistsAtPath:avatarFile]) {
        self.avatar.image = [UIImage imageWithContentsOfFile:avatarFile];
    }
    
    if (self.currentUserIsMe) {
        NSArray *locations = [GPSLocation fetchLastXGPSLocations:1];
        if (locations.count != 0) {
            GPSLocation *location = [locations objectAtIndex:0];
            SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:[location getGeometry]];
            self.userLastLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue])
                                                                  altitude:[[location.properties valueForKey:@"altitude"] doubleValue]
                                                        horizontalAccuracy:[[location.properties valueForKey:@"accuracy"] doubleValue]
                                                          verticalAccuracy:[[location.properties valueForKey:@"verticalAccuracy"] doubleValue]
                                                                 timestamp:location.timestamp];
            
            [self.mapDelegate updateGPSLocation:location forUser:self.user];
        }
    }
    
    if (!self.userLastLocation) {
        NSArray *locations = [self.mapDelegate.locations.fetchedResultsController fetchedObjects];
        if ([locations count]) {
            Location *location = [locations objectAtIndex:0];
            self.userLastLocation = [[CLLocation alloc] initWithCoordinate:location.location.coordinate
                                                                  altitude:[[location.properties valueForKey:@"altitude"] doubleValue]
                                                        horizontalAccuracy:[[location.properties valueForKey:@"accuracy"] doubleValue]
                                                          verticalAccuracy:[[location.properties valueForKey:@"verticalAccuracy"] doubleValue]
                                                                 timestamp:location.timestamp];
        }
        [self.mapDelegate.locations.fetchedResultsController setDelegate:self];
    }
    

    
    if (self.userLastLocation) {
        [self zoomAndCenterMapOnLocation:self.userLastLocation];
        [self setLocationText];
     }
    
    [self sizeHeaderToFit];
}

- (void) updateUserDefaults: (NSNotification *) notification {
    [self setLocationText];
}

- (void) setLocationText {
    NSString *location = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMGRS"]) {
        location = [MGRS MGRSfromCoordinate:self.userLastLocation.coordinate];
    } else {
        location = [NSString stringWithFormat:@"%.05f, %.05f", self.userLastLocation.coordinate.latitude, self.userLastLocation.coordinate.longitude];
    }
        
    UIFont *locationFont = [UIFont systemFontOfSize:14.0f];
    UIFont *accuracyFont = [UIFont systemFontOfSize:11.0f];
    NSDictionary *locationAttributes = @{NSFontAttributeName:locationFont, NSForegroundColorAttributeName:[UIColor mageBlue]};
    NSDictionary *accuracyAttributes = @{NSFontAttributeName:accuracyFont, NSForegroundColorAttributeName:[UIColor secondaryText]};
    NSMutableAttributedString *locationText = [[NSMutableAttributedString alloc] init];
    [locationText appendAttributedString:[[NSAttributedString alloc] initWithString:location attributes:locationAttributes]];
    [locationText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  GPS +/- %f", self.userLastLocation.horizontalAccuracy] attributes:accuracyAttributes]];
    [self.location setAttributedText:locationText];
}

- (void) locationSingleTap: (id) sender {
    [self launchMapApp];
}

- (void) locationLongPress: (id) sender {
    [self launchMapApp];
}

- (NSDictionary *) getLaunchableUrls {
    NSString *appleMapsQueryString = [NSString stringWithFormat:@"ll=%f,%f&q=%@", self.userLastLocation.coordinate.latitude, self.userLastLocation.coordinate.longitude, self.user.name];
    NSString *appleMapsQueryStringEncoded = [appleMapsQueryString stringByAddingPercentEncodingWithAllowedCharacters: NSCharacterSet.URLQueryAllowedCharacterSet];
    NSURL *appleMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?%@", appleMapsQueryStringEncoded]];
    NSURL *googleMapsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/maps/dir/?api=1&destination=%f,%f", self.userLastLocation.coordinate.latitude, self.userLastLocation.coordinate.longitude]];
    
    NSMutableDictionary *urlMap = [[NSMutableDictionary alloc] init];
    [urlMap setObject:appleMapsUrl forKey:@"Apple Maps"];
    
    if ([[UIApplication sharedApplication] canOpenURL:googleMapsUrl]) {
        [urlMap setObject:googleMapsUrl forKey:@"Google Maps"];
    }
    return urlMap;
}

- (void) launchMapApp {
    NSDictionary *urlMap = [self getLaunchableUrls];
    if ([urlMap count] > 0) {
        [self presentMapsActionSheetForURLs:urlMap];
    } else {
        [[UIApplication sharedApplication] openURL:[urlMap objectForKey:@"Apple Maps"]  options:@{} completionHandler:^(BOOL success) {
            NSLog(@"opened? %d", success);
        }];
    }
}

- (void) presentMapsActionSheetForURLs: (NSDictionary *) urlMap {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Get Directions With..."
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Copy To Clipboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMGRS"]) {
            pasteboard.string = [MGRS MGRSfromCoordinate:self.userLastLocation.coordinate];
        } else {
            pasteboard.string = [NSString stringWithFormat:@"%.05f, %.05f", self.userLastLocation.coordinate.latitude, self.userLastLocation.coordinate.longitude];
        }
    }]];
    for (NSString *app in urlMap) {
        [alert addAction:[UIAlertAction actionWithTitle:app style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[urlMap valueForKey:app] options:@{} completionHandler:^(BOOL success) {
                NSLog(@"opened? %d", success);
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

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}

- (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location{
    if ([self.presentedViewController isKindOfClass:[ObservationViewController class]]) {
        return nil;
    }
    
    CGPoint cellPostion = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        ObservationTableViewCell *tableCell = (ObservationTableViewCell *)[self.tableView cellForRowAtIndexPath:path];
        
        ObservationViewController *previewController = [self.storyboard instantiateViewControllerWithIdentifier:@"observationViewerViewController"];
        previewController.observation = tableCell.observation;
        return previewController;
    }
    return nil;
}

- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
    [self.navigationController showViewController:viewControllerToCommit sender:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self isForceTouchAvailable]) {
        if (!self.previewingContext) {
            self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
        }
    } else {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}


- (void) zoomAndCenterMapOnLocation: (CLLocation *) location {
    double accuracy = location.horizontalAccuracy;
    CLLocationDistance latitudeMeters = accuracy * 2.5;  // double the radius w/ padding
    CLLocationDistance longitudeMeters = accuracy * 2.5; // double the radius w/ padding
    
    MKCoordinateRegion region = [self.map regionThatFits:MKCoordinateRegionMakeWithDistance(location.coordinate, latitudeMeters, longitudeMeters)];
    [self.mapDelegate selectedUser:self.user region:region];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSArray *locations = [self.mapDelegate.locations.fetchedResultsController fetchedObjects];
    [self.mapDelegate updateLocations: locations];
    if ([locations count]) {
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:[[locations objectAtIndex:0] getGeometry]];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[centroid.y doubleValue] longitude:[centroid.x doubleValue]];
        [self zoomAndCenterMapOnLocation:location];
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.mapDelegate cleanup];
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
    AttachmentViewController *attachmentVC = [[AttachmentViewController alloc] initWithAttachment:attachment];
    [attachmentVC setTitle:@"Attachment"];
    [self.navigationController pushViewController:attachmentVC animated:YES];
}

- (IBAction)portraitClick:(id)sender {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString* avatarFile = [documentsDirectory stringByAppendingPathComponent:self.user.avatarUrl];
    if (!self.currentUserIsMe) {
        if(self.user.avatarUrl && [[NSFileManager defaultManager] fileExistsAtPath:avatarFile]) {
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
            NSURL *avatarUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, self.user.avatarUrl]];

            AttachmentViewController *attachmentVC = [[AttachmentViewController alloc] initWithMediaURL:avatarUrl andContentType:@"image" andTitle:@"Avatar"];
            [self.navigationController pushViewController:attachmentVC animated:YES];
        }
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Avatar"
                                                                   message:@"Change or view your avatar"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"View Avatar" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        NSURL *avatarUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, self.user.avatarUrl]];
        
        AttachmentViewController *attachmentVC = [[AttachmentViewController alloc] initWithMediaURL:avatarUrl andContentType:@"image" andTitle:@"Avatar"];
        [self.navigationController pushViewController:attachmentVC animated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"New Avatar Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf checkCameraPermissionsWithCompletion:^(BOOL granted) {
            if (granted) {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = weakSelf;
                picker.allowsEditing = YES;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                
                [weakSelf presentViewController:picker animated:YES completion:NULL];
            }
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
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users/myself"];
    
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
    if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        Observation *observation = (Observation *) sender;
        [destination setObservation:observation];
    }
}

- (void) selectedObservation:(Observation *)observation {
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void) selectedObservation:(Observation *)observation region:(MKCoordinateRegion)region {
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void) observationDetailSelected:(Observation *)observation {
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

@end
