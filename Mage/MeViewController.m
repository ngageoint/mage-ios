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
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
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
        self.user = [User fetchCurrentUser];
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
    if ([attachment.contentType hasPrefix:@"image"]) {
        [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
    } else if ([attachment.contentType hasPrefix:@"video"]) {
        [self downloadAndSaveMediaToTempFolder:attachment];
    } else if ([attachment.contentType hasPrefix:@"audio"]) {
        [self downloadAndSaveMediaToTempFolder:attachment];
    }
}


#pragma mark - Download Media to TMP directory
-(void) downloadAndSaveMediaToTempFolder:(Attachment *) attachment{
    HttpManager *http = [HttpManager singleton];
    Observation *obs = (Observation *)attachment.observation;
    
    NSString *downloadPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:attachment.remoteId] stringByAppendingPathComponent:attachment.name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
        // save the local path
        NSLog(@"playing locally");
        [self playMediaFromDocumentsFolder:downloadPath];
    } else {
        NSLog(@"Downloading to %@", downloadPath);
        NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:attachment.url parameters: nil error: nil];
        AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
                // save the local path
                [self playMediaFromDocumentsFolder:downloadPath];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            
        }];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[downloadPath stringByDeletingLastPathComponent]]) {
            NSLog(@"Creating directory %@", [downloadPath stringByDeletingLastPathComponent]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
        operation.responseSerializer = [AFHTTPResponseSerializer serializer];
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadPath append:NO];
        [operation start];
    }
}


//NSNotification callback function
- (void)moviePlayerPlaybackStateDidChange:(NSNotification*)notification {
    MPMoviePlayerController *moviePlayer = notification.object;
    
    MPMoviePlaybackState playbackState = moviePlayer.playbackState;
    
    if(playbackState == MPMoviePlaybackStateStopped) {
        NSLog(@"MPMoviePlaybackStateStopped");
    } else if(playbackState == MPMoviePlaybackStatePlaying) {
        NSLog(@"MPMoviePlaybackStatePlaying");
    } else if(playbackState == MPMoviePlaybackStatePaused) {
        NSLog(@"MPMoviePlaybackStatePaused");
    } else if(playbackState == MPMoviePlaybackStateInterrupted) {
        NSLog(@"MPMoviePlaybackStateInterrupted");
    } else if(playbackState == MPMoviePlaybackStateSeekingForward) {
        NSLog(@"MPMoviePlaybackStateSeekingForward");
    } else if(playbackState == MPMoviePlaybackStateSeekingBackward) {
        NSLog(@"MPMoviePlaybackStateSeekingBackward");
    }
}

-(void) playMediaFromDocumentsFolder:(NSString *) fromPath{
    NSURL *fURL = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", fURL);
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:fURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(moviePlayerPlaybackStateDidChange:)  name:MPMoviePlayerPlaybackStateDidChangeNotification  object:nil];
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    videoPlayerView.moviePlayer.view.frame = self.view.frame;
    videoPlayerView.moviePlayer.initialPlaybackTime = 0.0;
    videoPlayerView.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    [videoPlayerView.moviePlayer prepareToPlay];
    [videoPlayerView.moviePlayer play];
}

-(void) playMovieAtURL: (NSURL*) theURL {
    
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL:theURL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(moviePlayerPlaybackStateDidChange:)  name:MPMoviePlayerPlaybackStateDidChangeNotification  object:nil];
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    videoPlayerView.moviePlayer.view.frame = self.view.frame;
    videoPlayerView.moviePlayer.initialPlaybackTime = 0.0;
    videoPlayerView.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [videoPlayerView.moviePlayer prepareToPlay];
    [videoPlayerView.moviePlayer play];
}

// When the movie is done, release the controller.
-(void) myMovieFinishedCallback: (NSNotification*) aNotification
{
    MPMoviePlayerController* theMovie = [aNotification object];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: MPMoviePlayerPlaybackDidFinishNotification
     object: theMovie];
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
        [vc setImageUrl: [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults valueForKeyPath:@"loginParameters.token"]]]];
        
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
