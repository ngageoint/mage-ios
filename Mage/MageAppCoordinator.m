//
//  MageAppCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/5/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageAppCoordinator.h"
#import "Attachment+Thumbnail.h"
#import "UIImage+Thumbnail.h"
#import "AuthenticationCoordinator.h"
#import "EventChooserCoordinator.h"
#import <Event.h>

#import <UserNotifications/UserNotifications.h>
#import <FICImageCache.h>
#import <AVFoundation/AVFoundation.h>
#import <UserUtility.h>
#import <MageSessionManager.h>
#import <StoredPassword.h>
#import <MageServer.h>

@interface MageAppCoordinator() <UNUserNotificationCenterDelegate, FICImageCacheDelegate, AuthenticationDelegate, EventChooserDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) NSMutableArray *childCoordinators;

@end

@implementation MageAppCoordinator

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController forApplication: (UIApplication *) application {
    self = [super init];
    if (!self) return nil;
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _navigationController = navigationController;

    [self setupPushNotificationsForApplication:application];
    [self setupFastImageCache];
    
    return self;
}

- (void) start {
    // check for a valid token
    if ([[UserUtility singleton] isTokenExpired]) {
        // start the authentication coordinator
        AuthenticationCoordinator *authCoordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:self.navigationController andDelegate:self];
        [_childCoordinators addObject:authCoordinator];
        [authCoordinator start];
    } else {
        [MageSessionManager manager].token = [StoredPassword retrieveStoredToken];
        [self startEventChooser];
    }
}

- (void) authenticationSuccessful {
    [_childCoordinators removeLastObject];
    [self startEventChooser];
}

- (void) startEventChooser {
    EventChooserCoordinator *eventChooser = [[EventChooserCoordinator alloc] initWithViewController:self.navigationController andDelegate:self];
    [_childCoordinators addObject:eventChooser];
    [eventChooser start];
}

- (void) eventChoosen:(Event *)event {
    [_childCoordinators removeLastObject];
    [Event sendRecentEvent];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIStoryboard *ipadStoryboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
        UIViewController *vc = [ipadStoryboard instantiateInitialViewController];
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self.navigationController presentViewController:vc animated:YES completion:NULL];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [iphoneStoryboard instantiateInitialViewController];
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self.navigationController presentViewController:vc animated:YES completion:NULL];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNAuthorizationOptionAlert + UNAuthorizationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    
}

- (void) setupPushNotificationsForApplication: (UIApplication *) application {
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:@"View"
                                                                            title:@"View" options:UNNotificationActionOptionNone];
    UNNotificationCategory *observationPulledCategory = [UNNotificationCategory categoryWithIdentifier:@"ObservationPulled"
                                                                                               actions:@[viewAction] intentIdentifiers:@[]
                                                                                               options:UNNotificationCategoryOptionNone];
    UNNotificationCategory *tokenExpiredCategory = [UNNotificationCategory categoryWithIdentifier:@"TokenExpired"
                                                                                          actions:@[viewAction] intentIdentifiers:@[]
                                                                                          options:UNNotificationCategoryOptionNone];
    NSSet *categories = [NSSet setWithObjects:observationPulledCategory, tokenExpiredCategory, nil];
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center setNotificationCategories:categories];
    [center setDelegate:self];
    
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge + UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];
}

- (void) setupFastImageCache {
    FICImageFormat *thumbnailImageFormat = [[FICImageFormat alloc] init];
    thumbnailImageFormat.name = AttachmentSmallSquare;
    thumbnailImageFormat.family = AttachmentFamily;
    thumbnailImageFormat.style = FICImageFormatStyle32BitBGR;
    thumbnailImageFormat.imageSize = AttachmentSquareImageSize;
    thumbnailImageFormat.maximumCount = 250;
    thumbnailImageFormat.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    thumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    FICImageFormat *ipadThumbnailImageFormat = [[FICImageFormat alloc] init];
    ipadThumbnailImageFormat.name = AttachmentMediumSquare;
    ipadThumbnailImageFormat.family = AttachmentFamily;
    ipadThumbnailImageFormat.style = FICImageFormatStyle32BitBGR;
    ipadThumbnailImageFormat.imageSize = AttachmentiPadSquareImageSize;
    ipadThumbnailImageFormat.maximumCount = 250;
    ipadThumbnailImageFormat.devices = FICImageFormatDevicePad;
    ipadThumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    NSArray *imageFormats = @[thumbnailImageFormat, ipadThumbnailImageFormat];
    
    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
    sharedImageCache.delegate = self;
    sharedImageCache.formats = imageFormats;
}

- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    Attachment *attachment = (Attachment *) entity;
    [attachment.managedObjectContext obtainPermanentIDsForObjects:@[attachment] error:nil];
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextWithParent:attachment.managedObjectContext];
    
    [localContext performBlock:^{
        Attachment *localAttachment = [(Attachment *) entity MR_inContext:localContext];
        
        // Fetch the desired source image by making a network request
        UIImage *sourceImage = nil;
        NSLog(@"content type %@", localAttachment.contentType);
        if ([localAttachment.contentType hasPrefix:@"image"]) {
            NSURL *url = [localAttachment sourceImageURLWithFormatName:formatName];
            sourceImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(sourceImage);
            });
        } else if ([localAttachment.contentType hasPrefix:@"video"]) {
            NSURL *url = [localAttachment sourceImageURLWithFormatName:formatName];
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            generator.appliesPreferredTrackTransform = YES;
            CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
            
            AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                if (result != AVAssetImageGeneratorSucceeded) {
                    NSLog(@"couldn't generate thumbnail, error:%@", error);
                }
                
                CGSize thumbnailSize = [AttachmentSmallSquare isEqualToString:formatName] ? AttachmentSquareImageSize : AttachmentiPadSquareImageSize;
                UIImage *sourceImage = [UIImage imageWithCGImage:image];
                UIImage *thumbnail = [sourceImage thumbnailWithSize:thumbnailSize];
                UIImage *playOverlay = [UIImage imageNamed:@"play_overlay"];
                
                UIGraphicsBeginImageContextWithOptions(thumbnail.size, NO, 0.0);
                [thumbnail drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
                [playOverlay drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
                UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(newImage);
                });
            };
            
            [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
        } else if ([localAttachment.contentType hasPrefix:@"audio"]) {
            sourceImage = [UIImage imageNamed:@"audio_thumbnail"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(sourceImage);
            });
        } else {
            sourceImage = [UIImage imageNamed:@"paperclip_thumbnail"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(sourceImage);
            });
        }
    }];
}

@end
