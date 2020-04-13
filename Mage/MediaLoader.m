//
//  MediaLoader.m
//  MAGE
//
//  Created by Daniel Barela on 4/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MediaLoader.h"

@interface MediaLoader()

@property (strong, nonatomic) NSMutableArray *pendingRequests;
@property (strong, nonatomic) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (strong, nonatomic) NSString *tempFile;
@property (nonatomic, assign) NSUInteger fullAudioDataLength;
@property (nonatomic, strong) NSURL *urlToLoad;
@property (nonatomic, strong) id<MediaLoaderDelegate> delegate;
@property (strong, nonatomic) NSString *existingFile;
@property (strong, nonatomic) NSString *mimeExtension;
@property (strong, nonatomic) NSString *finalFile;

@end

@implementation MediaLoader

- (instancetype) initWithUrlToLoad: (NSURL *) urlToLoad andTempFile: (NSString *) tempFile andDelegate: (id<MediaLoaderDelegate>) delegate {
    self.urlToLoad = urlToLoad;
    self.tempFile = tempFile;
    self.finalFile = tempFile;
    self.delegate = delegate;
    // This tracks all pending AVAssetResourceLoadingRequest objects we have not fulfilled yet
    self.pendingRequests = [NSMutableArray array];
    return self;
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
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.finalFile]) {
        NSLog(@"write to file %@", self.finalFile);

        [data writeToFile:self.finalFile atomically:YES];
    } else {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.finalFile];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finished loading the media file");
    [self processPendingRequests];
    if (self.delegate) [self.delegate mediaLoadComplete:self.finalFile];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Failed with error %@", error);
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
//    CFStringRef extension = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(mimeType), NULL);
    
    CFStringRef extension = UTTypeCopyPreferredTagWithClass(contentType, kUTTagClassFilenameExtension);
    self.mimeExtension = CFBridgingRelease(extension);
    self.finalFile = [NSString stringWithFormat:@"%@.%@", self.tempFile, self.mimeExtension];
//    use this extension to name the file then pass that back to the other class so it can save it in the local file of attachment

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
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.finalFile];;
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

 //    // MARK: NSURLConnection delegate
 //    //
 //
 //    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
 //        print("did receive response");
 //        self.fullAudioDataLength = 0;
 //        self.response = response;
 //        self.processPendingRequests();
 //    }
 //
 //    func connection(_ connection: NSURLConnection, didReceive data: Data) {
 ////        print("did recieve data")
 //        self.fullAudioDataLength += data.count;
 //        self.appendDataToTempFile(data: data);
 //        self.processPendingRequests();
 //    }
 //
 //    func connectionDidFinishLoading(_ connection: NSURLConnection) {
 //        print("Finished loading the media file");
 //        // save the path to the downloaded file in the attachment
 //        MagicalRecord.save({ (localContext : NSManagedObjectContext!) in
 //            let localAttachment = self.attachment.mr_(in: localContext);
 //            localAttachment?.localPath = self.tempFile;
 //        });
 //        self.processPendingRequests();
 //    }
 //
 //    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
 //        print(error)
 //    }
 //
 //    func appendDataToTempFile(data: Data) {
 ////        print("append data")
 //        do {
 //            if (FileManager.default.fileExists(atPath: self.tempFile)) {
 //                try data.write(to: URL(fileURLWithPath: self.tempFile), options: .atomic)
 //            } else {
 //                let fileHandle = FileHandle(forWritingAtPath: self.tempFile);
 //                fileHandle?.seekToEndOfFile();
 //                fileHandle?.write(data);
 //            }
 //        } catch {
 //            print(error)
 //        }
 //    }
 //
 //    // MARK: AVURLAsset resource loading
 //
 //    private func processPendingRequests() {
 //        var requestsCompleted = [AVAssetResourceLoadingRequest]()
 //        for loadingRequest in pendingRequests {
 //            fillInContentInformation(contentInformationRequest: loadingRequest.contentInformationRequest)
 //            let didRespondCompletely = respondWithDataForRequest(dataRequest: loadingRequest.dataRequest!)
 //            if didRespondCompletely == true {
 //                requestsCompleted.append(loadingRequest)
 //                loadingRequest.finishLoading()
 //            }
 //        }
 //        for requestCompleted in requestsCompleted {
 //            for (i, pendingRequest) in pendingRequests.enumerated() {
 //                if requestCompleted == pendingRequest {
 //                    pendingRequests.remove(at: i)
 //                }
 //            }
 //        }
 //    }
 //
 //    private func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
 //        if(contentInformationRequest == nil) {
 //            return
 //        }
 //        if (self.response == nil) {
 //            return
 //        }
 //
 //        let mimeType = self.response!.mimeType
 //        let unmanagedContentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, mimeType! as CFString, nil)
 //        let cfContentType = unmanagedContentType!.takeRetainedValue()
 //        contentInformationRequest!.contentType = String(cfContentType)
 //        contentInformationRequest!.isByteRangeAccessSupported = true
 //        contentInformationRequest!.contentLength = self.response!.expectedContentLength
 //    }
 //
 //    func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
 //        var startOffset = dataRequest.requestedOffset;
 //        if (dataRequest.currentOffset != 0) {
 //            startOffset = dataRequest.currentOffset;
 //        }
 //
 //        // No data yet
 //        if (self.fullAudioDataLength < startOffset || self.fullAudioDataLength == 0) {
 //            return false;
 //        }
 //
 //        let unreadBytes = self.fullAudioDataLength - Int(startOffset);
 //        let numberOfBytesToRespondWith = min(dataRequest.requestedLength, unreadBytes);
 //
 //        if let respondData = self.dataFromFileInRange(start: startOffset, length: numberOfBytesToRespondWith) {
 //            dataRequest.respond(with: respondData);
 //        }
 //        let endOffset = Int(startOffset) + dataRequest.requestedLength;
 //
 //        return self.fullAudioDataLength >= endOffset && self.fullAudioDataLength != 0;
 //    }
 //
 //    func dataFromFileInRange(start: Int64, length: Int) -> Data? {
 //        let fileHandle = FileHandle(forReadingAtPath: self.tempFile);
 //        fileHandle?.seek(toFileOffset: UInt64(start));
 //        return fileHandle?.readData(ofLength: length);
 //    }
 //
 //    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
 //        if (self.connection == nil) {
 //            if let interceptedURL = loadingRequest.request.url {
 //                var interceptedURLComponents = URLComponents(url: interceptedURL, resolvingAgainstBaseURL: false);
 //                let loadingComponents = URLComponents(url: self.urlToLoad!, resolvingAgainstBaseURL: false);
 //                interceptedURLComponents?.scheme = loadingComponents?.scheme;
 //
 //                let request = URLRequest(url: (interceptedURLComponents?.url)!);
 //                self.connection = NSURLConnection.init(request: request, delegate: self, startImmediately: false);
 //                self.connection?.setDelegateQueue(OperationQueue.main);
 //                self.connection?.start();
 //            }
 //        }
 //
 //        self.pendingRequests.append(loadingRequest);
 ////        self.processPendingRequests();
 //
 //        return true;
 //    }
 //
 //    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
 //        print("cancel loading request")
 //        print("pnding requets", pendingRequests.count);
 //        self.pendingRequests = self.pendingRequests.filter { value in
 //            value != loadingRequest
 //        }
 //        print("pending requests now", pendingRequests.count);
 //    }


@end
