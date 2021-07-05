//
//  MediaLoader.m
//  MAGE
//
//  Created by Daniel Barela on 4/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MediaLoader.h"
#import "MageSessionManager.h"

@interface MediaLoader() <NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSMutableArray *pendingRequests;
@property (strong, nonatomic) NSURLConnection *connection;
@property (nonatomic, strong) NSURLResponse *response;
@property (strong, nonatomic) NSString *tempFile;
@property (nonatomic, assign) NSUInteger fullAudioDataLength;
@property (nonatomic, strong) NSURL *urlToLoad;
@property (nonatomic, strong) id<MediaLoaderDelegate> delegate;
@property (strong, nonatomic) NSString *existingFile;
@property (strong, nonatomic) NSString *mimeExtension;
@property (strong, nonatomic) NSString *finalFile;
@property (nonatomic) BOOL localFile;

@property (strong, nonatomic) NSURLSessionDataTask *task;

@end

@implementation MediaLoader

- (instancetype) initWithDelegate: (id<MediaLoaderDelegate>) delegate {
    self.delegate = delegate;
    return self;
}

- (instancetype) initWithUrlToLoad: (NSURL *) urlToLoad andTempFile: (NSString *) tempFile andDelegate: (id<MediaLoaderDelegate>) delegate {
    self.urlToLoad = urlToLoad;
    self.tempFile = tempFile;
    self.finalFile = tempFile;
    self.delegate = delegate;
    // This tracks all pending AVAssetResourceLoadingRequest objects we have not fulfilled yet
    self.pendingRequests = [NSMutableArray array];
    return self;
}

#pragma mark - Audio Download

- (void) downloadAudioToFile: (NSString *) file fromURL: (NSURL *) url {
    self.urlToLoad = url;
    self.finalFile = file;
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:self.urlToLoad.absoluteString parameters: nil error: nil];

    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * downloadProgress){
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = downloadProgress.fractionCompleted;
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaLoadProgress:)]) {
                [self.delegate mediaLoadProgress:progress];
            }
        });
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:self.finalFile];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSString * fileString = [filePath path];
        if(!error){
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[NSFileManager defaultManager] fileExistsAtPath:fileString]){
                    if (self.delegate) [self.delegate mediaLoadComplete:self.finalFile withNewFile:YES];
                }
            });
        } else {
            NSLog(@"Error: %@", error);
            //delete the file
            NSError *deleteError;
            [[NSFileManager defaultManager] removeItemAtPath:fileString error:&deleteError];
        }

    }];

    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.finalFile stringByDeletingLastPathComponent]]) {
        NSLog(@"Creating directory %@", [self.finalFile stringByDeletingLastPathComponent]);
        [[NSFileManager defaultManager] createDirectoryAtPath:[self.finalFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    }

    [manager addTask:task];
}

#pragma mark - AVPlayerItem

- (AVPlayerItem *) createPlayerItemFromURL: (NSURL *) url toFile: (nullable NSString *) file {
    self.pendingRequests = [NSMutableArray array];
    self.urlToLoad = url;

    self.localFile = url.fileURL;
    if (self.localFile) {
        self.finalFile = url.path;
        self.tempFile = url.path;
    } else {
        self.tempFile = file;
    }
    
    NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
    components.scheme = @"streaming";
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:components.URL];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    
    return item;
}

- (void)appendDataToTempFile:(NSData *)data {
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.finalFile]) {
        NSLog(@"write to file %@", self.finalFile);

        [data writeToFile:self.finalFile atomically:YES];
    } else {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.finalFile];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
    }
}

#pragma mark - AVURLAsset resource loading

- (void)processPendingRequests {
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];
        
        if (didRespondCompletely) {
            [requestsCompleted addObject:loadingRequest];
            
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest {
    if (contentInformationRequest == nil || self.response == nil) {
        return;
    }
    
    NSString *mimeType = [self.response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    CFStringRef extension = UTTypeCopyPreferredTagWithClass(contentType, kUTTagClassFilenameExtension);
    self.mimeExtension = CFBridgingRelease(extension);
    if (!self.localFile) {
        self.finalFile = [NSString stringWithFormat:@"%@.%@", self.tempFile, self.mimeExtension];
    }

    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.response expectedContentLength];
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest {
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0) {
        startOffset = dataRequest.currentOffset;
    }
    
    // Don't have any data at all for this request
    if (self.fullAudioDataLength < startOffset) {
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

- (NSData *)dataFromFileInRange:(NSRange)range {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.finalFile];;
    [fileHandle seekToFileOffset:range.location];
    return [fileHandle readDataOfLength:range.length];
}


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self startSessionTask:loadingRequest];
    
    [self.pendingRequests addObject:loadingRequest];
    [self processPendingRequests];
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.pendingRequests removeObject:loadingRequest];
}

- (void) startSessionTask: (AVAssetResourceLoadingRequest *) loadingRequest {
    if (self.task == nil) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPMaximumConnectionsPerHost = MAGE_HTTPMaximumConnectionsPerHost;
        configuration.URLCache = nil;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
        MageSessionManager *manager = [MageSessionManager sharedManager];

        NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:self.urlToLoad.absoluteString parameters: nil error: nil];

        self.task = [session dataTaskWithRequest:request];
        
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.finalFile stringByDeletingLastPathComponent]]) {
            NSLog(@"Creating directory %@", [self.finalFile stringByDeletingLastPathComponent]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[self.finalFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        [self.task resume];
    }
}

#pragma mark - NSURLSessionDownload delegate

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSLog(@"finished loading the media file");
    [self processPendingRequests];
    if (self.delegate) [self.delegate mediaLoadComplete:self.finalFile withNewFile:!self.localFile];
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.response = downloadTask.response;
    self.fullAudioDataLength += bytesWritten;
    [self processPendingRequests];
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

#pragma mark - NSURLSessionTask delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"finished loading the media file");
    [self processPendingRequests];
    
    if(error){
        NSLog(@"Error: %@", error);
        //delete the file
        NSError *deleteError;
        [[NSFileManager defaultManager] removeItemAtPath:self.finalFile error:&deleteError];
    }
}

#pragma mark - NSURLSessionData delegate

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.fullAudioDataLength = 0;
    self.response = (NSHTTPURLResponse *)response;
    
    [self processPendingRequests];
    completionHandler(NSURLSessionResponseAllow);
}

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.fullAudioDataLength += data.length;
    if (!self.localFile) [self appendDataToTempFile: data];
    
    [self processPendingRequests];
}

@end
