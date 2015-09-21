//
//  ImageViewerViewController.m
//  Mage
//
//

#import "ImageViewerViewController.h"
#import <FICImageCache.h>
#import "AppDelegate.h"
#import <HttpManager.h>
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface ImageViewerViewController () <AVAudioPlayerDelegate>

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *imageActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *imageViewHolder;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
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

- (NSOperationQueue *) operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return _operationQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
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
            [self.imageViewHolder setHidden:YES];
            
            NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.mediaUrl lastPathComponent]];
            [self downloadAndPlayMediaType:self.contentType fromUrl:[self.mediaUrl absoluteString] andSaveTo:tempFile];
        }
    } else if (self.attachment != nil) {
        [self showAttachment];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [self cleanup];
    }
}

- (void) cleanup {
    self.imageView.image = nil;
    [self.operationQueue cancelAllOperations];
    
    if (self.videoPlayerView) {
        [self.videoPlayerView stop];
        [self.videoPlayerView.view removeFromSuperview];
        self.videoPlayerView = nil;
    }
    
    if (self.audioPlayer) {
        [self stopAudio];
    }
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) setContent:(Attachment *)attachment {
    if (self.attachment == attachment) return;
    
    self.attachment = attachment;
    [self cleanup];
    [self showAttachment];
}

- (void) showAttachment {
    if ([self.attachment.contentType hasPrefix:@"image"]) {
        [self.imageViewHolder setHidden:NO];
        [self.progressView setHidden:YES];
        [self.audioPlayerView setHidden:YES];
        
        [self.imageActivityIndicator startAnimating];
        
        __weak typeof(self) weakSelf = self;
        NSURLRequest *request = [NSURLRequest requestWithURL:[self.attachment sourceURL]];
        [self.imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.imageView.image = image;
            [weakSelf.imageActivityIndicator stopAnimating];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            NSLog(@"Error loading observation attachment");
        }];
    } else if ([self.attachment.contentType hasPrefix:@"video"] || [self.attachment.contentType hasPrefix:@"audio"]) {
        [self.imageViewHolder setHidden:YES];
        
        [self downloadAndPlayAttachment:self.attachment];
    }
}

-(void) downloadAndPlayAttachment:(Attachment *) attachment {
    NSString *path = attachment.localPath;
    if (!path) {
        path = [[NSTemporaryDirectory() stringByAppendingPathComponent:attachment.remoteId] stringByAppendingPathComponent:attachment.name];
    }
    
    [self downloadAndPlayAttachment:attachment andSaveto:path];
}

-(void) downloadAndPlayAttachment: (Attachment *) attachment andSaveto: (NSString *) downloadPath {
    [self downloadAndPlayMediaType:attachment.contentType fromUrl:attachment.url andSaveTo:downloadPath];
}

-(void) downloadAndPlayMediaType: (NSString *) type fromUrl: (NSString *) url andSaveTo: (NSString *) downloadPath {
    HttpManager *http = [HttpManager singleton];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
        // save the local path
        NSLog(@"playing locally");
        [self.progressView setHidden:YES];
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
        
        [self.operationQueue addOperation:operation];
    }

}

-(void) playMediaType: (NSString *) type FromDocumentsFolder:(NSString *) fromPath {
    NSURL *url = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", url);
    
    if ([type hasPrefix:@"video"]) {
        self.videoPlayerView = [[MPMoviePlayerController alloc] initWithContentURL:url];
        self.videoPlayerView.view.frame = self.mediaHolderView.bounds;
        [self.videoPlayerView.view setAutoresizingMask: UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];

        self.videoPlayerView.scalingMode = MPMovieScalingModeAspectFit;
        self.videoPlayerView.initialPlaybackTime = 0.0;
        self.videoPlayerView.movieSourceType = MPMovieSourceTypeFile;
        [self.mediaHolderView addSubview:self.videoPlayerView.view];
        [self.videoPlayerView play];
    } else if ([type hasPrefix:@"audio"]) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        self.audioPlayer.delegate = self;
        [self.audioPlayer setVolume:1.0];
        self.audioPlayer.numberOfLoops = 0;
        
        NSTimeInterval totalSeconds = self.audioPlayer.duration;
        
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
    self.audioPlayer.playing ? [self stopAudio] : [self playAudio];
}

- (void) stopAudio {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
    
    [self.audioPlayButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [self updateSlider];
    [self.sliderTimer invalidate];
}

- (void) playAudio {
    if (self.sliderTimer != nil && self.sliderTimer.isValid) {
        [self.sliderTimer invalidate];
    }
    
    // Set a timer which keep getting the current music time and update the UISlider in 1 sec interval
    _sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    // Set the maximum value of the UISlider
    self.audioProgressSlider.maximumValue = self.audioPlayer.duration;
    // Set the valueChanged target
    
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    [self.audioPlayButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void)updateSlider {
    // Update the slider about the music time
    self.audioProgressSlider.value = self.audioPlayer.currentTime;
}

- (IBAction)sliderStartChange:(id)sender {
    [self.audioPlayer stop];
    [self.sliderTimer invalidate];
}

- (IBAction)sliderChanged:(UISlider *)sender {
    // Fast skip the music when user scroll the UISlider
    [self.audioPlayer stop];
    [self.audioPlayer setCurrentTime:self.audioProgressSlider.value];
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
