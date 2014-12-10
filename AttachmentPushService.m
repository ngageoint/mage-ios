//
//  AttachmentPushService.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 12/4/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "AttachmentPushService.h"
#import "HttpManager.h"
#import "NSManagedObjectContext+MAGE.h"
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
        
        NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Attachment" inManagedObjectContext:context]];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"lastModified" ascending:NO], nil]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
        [self.fetchedResultsController setDelegate:self];
    }
    
    return self;
}

- (void) start {
    [self stop];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    [self pushAttachments];
    // probably not exactly correct but for now i am just going to schedule right here
    // should wait for things to push and then schedule again maybe.
    [self scheduleTimer];
}

- (void) scheduleTimer {
    self.attachmentPushTimer = [NSTimer timerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.attachmentPushTimer forMode:NSRunLoopCommonModes];
}

- (void) onTimerFire {
    [self pushAttachments];
}


//controllerWillChangeContent:
//controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:
//controller:didChangeSection:atIndex:forChangeType:
//controllerDidChangeContent:

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            //            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            NSLog(@"attachment inserted, push em");
            [self pushAttachments];
            break;
            
        case NSFetchedResultsChangeDelete:
            //            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            NSLog(@"attachment updated, push em");
            [self pushAttachments];
            break;
            
        case NSFetchedResultsChangeMove:
            //            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            //            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void) pushAttachments {
    NSLog(@"currently still pushing %lu attachments", (unsigned long)self.pushingAttachments.count);
    //    if (self.pushingObservations.count != 0) return;
    
    // only push attachments that haven't already been told to be pushed
    NSMutableDictionary *attachmentsToPush = [[NSMutableDictionary alloc] init];
    for (Attachment *attachment in [self.fetchedResultsController fetchedObjects]) {
        if ([self.pushingAttachments objectForKey:attachment.objectID] == nil){
            [self.pushingAttachments setObject:attachment forKey:attachment.objectID];
            [attachmentsToPush setObject:attachment forKey:attachment.objectID];
        }
    }
    
    NSLog(@"about to push an additional %lu attachments", (unsigned long)attachmentsToPush.count);
    for (id attachmentId in attachmentsToPush) {
        // let's pull the most up to date version of this attachment to push
        NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
        NSError *error;
        Attachment *attachment = (Attachment *)[context existingObjectWithID:attachmentId error:&error];
        if (attachment == nil || attachment.observation.remoteId == nil) {
            continue;
        }
        NSLog(@"submitting attachment %@", attachment.objectID);
        
        HttpManager *manager = [HttpManager singleton];
        
        NSString *url = [NSString stringWithFormat:@"%@/%@", attachment.observation.url, @"attachments"];

        NSMutableURLRequest *request = [manager.sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:[NSData dataWithContentsOfFile:attachment.localPath] name:@"attachment" fileName:attachment.name mimeType:attachment.contentType];
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
            } else {
                NSLog(@"%@ %@", response, responseObject);
                [attachment.managedObjectContext refreshObject:attachment mergeChanges:NO];
                attachment.remoteId = [responseObject valueForKey:@"id"];
                NSDateFormatter *dateFormat = [NSDateFormatter new];
                [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
                // Always use this locale when parsing fixed format date strings
                NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                dateFormat.locale = posix;
                NSString *dateString = [responseObject valueForKey:@"lastModified"];
                if (dateString != nil) {
                    NSDate *date = [dateFormat dateFromString:dateString];
                    [attachment setLastModified:date];
                }
                attachment.name = [responseObject valueForKey:@"name"];
                attachment.url = [responseObject valueForKey:@"url"];
                attachment.dirty = NO;
                // we keep getting save errors so I am just going to set a merge policy here
                // to have the database win
                [context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
                NSError *error;
                if (![context save:&error]) {
                    NSLog(@"Error updating attachment: %@", error);
                }
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
}


/*
 //            HttpManager *manager = [HttpManager singleton];
 //            NSString *url = [NSString stringWithFormat:@"%@/%@", self.observation.url, @"attachments"];
 //
 //            NSMutableURLRequest *request = [manager.sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
 //                [formData appendPartWithFileData:[attachment valueForKey:@"data"] name:@"attachment" fileName:[attachment valueForKey:@"fileName"] mimeType:[attachment valueForKey:@"mimeType"]];
 //            } error:nil];
 //            // not sure why the HTTPRequestHeaders are not being set, so set them here
 //            [manager.sessionManager.requestSerializer.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
 //                if (![request valueForHTTPHeaderField:field]) {
 //                    [request setValue:value forHTTPHeaderField:field];
 //                }
 //            }];
 //            NSProgress *progress = nil;
 //
 //            NSURLSessionUploadTask *uploadTask = [manager.sessionManager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
 //                if (error) {
 //                    NSLog(@"Error: %@", error);
 //                } else {
 //                    NSLog(@"%@ %@", response, responseObject);
 //                }
 //            }];
 //
 //
 //            [uploadTask resume];*/

@end
