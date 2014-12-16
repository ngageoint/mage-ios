//
//  ImageViewerViewController.m
//  Mage
//
//  Created by Dan Barela on 8/13/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ImageViewerViewController.h"
#import <FICImageCache.h>
#import "AppDelegate.h"
#import <HttpManager.h>
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ImageViewerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) BOOL shouldHideNavBar;
@property (weak, nonatomic) IBOutlet UIView *mediaHolderView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressPercentLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressBar;
@property (strong, nonatomic) MPMoviePlayerController *videoPlayerView;

@end

@implementation ImageViewerViewController

bool originalNavBarHidden;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.mediaUrl != nil) {
        if ([self.contentType hasPrefix:@"image"]) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.mediaHolderView.frame];
            [self.mediaHolderView addSubview:imageView];
            
            imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.mediaUrl]];
        } else if ([self.contentType hasPrefix:@"video"]) {
            NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.mediaUrl lastPathComponent]];
            [self downloadAndPlayMovieFrom:[self.mediaUrl absoluteString] andSaveto:tempFile];
        } else if ([self.contentType hasPrefix:@"audio"]) {
//            NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.mediaUrl lastPathComponent]];
//            [self downloadAndPlayMovieFrom:[self.mediaUrl absoluteString] andSaveto:tempFile];
        }
    } else if (self.attachment != nil) {
        
        if ([self.attachment.contentType hasPrefix:@"image"]) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.mediaHolderView.frame];
            [self.mediaHolderView addSubview:imageView];
            FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
                imageView.image = image;
            };
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            BOOL imageExists = [delegate.imageCache retrieveImageForEntity:[self attachment] withFormatName:AttachmentLarge completionBlock:completionBlock];
            
            if (imageExists == NO) {
                imageView.image = [UIImage imageNamed:@"download"];
            }
        } else if ([self.attachment.contentType hasPrefix:@"video"]) {
            [self downloadAndPlayAttachment:self.attachment];
        } else if ([self.attachment.contentType hasPrefix:@"audio"]) {
//            [self downloadAndPlayAttachment:self.attachment];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    originalNavBarHidden = [self.navigationController isNavigationBarHidden];
    [self.navigationController setNavigationBarHidden:_shouldHideNavBar animated:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:originalNavBarHidden animated:animated];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void) downloadAndPlayAttachment:(Attachment *) attachment{
    NSString *downloadPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:attachment.remoteId] stringByAppendingPathComponent:attachment.name];
    [self downloadAndPlayMovieFrom:attachment.url andSaveto:downloadPath];
}

-(void) downloadAndPlayMovieFrom: (NSString *) url andSaveto: (NSString *) downloadPath {
    HttpManager *http = [HttpManager singleton];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
        // save the local path
        NSLog(@"playing locally");
        [self playMediaFromDocumentsFolder:downloadPath];
    } else {
        NSLog(@"Downloading to %@", downloadPath);
        [self.progressView setHidden:NO];
        
        NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
        __weak ImageViewerViewController *weakSelf = self;
        AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
                    [weakSelf.progressView setHidden:YES];
                    [weakSelf playMediaFromDocumentsFolder:downloadPath];
                }
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            //delete the file
            NSError *deleteError;
            [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:&deleteError];
        }];
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[downloadPath stringByDeletingLastPathComponent]]) {
            NSLog(@"Creating directory %@", [downloadPath stringByDeletingLastPathComponent]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
        operation.responseSerializer = [AFHTTPResponseSerializer serializer];
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadPath append:NO];
        
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            dispatch_async(dispatch_get_main_queue(), ^{
                float progress = (float)totalBytesRead / totalBytesExpectedToRead;
                weakSelf.downloadProgressBar.progress = progress;
                weakSelf.progressPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
            });
        }];
        
        [operation start];
    }

}

-(void) playMediaFromDocumentsFolder:(NSString *) fromPath{
    NSURL *fURL = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", fURL);
    self.videoPlayerView = [[MPMoviePlayerController alloc] initWithContentURL:fURL];
    
    self.videoPlayerView.view.frame = self.mediaHolderView.frame;
    self.videoPlayerView.scalingMode = MPMovieScalingModeAspectFit;
    self.videoPlayerView.initialPlaybackTime = 0.0;
    self.videoPlayerView.movieSourceType = MPMovieSourceTypeFile;
    [self.mediaHolderView addSubview:self.videoPlayerView.view];
    [self.videoPlayerView play];
}

@end
