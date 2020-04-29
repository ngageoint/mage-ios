//
//  AttachmentPushService.m
//  mage-ios-sdk
//
//

#import "AttachmentPushService.h"
#import "Attachment.h"
#import "Observation.h"
#import "UserUtility.h"
#import "NSDate+Iso8601.h"
#import "StoredPassword.h"
#import "DataConnectionUtilities.h"

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
    
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pushTasks = [NSMutableArray arrayWithArray:[uploadTasks valueForKeyPath:@"taskIdentifier"]];
            
            [self pushAttachments:self.fetchedResultsController.fetchedObjects];
            [self scheduleTimer];
        });
    }];
}

- (void) stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_attachmentPushTimer isValid]) {
            [_attachmentPushTimer invalidate];
            _attachmentPushTimer = nil;
        }
    });
    
    self.fetchedResultsController = nil;
}


- (void) scheduleTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.attachmentPushTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
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
        
        NSData *attachmentData = [NSData dataWithContentsOfFile:attachment.localPath];
        if (attachmentData == nil) {
            NSLog(@"Attachment data nil for observation: %@ at path: %@", attachment.observation.remoteId, attachment.localPath);
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                Attachment *localAttachment = [attachment MR_inContext:localContext];
                [localAttachment MR_deleteEntity];
            }];
            
            continue;
        }
        
        NSString *url = [NSString stringWithFormat:@"%@/%@", attachment.observation.url, @"attachments"];
        NSLog(@"pushing attachment %@", url);

        NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
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

    if (error) {
        NSLog(@"ATTACHMENT - error uploading attachment %@", error);
        return;
    }
    
    NSData *data = [self.pushData objectForKey:[NSNumber numberWithLong:task.taskIdentifier]];
    if (!data) {
        NSLog(@"ATTACHMENT - error uploading attachment, did not receive response from the server");
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
    
        attachment.dirty = [NSNumber numberWithBool:NO];
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

            NSURL *attachmentUrl = [NSURL fileURLWithPath:tmpFileLocation];
            NSError *removeError;
            NSLog(@"ATTACHMENT - Deleting tmp multi part file for attachment upload %@", attachmentUrl);
            if (![[NSFileManager defaultManager] removeItemAtURL:attachmentUrl error:&removeError]) {
                NSLog(@"ATTACHMENT - Error removing temporary attachment upload file %@", removeError);
            }
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

