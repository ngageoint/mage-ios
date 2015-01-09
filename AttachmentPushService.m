//
//  AttachmentPushService.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 12/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "AttachmentPushService.h"
#import "HttpManager.h"
#import "Attachment+helper.h"
#import "Observation+helper.h"

NSString * const kAttachmentPushFrequencyKey = @"attachmentPushFrequency";

@interface AttachmentPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* attachmentPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *pushingAttachments;
@end

@implementation AttachmentPushService

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kAttachmentPushFrequencyKey] doubleValue];
        _pushingAttachments = [[NSMutableDictionary alloc] init];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kAttachmentPushFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        self.fetchedResultsController = [Attachment MR_fetchAllSortedBy:@"lastModified"
                                                              ascending:NO
                                                          withPredicate:[NSPredicate predicateWithFormat:@"observationRemoteId != nil && dirty == YES"]
                                                                groupBy:nil
                                                               delegate:self
                                                              inContext:[NSManagedObjectContext MR_rootSavingContext]];
        
    }
    
    return self;
}

- (void) start {
    [self stop];
    
    self.fetchedResultsController.delegate = self;
    [self pushAttachments:self.fetchedResultsController.fetchedObjects];
    
    [self scheduleTimer];
}

- (void) scheduleTimer {
    self.attachmentPushTimer = [NSTimer timerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.attachmentPushTimer forMode:NSRunLoopCommonModes];
}

- (void) onTimerFire {
    [Attachment MR_performFetch:self.fetchedResultsController];
    [self pushAttachments:self.fetchedResultsController.fetchedObjects];
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
        
        HttpManager *manager = [HttpManager singleton];
        NSString *url = [NSString stringWithFormat:@"%@/%@", attachment.observation.url, @"attachments"];

        NSMutableURLRequest *request = [manager.sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:attachmentData name:@"attachment" fileName:attachment.name mimeType:attachment.contentType];
        } error:nil];
        // not sure why the HTTPRequestHeaders are not being set, so set them here
        [manager.sessionManager.requestSerializer.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
            if (![request valueForHTTPHeaderField:field]) {
                [request setValue:value forHTTPHeaderField:field];
            }
        }];
        NSProgress *progress = nil;

        NSURLSessionUploadTask *uploadTask = [manager.sessionManager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
                [attachmentsToPush removeObjectForKey:attachment.objectID];
            } else {
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    Attachment *localAttachment = [attachment MR_inContext:localContext];
                    localAttachment.remoteId = [responseObject valueForKey:@"id"];
                    
                    NSDateFormatter *dateFormat = [NSDateFormatter new];
                    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                    
                    // Always use this locale when parsing fixed format date strings
                    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    dateFormat.locale = posix;
                    
                    NSString *dateString = [responseObject valueForKey:@"lastModified"];
                    if (dateString != nil) {
                        NSDate *date = [dateFormat dateFromString:dateString];
                        [localAttachment setLastModified:date];
                    }
                    localAttachment.name = [responseObject valueForKey:@"name"];
                    localAttachment.url = [responseObject valueForKey:@"url"];
                    localAttachment.dirty = [NSNumber numberWithBool:NO];
                } completion:^(BOOL success, NSError *error) {
                    [attachmentsToPush removeObjectForKey:attachment.objectID];
                }];
            }
        }];
        
        [uploadTask resume];
    }
}

-(void) stop {
    if ([_attachmentPushTimer isValid]) {
        [_attachmentPushTimer invalidate];
        _attachmentPushTimer = nil;
    }
    
    self.fetchedResultsController.delegate = nil;
}


@end

