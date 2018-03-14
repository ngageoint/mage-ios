//
//  AttachmentViewController.m
//  Mage
//
//

#import "AttachmentViewController.h"
#import "FICImageCache.h"
#import "AppDelegate.h"
#import "MageSessionManager.h"
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface AttachmentViewController () <AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *imageActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *imageViewHolder;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *mediaHolderView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressPercentLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressBar;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;

@end

@implementation AttachmentViewController

- (instancetype) initWithMediaURL: (NSURL *) mediaURL andContentType: (NSString *) contentType andTitle: (NSString *) title {
    self = [super initWithNibName:@"AttachmentView" bundle:nil];
    if (self != nil) {
        self.mediaUrl = mediaURL;
        self.contentType = contentType;
        self.title = title;
    }
    return self;
}

- (instancetype) initWithAttachment: (Attachment *) attachment {
    self = [super initWithNibName:@"AttachmentView" bundle:nil];
    if (self != nil) {
        self.attachment = attachment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if (self.mediaUrl != nil) {
        if ([self.contentType hasPrefix:@"image"]) {
            
            [self.imageViewHolder setHidden:NO];
            [self.progressView setHidden:YES];
            [self.imageActivityIndicator setHidden:YES];
            [self.imageActivityIndicator stopAnimating];
            
            self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.mediaUrl]];
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
    
    if (self.playerViewController) {
        [self.playerViewController.player pause];
        [self.playerViewController.view removeFromSuperview];
        self.playerViewController = nil;
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
        
        [self.imageActivityIndicator startAnimating];
        
        NSInteger size = MAX(self.imageView.frame.size.height, self.imageView.frame.size.width) * [UIScreen mainScreen].scale;
    
        __weak typeof(self) weakSelf = self;
        NSURLRequest *request = [NSURLRequest requestWithURL:[self.attachment sourceURLWithSize:size]];
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

    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
        // save the local path
        NSLog(@"playing locally");
        [self.progressView setHidden:YES];
        [self playMediaType: type FromDocumentsFolder:downloadPath];
    } else {
        NSLog(@"Downloading to %@", downloadPath);
        [self.progressView setHidden:NO];
        
        __weak AttachmentViewController *weakSelf = self;
        
        MageSessionManager *manager = [MageSessionManager manager];
        NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
        
        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * downloadProgress){
            dispatch_async(dispatch_get_main_queue(), ^{;
                float progress = downloadProgress.fractionCompleted;
                weakSelf.downloadProgressBar.progress = progress;
                weakSelf.progressPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
            });
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            return [NSURL fileURLWithPath:downloadPath];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            NSString * fileString = [filePath path];
            
            if(!error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[NSFileManager defaultManager] fileExistsAtPath:fileString]){
                        [weakSelf.progressView setHidden:YES];
                        [weakSelf playMediaType: type FromDocumentsFolder:fileString];
                    }
                });
            }else{
                NSLog(@"Error: %@", error);
                //delete the file
                NSError *deleteError;
                [[NSFileManager defaultManager] removeItemAtPath:fileString error:&deleteError];
            }

        }];
        
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[downloadPath stringByDeletingLastPathComponent]]) {
            NSLog(@"Creating directory %@", [downloadPath stringByDeletingLastPathComponent]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        [manager addTask:task];
    }

}

-(void) playMediaType: (NSString *) type FromDocumentsFolder:(NSString *) fromPath {
    NSURL *url = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", url);
    
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = [AVPlayer playerWithURL:url];
    
    self.playerViewController.view.frame = self.mediaHolderView.frame;
    [self.playerViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    [self.mediaHolderView addSubview:self.playerViewController.view];
    [self.playerViewController.player play];
}

@end
