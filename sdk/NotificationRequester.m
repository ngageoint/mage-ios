//
//  NotificationRequester.m
//  Pods
//
//  Created by Dan Barela on 8/30/17.
//
//

#import "NotificationRequester.h"
#import <UserNotifications/UserNotifications.h>
#import "MAGE-Swift.h"
@import Persistence;

@implementation NotificationRequester

+ (UNNotificationRequest *) buildObservationNotificationRequest: (NSManagedObject *) observation {
    Observation *strongObservation = (Observation *)observation;
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    Event *event = [Event getEventWithEventId:strongObservation.eventId context:observation.managedObjectContext];
    
    NSString *body = @"";
    if ([strongObservation primaryFeedFieldText] != nil) {
        body = [body stringByAppendingString:[NSString stringWithFormat:@"%@", [strongObservation primaryFeedFieldText]]];
    }
    if ([strongObservation secondaryFeedFieldText] != nil) {
        body = [body stringByAppendingString:[NSString stringWithFormat:@", %@", [strongObservation secondaryFeedFieldText]]];
    }
    
    body = [body stringByAppendingString:[NSString stringWithFormat:@" observation was created in %@ event.", event.name]];
    
    content.title = [NSString stringWithFormat: @"New Observation"];
    content.body = body;
    
    NSMutableArray *attachments = [[NSMutableArray alloc] init];
    NSString *imageUrl = [ObservationImage imageNameWithObservation:strongObservation];
    if (imageUrl) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageUrl];
        if (image) {
            CGFloat sideLength = image.size.height > image.size.width ? image.size.height : image.size.width;
            
            CGSize size = CGSizeMake(sideLength, sideLength);
            UIGraphicsBeginImageContext(size);
            [image drawAtPoint:CGPointMake((sideLength - image.size.width) / 2, (sideLength - image.size.height) / 2)];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            NSString *tmpUrl = [NSTemporaryDirectory() stringByAppendingString:@"image.png"];
            [UIImagePNGRepresentation(image) writeToFile:tmpUrl atomically:YES];
            
            UNNotificationAttachment *icon = [UNNotificationAttachment attachmentWithIdentifier:strongObservation.remoteId URL:[NSURL fileURLWithPath:tmpUrl] options:@{ UNNotificationAttachmentOptionsThumbnailClippingRectKey: (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(CGRectMake(0, 0, 1.0, 1.0)))} error:nil];
            [attachments addObject:icon];
        }
    }
    content.attachments = attachments;
    content.categoryIdentifier = @"ObservationPulled";
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                  triggerWithTimeInterval:1 repeats:NO];
    return [UNNotificationRequest requestWithIdentifier:strongObservation.remoteId
                                                content:content trigger:trigger];
}

+ (void) observationPulled: (NSManagedObject *) observationOld {
    Observation* strongObservation = (Observation *)observationOld;
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_context];
    
    
    [context performBlockAndWait:^{
        Observation *observation = [strongObservation MR_inContext:context];
        UNNotificationRequest *request = [NotificationRequester buildObservationNotificationRequest:observation];
        
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"Something went wrong: %@",error);
            }
            NSLog(@"notification");
        }];
    }];
}

+ (void) sendBulkNotificationCount: (NSUInteger) count inEvent: (Event *) event {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString stringWithFormat: @"New Observations"];
    content.body = [NSString stringWithFormat:@"%lu new observations were pulled for event %@", (unsigned long)count, event.name];
    
    content.categoryIdentifier = @"ObservationPulled";
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                  triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"EventObservations%@",event.remoteId]
                                                                          content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
        }
        NSLog(@"notification");
    }];
}

@end
