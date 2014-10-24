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

@interface MeViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *username;

@end

@implementation MeViewController

- (void) viewDidLoad {
    
    if (self.user == nil) {
        self.user = [User fetchCurrentUserForManagedObjectContext: self.contextHolder.managedObjectContext];
    }
    
    self.name.text = self.user.name;
    self.username.text = self.user.username;
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];

    [self.avatar setImage:[UIImage imageWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults objectForKey:@"token"]]]]]];
    
    Locations *locations = [Locations locationsForUser:self.user inManagedObjectContext:self.contextHolder.managedObjectContext];
    [self.mapDelegate setLocations:locations];
    
    Observations *observations = [Observations observationsForUser:self.user inManagedObjectContext:self.contextHolder.managedObjectContext];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    [self.mapDelegate setObservations:observations];
}

- (IBAction)portraitClick:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Avatar", @"Take New Avatar Photo", @"Choose Avatar From Library", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            // view avatar
            NSLog(@"view avatar");
            [self performSegueWithIdentifier:@"viewImageSegue" sender:self];
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
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    NSURLSessionUploadTask *uploadTask = [manager.sessionManager uploadTaskWithRequest:request fromData:UIImagePNGRepresentation(image) progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
//        if (error) {
//            NSLog(@"Error: %@", error);
//        } else {
//            NSLog(@"Success: %@ %@", response, responseObject);
//        }
//    }];
//    [uploadTask resume];
    
    
    
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
    
//    CLLocationDistance latitudeMeters = 500;
//    CLLocationDistance longitudeMeters = 500;
//    NSDictionary *properties = self.user.location.properties;
//    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
//    if (accuracyProperty != nil) {
//        double accuracy = [accuracyProperty doubleValue];
//        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
//        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
//    }
//    
//    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([self.user.location location].coordinate, latitudeMeters, longitudeMeters);
//    MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
//    
//    [self.mapDelegate selectedUser:self.user region:viewRegion];
}

- (IBAction)dismissMe:(id)sender {
    NSLog(@"Done");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        ImageViewerViewController *vc = [segue destinationViewController];
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        [vc setImageUrl: [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults objectForKey:@"token"]]]];
        
    }
}

@end
