//
//  AttachmentPushService.m
//  mage-ios-sdk
//
//

#import "AttachmentPushService.h"
#import "MageSessionManager.h"
#import "Attachment.h"
#import "Observation.h"
#import "UserUtility.h"
#import "NSDate+iso8601.h"

NSString * const kAttachmentPushFrequencyKey = @"attachmentPushFrequency";

@interface AttachmentPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* attachmentPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *pushingAttachments;
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
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kAttachmentPushFrequencyKey] doubleValue];
        _pushingAttachments = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void) start {
    self.fetchedResultsController = [Attachment MR_fetchAllSortedBy:@"lastModified"
                                                          ascending:NO
                                                      withPredicate:[NSPredicate predicateWithFormat:@"observationRemoteId != nil && dirty == YES"]
                                                            groupBy:nil
                                                           delegate:self
                                                          inContext:[NSManagedObjectContext MR_defaultContext]];

    [self pushAttachments:self.fetchedResultsController.fetchedObjects];
    [self scheduleTimer];
}

- (void) scheduleTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.attachmentPushTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) onTimerFire {
    if (![[UserUtility singleton] isTokenExpired]) {
        [Attachment MR_performFetch:self.fetchedResultsController];
        [self pushAttachments:self.fetchedResultsController.fetchedObjects];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"attachment inserted, push em");
            [self pushAttachments:@[anObject]];
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"attachment updated, push em");
            [self pushAttachments:@[anObject]];
            break;
        default:
            break;
    }
}


- (void) pushAttachments:(NSArray *) attachments {
    NSLog(@"currently still pushing %lu attachments", (unsigned long)self.pushingAttachments.count);
    
    // only push attachments that haven't already been told to be pushed
    NSMutableDictionary *attachmentsToPush = [[NSMutableDictionary alloc] init];
    for (Attachment *attachment in attachments) {
        if ([self.pushingAttachments objectForKey:attachment.objectID] == nil) {
            [self.pushingAttachments setObject:attachment forKey:attachment.objectID];
            [attachmentsToPush setObject:attachment forKey:attachment.objectID];
        }
    }
    
    NSLog(@"about to push an additional %lu attachments", (unsigned long) attachmentsToPush.count);
    for (Attachment *attachment in [attachmentsToPush allValues]) {
        NSLog(@"submitting attachment %@", attachment);
        
        NSData *attachmentData = [NSData dataWithContentsOfFile:attachment.localPath];
        if (attachmentData == nil) {
            NSLog(@"Attachment data nil for observation: %@ at path: %@", attachment.observation.remoteId, attachment.localPath);
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                Attachment *localAttachment = [attachment MR_inContext:localContext];
                [localAttachment MR_deleteEntity];
            }];
            
            [attachmentsToPush removeObjectForKey:attachment.objectID];
            continue;
        }
        
        MageSessionManager *manager = [MageSessionManager manager];
        NSString *url = [NSString stringWithFormat:@"%@/%@", attachment.observation.url, @"attachments"];

        NSURL *URL = [NSURL URLWithString:url];
        NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:attachmentData name:@"attachment" fileName:attachment.name mimeType:attachment.contentType];
        } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Attachment *localAttachment = [attachment MR_inContext:localContext];
                localAttachment.remoteId = [responseObject valueForKey:@"id"];
                
                NSString *dateString = [responseObject valueForKey:@"lastModified"];
                if (dateString != nil) {
                    NSDate *date = [NSDate dateFromIso8601String:dateString];
                    [localAttachment setLastModified:date];
                }
                localAttachment.name = [responseObject valueForKey:@"name"];
                localAttachment.url = [responseObject valueForKey:@"url"];
                localAttachment.dirty = [NSNumber numberWithBool:NO];
            } completion:^(BOOL success, NSError *error) {
                [attachmentsToPush removeObjectForKey:attachment.objectID];
            }];
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            [attachmentsToPush removeObjectForKey:attachment.objectID];
        }];
                
        [manager addTask:task];
    }
}

-(void) stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_attachmentPushTimer isValid]) {
            [_attachmentPushTimer invalidate];
            _attachmentPushTimer = nil;
        }
    });
    
    self.fetchedResultsController = nil;
}


@end

