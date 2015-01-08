//
//  MeViewController.m
//  MAGE
//
//  Created by Dan Barela on 10/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
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
#import <MageServer.h>
#import <HttpManager.h>
#import "LocationAnnotation.h"
#import <GPSLocation+helper.h>
#import "PersonImage.h"
#import <GeoPoint.h>
#import "AttachmentSelectionDelegate.h"
#import "Attachment+FICAttachment.h"

@interface MeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AttachmentSelectionDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL shouldHideNavBar;

@end

@implementation MeViewController

bool originalNavBarHidden;
bool currentUserIsMe = NO;

- (void) viewDidLoad {
    
    if (self.user == nil) {
        self.user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
        currentUserIsMe = YES;
    }
    
    self.name.text = self.user.name;
    self.name.layer.shadowColor = [[UIColor blackColor] CGColor];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    UIImage *avatarImage = [UIImage imageWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults valueForKeyPath:@"loginParameters.token"]]]]];
    if (avatarImage != nil) {
        [self.avatar setImage:avatarImage];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults valueForKeyPath:@"loginParameters.token"]];
    NSLog(@"url is: %@", url);
    [self.avatar setImage:[UIImage imageWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults valueForKeyPath:@"loginParameters.token"]]]]]];
    
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
    
    UIActionSheet *actionSheet = nil;
    
    // have to do it this way to keep the cancel button on the bottom
    if (currentUserIsMe) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Avatar", @"Take New Avatar Photo", @"Choose Avatar From Library", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Avatar", nil];
    }
    
    [actionSheet showInView:self.view];
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
    originalNavBarHidden = [self.navigationController isNavigationBarHidden];
    [self.navigationController setNavigationBarHidden:_shouldHideNavBar animated:animated];
    
    CLLocationDistance latitudeMeters = 500;
    CLLocationDistance longitudeMeters = 500;
    NSDictionary *properties = _user.location.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    if (currentUserIsMe) {
        NSArray *lastLocation = [GPSLocation fetchLastXGPSLocations:1];
        if (lastLocation.count != 0) {
            GPSLocation *gpsLocation = [lastLocation objectAtIndex:0];
            [self.mapDelegate updateGPSLocation:gpsLocation forUser:self.user andCenter: YES];
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:originalNavBarHidden animated:animated];
}

- (IBAction)dismissMe:(id)sender {
    NSLog(@"Done");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"viewAvatarSegue"]) {
        ImageViewerViewController *vc = [segue destinationViewController];
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        [vc setMediaUrl: [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults valueForKeyPath:@"loginParameters.token"]]]];
        [vc setContentType:@"image"];
        
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Observation *observation = [self.observationDataStore observationAtIndexPath:indexPath];
        [destination setObservation:observation];
    } else if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        [vc setAttachment:sender];
    }
}

@end
