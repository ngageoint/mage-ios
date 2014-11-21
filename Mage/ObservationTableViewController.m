//
//  ObservationsViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationTableViewController.h"
#import "ObservationTableViewCell.h"
#import <Observation.h>
#import "ObservationViewController.h"
#import "MageRootViewController.h"
#import "AttachmentSelectionDelegate.h"
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AFNetworking/AFNetworking.h>
#import <HttpManager.h>
#import "ImageViewerViewController.h"

@interface ObservationTableViewController () <AttachmentSelectionDelegate>
@property(nonatomic, strong) IBOutlet UIRefreshControl *refreshControl;
@end

@implementation ObservationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.observationDataStore startFetchController];
    
    [self.refreshControl addTarget:self
                            action:@selector(refreshObservations)
                  forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
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

-(void) refreshObservations {
    NSLog(@"refreshObservations");
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


@end
