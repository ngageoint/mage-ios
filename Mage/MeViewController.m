//
//  MeViewController.m
//  MAGE
//
//

#import "MeViewController.h"
#import "UIImage+Resize.h"
#import "ManagedObjectContextHolder.h"
#import "Observations.h"
#import <User+helper.h>
#import <MapKit/MapKit.h>
#import "Locations.h"
#import "MapDelegate.h"
#import <Location+helper.h>
#import "ObservationDataStore.h"
#import "ImageViewerViewController.h"
#import <AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <MageServer.h>
#import <HttpManager.h>
#import "LocationAnnotation.h"
#import <GPSLocation+helper.h>
#import <GeoPoint.h>
#import "AttachmentSelectionDelegate.h"
#import "Attachment+FICAttachment.h"

@interface MeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AttachmentSelectionDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UILabel *name;
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
        self.title = self.user.name;
    }
    self.name.text = self.user.name;
    self.name.layer.shadowColor = [[UIColor blackColor] CGColor];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    
    self.avatar.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, self.user.avatarUrl]];
    
    Observations *observations = [Observations observationsForUser:self.user];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:observations];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        Locations *locations = [Locations locationsForUser:self.user];
        [self.mapDelegate setLocations:locations];
    }
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (IBAction)portraitClick:(id)sender {
    // Returning for right now to fix split view controller strangeness
    return;
    /*
    
    UIActionSheet *actionSheet = nil;
    
    // have to do it this way to keep the cancel button on the bottom
    if (currentUserIsMe) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Avatar", @"Take New Avatar Photo", @"Choose Avatar From Library", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Avatar", nil];
    }
    
    [actionSheet showInView:self.view];
     */
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            // view avatar
            NSLog(@"view avatar");
            [self performSegueWithIdentifier:@"viewAvatarSegue" sender:self];
            break;
        }
        case 1: {
            // change avatar
            NSLog(@"take avatar picture");
            
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
            break;
        }
        case 2: {
            NSLog(@"choose avatar from library");
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            [self presentViewController:picker animated:YES completion:NULL];
            break;
        }
        default: {
            break;
        }
    }
}

- (void) uploadAvatar: (UIImage *)image {
    
    HttpManager *manager = [HttpManager singleton];
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@", [MageServer baseURL], @"api/users", self.user.remoteId];
    
    NSMutableURLRequest *request = [manager.sessionManager.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImagePNGRepresentation(image) name:@"avatar" fileName:@"avatar.png" mimeType:@"image/png"];
    } error:nil];
    // not sure why the HTTPRequestHeaders are not being set, so set them here
    [manager.sessionManager.requestSerializer.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [request setValue:value forHTTPHeaderField:field];
        }
    }];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.avatar.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self uploadAvatar:chosenImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (currentUserIsMe) {
        NSArray *lastLocation = [GPSLocation fetchLastXGPSLocations:1];
        if (lastLocation.count != 0) {
            GPSLocation *gpsLocation = [lastLocation objectAtIndex:0];
            [self.mapDelegate updateGPSLocation:gpsLocation forUser:self.user andCenter: YES];
        }
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"viewAvatarSegue"]) {
        ImageViewerViewController *vc = [segue destinationViewController];
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
        NSURL *avatarUrl = [NSURL URLWithString: [NSString stringWithFormat:@"%@/%@", documentsDirectory, self.user.avatarUrl]];
        [vc setMediaUrl: avatarUrl];
        [vc setContentType:@"image"];
        [vc setTitle:@"Avatar"];
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Observation *observation = [self.observationDataStore observationAtIndexPath:indexPath];
        [destination setObservation:observation];
    } else if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        ImageViewerViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

@end
