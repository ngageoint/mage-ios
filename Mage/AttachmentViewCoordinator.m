//
//  AttachmentViewCoordinator.m
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AttachmentViewCoordinator.h"
#import "DataConnectionUtilities.h"
#import "AttachmentViewController.h"
#import "FadeTransitionSegue.h"
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "StoredPassword.h"
#import "MAGE-Swift.h"

@interface AttachmentViewCoordinator() <NSURLConnectionDataDelegate, AVAssetResourceLoaderDelegate, UINavigationControllerDelegate, NavigationControllerObserverDelegate>

@property (strong, nonatomic) UINavigationController *rootViewController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) NavigationControllerObserver *navigationControllerObserver;
@property (strong, nonatomic) id<AttachmentViewDelegate> delegate;
@property (strong, nonatomic) Attachment *attachment;
@property (strong, nonatomic) NSMutableArray *pendingRequests;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@property (strong, nonatomic) NSString *tempFile;
@property (nonatomic, assign) NSUInteger fullAudioDataLength;
@property (nonatomic, strong) NSURL *urlToLoad;

@end

@implementation AttachmentViewCoordinator

- (instancetype) initWithNavigationController: (UINavigationController *) rootViewController andDelegate: (id<AttachmentViewDelegate>) delegate andAttachment: (Attachment *) attachment {
    self = [super init];
    if (!self) return nil;
    
    _rootViewController = rootViewController;
    
    _delegate = delegate;
    _attachment = attachment;
    
    self.tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.attachment.url lastPathComponent]];
    self.navigationController = rootViewController;
    self.navigationControllerObserver = [[NavigationControllerObserver alloc] initWithNavigationController:self.navigationController];
    
    return self;
}

- (void) start {
//    self.navigationController.navigationItem.backBarButtonItem.title = self.rootViewController.title;
//    [self.navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
//    [self.rootViewController presentViewController:self.navigationController animated:YES completion:nil];
//    [self.rootViewController pushViewController: self.navigationController animated:YES];
    if (![DataConnectionUtilities shouldFetchAttachments] && !self.attachment.localPath && ![[NSFileManager defaultManager] fileExistsAtPath:self.tempFile]) {
        AskToDownloadViewController *vc = [[AskToDownloadViewController alloc] initWithAttachment:self.attachment delegate:self];
        [_navigationController pushViewController:vc animated:YES];
        [self.navigationControllerObserver observePopTransitionOf:vc delegate:self];
        return;
    } else {
        if ([self.attachment.contentType hasPrefix:@"image"]) {
            ImageAttachmentViewController *ac = [[ImageAttachmentViewController alloc] initWithAttachment:self.attachment];
            ac.view.backgroundColor = [UIColor blackColor];
            [_navigationController pushViewController:ac animated:YES];
        } else if ([self.attachment.contentType hasPrefix:@"video"] || [self.attachment.contentType hasPrefix:@"audio"]) {
            [self downloadAudioVideo];
        }
    }
    
}

- (void) navigationControllerObserver:(NavigationControllerObserver *)observer didObservePopTransitionFor:(UIViewController *)viewController {
    // this gets called on the back button
    NSLog(@"pop %@", viewController);
    [self.delegate doneViewing:self];
}

- (void) navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSLog(@"There are %ld view controllers", [self.navigationController.viewControllers count]);
    if ([navigationController.viewControllers count] == 0) {
        [self.delegate doneViewing:self];
    }
}

- (void) downloadAttachment {
    // proceed to the attachment downloading view
    NSLog(@"Download the attachment");
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];

    [_navigationController popViewControllerAnimated:NO];
    
    if ([self.attachment.contentType hasPrefix:@"image"]) {
        ImageAttachmentViewController *ac = [[ImageAttachmentViewController alloc] initWithAttachment:self.attachment];
        [_navigationController pushViewController:ac animated:NO];
    } else if ([self.attachment.contentType hasPrefix:@"video"] || [self.attachment.contentType hasPrefix:@"audio"]) {
        [self downloadAudioVideo];
    }
}

- (void) downloadAudioVideo {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.attachment.localPath]) {
        // save the local path
        NSLog(@"playing locally");
        return [self playMediaType:self.attachment.contentType FromDocumentsFolder:self.attachment.localPath];
    }
    NSString *urlString = [NSString stringWithFormat: @"%@?access_token=%@", self.attachment.url, [StoredPassword retrieveStoredToken]];
    NSURL *url = [NSURL URLWithString:urlString];
    self.urlToLoad = url;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:components.URL options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    // This tracks all pending AVAssetResourceLoadingRequest objects we have not fulfilled yet
    self.pendingRequests = [NSMutableArray array];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = self.player;
    [self.playerViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [_navigationController pushViewController:self.playerViewController animated:NO];
    [self.navigationControllerObserver observePopTransitionOf:self.playerViewController delegate:self];
}

-(void) playMediaType: (NSString *) type FromDocumentsFolder:(NSString *) fromPath {
    NSURL *url = [NSURL fileURLWithPath:fromPath];
    NSLog(@"Playing %@", url);
    self.urlToLoad = url;
//    self.playerViewController = [[AVPlayerViewController alloc] init];
//    self.playerViewController.player = [AVPlayer playerWithURL:url];
//
//    [self.playerViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
//    [_navigationController pushViewController:self.playerViewController animated:NO];
//    [self.navigationControllerObserver observePopTransitionOf:self.playerViewController delegate:self];
//
//    [self.playerViewController.player play];
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:components.URL options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    // This tracks all pending AVAssetResourceLoadingRequest objects we have not fulfilled yet
    self.pendingRequests = [NSMutableArray array];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.player = self.player;
    [self.playerViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [_navigationController pushViewController:self.playerViewController animated:NO];
    [self.navigationControllerObserver observePopTransitionOf:self.playerViewController delegate:self];
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.fullAudioDataLength = 0;
    self.response = (NSHTTPURLResponse *)response;
    
    [self processPendingRequests];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    self.fullAudioDataLength += data.length;
    [self appendDataToTempFile: data];
    
    [self processPendingRequests];
}

- (void)appendDataToTempFile:(NSData *)data
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.tempFile]) {
        [data writeToFile:self.tempFile atomically:YES];
//        [data writeToURL:url atomically:YES];
//        [FileUtils saveData:data toURL:self.tempURL];
    } else {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFile];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finished loading the media file");
    // save it and set the local path of the attachment
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Attachment *localAttachment = [self.attachment MR_inContext:localContext];
        localAttachment.localPath = self.tempFile;
    }];
    [self processPendingRequests];
}

#pragma mark - AVURLAsset resource loading

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];
        
        if (didRespondCompletely)
        {
            [requestsCompleted addObject:loadingRequest];
            
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (contentInformationRequest == nil || self.response == nil)
    {
        return;
    }
    
    NSString *mimeType = [self.response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.response expectedContentLength];
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    // Don't have any data at all for this request
    if (self.fullAudioDataLength < startOffset)
    {
        return NO;
    }
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = self.fullAudioDataLength - (NSUInteger)startOffset;
    
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
    NSRange range = NSMakeRange((NSUInteger)startOffset, numberOfBytesToRespondWith);
    NSData *subData = [self dataFromFileInRange:range];
    [dataRequest respondWithData:subData];
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = self.fullAudioDataLength >= endOffset;
    
    return didRespondFully;
}

- (NSData *)dataFromFileInRange:(NSRange)range
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.tempFile];;
    [fileHandle seekToFileOffset:range.location];
    return [fileHandle readDataOfLength:range.length];
}


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if (self.connection == nil)
    {
        NSURL *interceptedURL = [loadingRequest.request URL];
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:interceptedURL resolvingAgainstBaseURL:NO];
        NSURLComponents *loadingComponents = [[NSURLComponents alloc] initWithURL:self.urlToLoad resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = loadingComponents.scheme;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[actualURLComponents URL]];
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
        
        [self.connection start];
    }
    
    [self.pendingRequests addObject:loadingRequest];
    [self processPendingRequests];
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.pendingRequests removeObject:loadingRequest];
}

#pragma KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay)
    {
        [self.player play];
    }
}
@end
