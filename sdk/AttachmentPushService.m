//
//  AttachmentPushService.m
//  mage-ios-sdk
//
//

#import "AttachmentPushService.h"
#import "NSDate+Iso8601.h"
#import "StoredPassword.h"
#import "RouteMethod.h"
#import "MAGERoutes.h"
#import "MAGE-Swift.h"

NSString * const kAttachmentPushFrequencyKey = @"attachmentPushFrequency";
NSString * const kAttachmentBackgroundSessionIdentifier = @"mil.nga.mage.background.attachment";

@interface AttachmentPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* attachmentPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *pushTasks;
@property (nonatomic, strong) NSMutableDictionary *pushData;
@end

@implementation AttachmentPushService

+ (instancetype) singleton {
    static AttachmentPushService *pushService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pushService = [[self alloc] init];
        pushService.started = false;
    });
    return pushService;
}

- (id) init {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kAttachmentBackgroundSessionIdentifier];
    
    if (self = [super initWithSessionConfiguration:configuration]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kAttachmentPushFrequencyKey] doubleValue];
        _pushTasks = [NSMutableArray array];
        _pushData = [NSMutableDictionary dictionary];
        
        [self configureProgress];
        [self configureTaskReceivedData];
        [self configureTaskCompletion];
        [self configureBackgroundCompletion];
    }
    
    return self;
}

- (void) start {
    [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [StoredPassword retrieveStoredToken]] forHTTPHeaderField:@"Authorization"];
    
    self.fetchedResultsController = [Attachment MR_fetchAllSortedBy:@"lastModified"
                                                          ascending:NO
                                                      withPredicate:[NSPredicate predicateWithFormat:@"observationRemoteId != nil && dirty == YES"]
                                                            groupBy:nil
                                                           delegate:self
                                                          inContext:[NSManagedObjectContext MR_defaultContext]];
    __weak typeof(self) weakSelf = self;
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.pushTasks = [NSMutableArray arrayWithArray:[uploadTasks valueForKeyPath:@"taskIdentifier"]];
            
            [weakSelf pushAttachments:weakSelf.fetchedResultsController.fetchedObjects];
            [weakSelf scheduleTimer];
        });
    }];
    self.started = true;
}

- (void) stop {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.attachmentPushTimer isValid]) {
            [weakSelf.attachmentPushTimer invalidate];
            weakSelf.attachmentPushTimer = nil;
        }
    });
    
    self.fetchedResultsController = nil;
    self.started = false;
}


- (void) scheduleTimer {
    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.attachmentPushTimer = [NSTimer scheduledTimerWithTimeInterval:weakSelf.interval target:weakSelf selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) onTimerFire {
    if (![[UserUtility singleton] isTokenExpired]) {
        NSLog(@"ATTACHMENT - push timer fired, checking if any attachments need to be pushed");
        [Attachment MR_performFetch:self.fetchedResultsController];
        [self pushAttachments:self.fetchedResultsController.fetchedObjects];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"ATTACHMENT - attachment inserted, push em");
            [self pushAttachments:@[anObject]];
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"ATTACHMENT - attachment updated, push em");
            [self pushAttachments:@[anObject]];
            break;
        default:
            break;
    }
}

- (void) pushAttachments:(NSArray *) attachments {
    if (![DataConnectionUtilities shouldPushAttachments]) return;
    [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [StoredPassword retrieveStoredToken]] forHTTPHeaderField:@"Authorization"];

    for (Attachment *attachment in attachments) {
        if ([self.pushTasks containsObject:attachment.taskIdentifier]) {
            // already pushing this attachment
            continue;
        }
        
        // determine if this is a delete or a push
        if (attachment.markedForDeletion) {
            [self deleteAttachment:attachment];
        } else {
            [self pushAttachment:attachment];
        }
    }
}

- (void) deleteAttachment: (Attachment *) attachment {
    RouteMethod *delete = [[MAGERoutes attachment] deleteRoute:attachment];

    NSLog(@"deleting attachment %@", delete.route);
    [self DELETE:delete.route parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"Attachment deleted response %@", responseObject);
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            Attachment *localAttachment = [attachment MR_inContext:localContext];
            [localAttachment MR_deleteEntity];
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Failure to delete attachment %@", error);
    }];
}

- (void) pushAttachment: (Attachment *) attachment {
    NSData *attachmentData = [NSData dataWithContentsOfFile:attachment.localPath];
    if (attachmentData == nil) {
        NSLog(@"Attachment data nil for observation: %@ at path: %@", attachment.observation.remoteId, attachment.localPath);
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            Attachment *localAttachment = [attachment MR_inContext:localContext];
            [localAttachment MR_deleteEntity];
        }];
        
        return;
    }
    
    RouteMethod *push = [[MAGERoutes attachment] push:attachment];
    NSLog(@"pushing attachment %@", push.route);
    
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:push.method URLString:push.route parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:attachment.localPath] name:@"attachment" fileName:attachment.name mimeType:attachment.contentType error:nil];
    } error:nil];
    
    NSURL *attachmentUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:attachment.name]];
    NSLog(@"ATTACHMENT - Creating tmp multi part file for attachment upload %@", attachmentUrl);
    if ([[NSFileManager defaultManager] fileExistsAtPath:[attachmentUrl absoluteString]]) {
        NSLog(@"file already exists");
    }
    
    [self.requestSerializer requestWithMultipartFormRequest:request writingStreamContentsToFile:attachmentUrl completionHandler:^(NSError * _Nullable error) {
        NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromFile:attachmentUrl];
        
        NSNumber *taskIdentifier = [NSNumber numberWithLong:uploadTask.taskIdentifier];
        [self.pushTasks addObject:taskIdentifier];
        attachment.taskIdentifier = taskIdentifier;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
            NSLog(@"ATTACHMENT - Context did save %d with error %@", contextDidSave, error);
            [uploadTask resume];
        }];
    }];
}

- (void) configureProgress {
    [self setTaskDidSendBodyDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        double progress = (double) totalBytesSent / (double) totalBytesExpectedToSend;
        NSUInteger percent = (NSUInteger) (100.0 * progress);
        NSLog(@"ATTACHMENT - Upload %@ progress: %lu%%", task, (unsigned long)percent);
    }];
}

- (void) attachmentUploadReceivedData:(NSData *) data forTask:(NSURLSessionDataTask *) task {
    NSLog(@"ATTACHMENT - upload received data for task %@", task);
    
    NSNumber *taskIdentifier = [NSNumber numberWithLong:task.taskIdentifier];
    NSMutableData *existingData = [self.pushData objectForKey:taskIdentifier];
    if (existingData) {
        [existingData appendData:data];
    } else {
        [self.pushData setObject:[data mutableCopy] forKey:taskIdentifier];
    }
}

- (void) attachmentUploadCompleteWithTask:(NSURLSessionTask *) task withError:(NSError *) error {
    
    if ([task.originalRequest.HTTPMethod isEqualToString:@"DELETE"]) {
        NSLog(@"ATTACHMENT - delete complete with error %@", error);
        return;
    }

    if (error) {
        NSLog(@"ATTACHMENT - error uploading attachment %@", error);
        // try again
        [self.pushTasks removeObject:[NSNumber numberWithLong:task.taskIdentifier]];
        return;
    }
    
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
        if (httpResponse.statusCode != 200) {
            NSLog(@"ATTACHMENT - non 200 response %@", httpResponse);
            // try again
            [self.pushTasks removeObject:[NSNumber numberWithLong:task.taskIdentifier]];
            return;
        }
    }
    
    NSData *data = [self.pushData objectForKey:[NSNumber numberWithLong:task.taskIdentifier]];
    if (!data) {
        NSLog(@"ATTACHMENT - error uploading attachment, did not receive response from the server");
        // try again
        [self.pushTasks removeObject:[NSNumber numberWithLong:task.taskIdentifier]];
        return;
    }
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    Attachment *attachment = [Attachment MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"taskIdentifier == %@", [NSNumber numberWithLong:task.taskIdentifier]]
                                                         inContext:context];
    
    if (!attachment) {
        NSLog(@"ATTACHMENT - error completing attachment upload, could not retrieve attachment for task id %lu", (unsigned long)task.taskIdentifier);
        return;
    }
    
    NSString *tmpFileLocation = [NSTemporaryDirectory() stringByAppendingPathComponent:attachment.name];
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (response == nil) {
        // try again
        [self.pushTasks removeObject:[NSNumber numberWithLong:task.taskIdentifier]];
        return;
    }
    
    attachment.dirty = false;
    attachment.remoteId = [response valueForKey:@"id"];
    attachment.name = [response valueForKey:@"name"];
    attachment.url = [response valueForKey:@"url"];
    attachment.taskIdentifier = nil;
    NSString *dateString = [response valueForKey:@"lastModified"];
    if (dateString != nil) {
        NSDate *date = [NSDate dateFromIso8601String:dateString];
        [attachment setLastModified:date];
    }

    if (attachment.url) {
        __weak __typeof__(self) weakSelf = self;

        [context MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
            [weakSelf.pushTasks removeObject:[NSNumber numberWithLong:task.taskIdentifier]];
            // push local file to the image cache
            if ([NSFileManager.defaultManager fileExistsAtPath:attachment.localPath]) {
                NSData *fileData = [NSFileManager.defaultManager contentsAtPath:attachment.localPath];
                if ([attachment.contentType hasPrefix:@"image"]) {
                    [ImageCacheProvider.shared cacheImageWithImage:[UIImage imageWithData:fileData] data:fileData key:attachment.url];
                }
            }
            NSURL *attachmentUrl = [NSURL fileURLWithPath:tmpFileLocation];
            NSError *removeError;
            NSLog(@"ATTACHMENT - Deleting tmp multi part file for attachment upload %@", attachmentUrl);
            if (![[NSFileManager defaultManager] removeItemAtURL:attachmentUrl error:&removeError]) {
                NSLog(@"ATTACHMENT - Error removing temporary attachment upload file %@", removeError);
            }
            
            [NSNotificationCenter.defaultCenter postNotificationName:@"AttachmentPushed" object:nil];
        }];
    } else {
        // try again
        [self.pushTasks removeObject:[NSNumber numberWithLong:task.taskIdentifier]];
    }
}

- (void) configureTaskReceivedData {
    __weak __typeof__(self) weakSelf = self;
    [self setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        NSLog(@"ATTACHMENT - MageBackgroundSessionManager setDataTaskDidReceiveDataBlock");
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf attachmentUploadReceivedData:data forTask:dataTask];
        });
    }];
}

- (void) configureTaskCompletion {
    __weak __typeof__(self) weakSelf = self;
    [self setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
        NSLog(@"ATTACHMENT - MageBackgroundSessionManager calling setTaskDidCompleteBlock with error %@", error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf attachmentUploadCompleteWithTask:task withError:error];
        });
    }];
}

- (void) configureBackgroundCompletion {
    __weak __typeof__(self) weakSelf = self;
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession * _Nonnull session) {
        if (weakSelf.backgroundSessionCompletionHandler) {
            NSLog(@"ATTACHMENT - MageBackgroundSessionManager calling backgroundSessionCompletionHandler");
            void (^completionHandler)(void) = weakSelf.backgroundSessionCompletionHandler;
            weakSelf.backgroundSessionCompletionHandler = nil;
            completionHandler();
        }
    }];
}

@end

