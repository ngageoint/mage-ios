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
#import <AVFoundation/AVFoundation.h>

@interface ImageViewerViewController () <AVAudioPlayerDelegate>

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) BOOL shouldHideNavBar;
@property (weak, nonatomic) IBOutlet UIView *mediaHolderView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressPercentLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressBar;
@property (strong, nonatomic) MPMoviePlayerController *videoPlayerView;
@property (weak, nonatomic) IBOutlet UIView *audioPlayerView;
@property (weak, nonatomic) IBOutlet UILabel *audioLength;
@property (weak, nonatomic) IBOutlet UIButton *audioPlayButton;
@property (weak, nonatomic) IBOutlet UISlider *audioProgressSlider;
@property (strong, nonatomic) NSTimer *sliderTimer;

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
            [self.progressView setHidden:YES];
            [self.audioPlayerView setHidden:YES];
            self.imageView = [[UIImageView alloc] init];
            self.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.mediaHolderView addSubview:self.imageView];
            
            self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.mediaUrl]];
            self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
            self.imageView.clipsToBounds = YES;

        } else if ([self.contentType hasPrefix:@"video"] || [self.contentType hasPrefix:@"audio"]) {
            NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.mediaUrl lastPathComponent]];
            [self downloadAndPlayMediaType:self.contentType fromUrl:[self.mediaUrl absoluteString] andSaveTo:tempFile];
        }
    } else if (self.attachment != nil) {
        
        if ([self.attachment.contentType hasPrefix:@"image"]) {
            [self.progressView setHidden:YES];
            [self.audioPlayerView setHidden:YES];
            self.imageView = [[UIImageView alloc] init];
            self.imageView.contentMode = UIViewContentModeScaleAspectFit;
            self.imageView.frame = self.mediaHolderView.frame;
            
            [self.mediaHolderView addSubview:self.imageView];
            FICImageCacheCompletionBlock completionBlock = ^(id <FICEntity> entity, NSString *formatName, UIImage *image) {
                self.imageView.image = image;
                self.imageView.clipsToBounds = YES;
                self.imageView.contentMode = UIViewContentModeScaleAspectFit;
            };
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            BOOL imageExists = [delegate.imageCache retrieveImageForEntity:[self attachment] withFormatName:AttachmentLarge completionBlock:completionBlock];
            
            if (imageExists == NO) {
                self.imageView.image = [UIImage imageNamed:@"download"];
            }
        } else if ([self.attachment.contentType hasPrefix:@"video"] || [self.attachment.contentType hasPrefix:@"audio"]) {
            [self downloadAndPlayAttachment:self.attachment];
        }
    }
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.imageView != nil) {
        [self.imageView setFrame:self.mediaHolderView.frame];
    } else if (self.videoPlayerView != nil) {
        self.videoPlayerView.view.frame = self.mediaHolderView.frame;
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
    [self downloadAndPlayAttachment: attachment andSaveto:downloadPath];
}

-(void) downloadAndPlayAttachment: (Attachment *) attachment andSaveto: (NSString *) downloadPath {
    [self downloadAndPlayMediaType:attachment.contentType fromUrl:attachment.url andSaveTo:downloadPath];
}

-(void) downloadAndPlayMediaType: (NSString *) type fromUrl: (NSString *) url andSaveTo: (NSString *) downloadPath {
    HttpManager *http = [HttpManager singleton];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
        // save the local path
        NSLog(@"playing locally");
        [self playMediaType: type FromDocumentsFolder:downloadPath];
    } else {
        NSLog(@"Downloading to %@", downloadPath);
        [self.progressView setHidden:NO];
        
        NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
        __weak ImageViewerViewController *weakSelf = self;
        AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]){
                    [weakSelf.progressView setHidden:YES];
                    [weakSelf playMediaType: type FromDocumentsFolder:downloadPath];
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

-(void) playMediaType: (NSString *) type FromDocumentsFolder:(NSString *) fromPath{
    NSURL *url = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", url);
    
    if ([type hasPrefix:@"video"]) {
        self.videoPlayerView = [[MPMoviePlayerController alloc] initWithContentURL:url];
        
        self.videoPlayerView.view.frame = self.mediaHolderView.frame;
        self.videoPlayerView.scalingMode = MPMovieScalingModeAspectFit;
        self.videoPlayerView.initialPlaybackTime = 0.0;
        self.videoPlayerView.movieSourceType = MPMovieSourceTypeFile;
        [self.mediaHolderView addSubview:self.videoPlayerView.view];
        [self.videoPlayerView play];
    } else if ([type hasPrefix:@"audio"]) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        NSError *error;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        _audioPlayer.delegate = self;
        [_audioPlayer setVolume:1.0];
        _audioPlayer.numberOfLoops = 0;
        
        NSTimeInterval totalSeconds = _audioPlayer.duration;
        
        int seconds = (int)totalSeconds % 60;
        int minutes = ((int)totalSeconds / 60) % 60;
        int hours = totalSeconds / 3600;
        NSLog(@"starting to play the sound from url %@ duration seconds %f", url, totalSeconds);
        
        self.audioLength.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
        
        [self.audioPlayerView setHidden:NO];

        [self playAudio];
    }
}

- (IBAction)playButtonPressed:(id)sender {
    if (_audioPlayer.playing) {
        [self stopAudio];
    } else {
        [self playAudio];
    }
}

- (void) stopAudio {
    if (_audioPlayer.isPlaying) {
        [_audioPlayer stop];
    }
    [self.audioPlayButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [self updateSlider];
    [_sliderTimer invalidate];
}

- (void) playAudio {
    if (_sliderTimer != nil && _sliderTimer.isValid) {
        [_sliderTimer invalidate];
    }
    // Set a timer which keep getting the current music time and update the UISlider in 1 sec interval
    _sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    // Set the maximum value of the UISlider
    self.audioProgressSlider.maximumValue = _audioPlayer.duration;
    // Set the valueChanged target
    
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    [self.audioPlayButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void)updateSlider {
    // Update the slider about the music time
    self.audioProgressSlider.value = _audioPlayer.currentTime;
}

- (IBAction)sliderStartChange:(id)sender {
    [_audioPlayer stop];
    [_sliderTimer invalidate];
}

- (IBAction)sliderChanged:(UISlider *)sender {
    // Fast skip the music when user scroll the UISlider
    [_audioPlayer stop];
    [_audioPlayer setCurrentTime:self.audioProgressSlider.value];
    [self playAudio];
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"played the sound");
    [self stopAudio];
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Error playing the sound");
    [self stopAudio];
}

@end
