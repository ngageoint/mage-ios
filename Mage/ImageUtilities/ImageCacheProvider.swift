//
//  ImageCacheProvider.m
//  MAGE
//
//  Created by Daniel Barela on 2/21/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

//#import "FICImageCache.h"
//#import "Attachment+Thumbnail.h"
//#import "UIImage+Thumbnail.h"
//#import "DataConnectionUtilities.h"
//#import <AVFoundation/AVFoundation.h>

import Kingfisher

@objc class ImageCacheProvider: NSObject {
    
    @objc public static let shared = ImageCacheProvider()
    public var accessTokenModifier: AnyModifier!
    
    private override init() {
        super.init()
        // XXXX TODO temporary for testing
        ImageCache.default.clearMemoryCache();
        ImageCache.default.clearDiskCache();
        
        self.accessTokenModifier = AnyModifier { request in
            var r = request
            print("request", r);
            r.setValue(String(format: "Bearer %@", StoredPassword.retrieveStoredToken()), forHTTPHeaderField: "Authorization")
            return r
        }
    }
    
    @objc public func isCached(url: URL) -> Bool {
        return ImageCache.default.isCached(forKey: url.absoluteString)
    }
    
    @objc public func setImageViewUrl(imageView: UIImageView, url: URL) {
        imageView.kf.setImage(with: url)
    }
}

//- (instancetype) init {
//    self = [super init];
//    if (!self) return nil;
//
//
//
////    [self setupFastImageCache];
//
//    return self;
//}

//- (void) setupFastImageCache {
//    FICImageFormat *thumbnailImageFormat = [FICImageFormat formatWithName:AttachmentSmallSquare family:AttachmentFamily imageSize:AttachmentSquareImageSize style:FICImageFormatStyle32BitBGR maximumCount:250 devices:FICImageFormatDevicePhone | FICImageFormatDevicePad protectionMode:FICImageFormatProtectionModeNone];
////    FICImageFormat *thumbnailImageFormat = [[FICImageFormat alloc] init];
////    thumbnailImageFormat.name = AttachmentSmallSquare;
////    thumbnailImageFormat.family = AttachmentFamily;
////    thumbnailImageFormat.style = FICImageFormatStyle32BitBGR;
////    thumbnailImageFormat.imageSize = AttachmentSquareImageSize;
////    thumbnailImageFormat.maximumCount = 250;
////    thumbnailImageFormat.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
////    thumbnailImageFormat.protection = FICImageFormatProtectionModeNone;
//
//    FICImageFormat *ipadThumbnailImageFormat = [FICImageFormat formatWithName:AttachmentMediumSquare family:AttachmentFamily imageSize:AttachmentSquareImageSize style:FICImageFormatStyle32BitBGR maximumCount:250 devices: FICImageFormatDevicePad protectionMode:FICImageFormatProtectionModeNone];
////    FICImageFormat *ipadThumbnailImageFormat = [[FICImageFormat alloc] init];
////    ipadThumbnailImageFormat.name = AttachmentMediumSquare;
////    ipadThumbnailImageFormat.family = AttachmentFamily;
////    ipadThumbnailImageFormat.style = FICImageFormatStyle32BitBGR;
////    ipadThumbnailImageFormat.imageSize = AttachmentiPadSquareImageSize;
////    ipadThumbnailImageFormat.maximumCount = 250;
////    ipadThumbnailImageFormat.devices = FICImageFormatDevicePad;
////    ipadThumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
//
//    NSArray *imageFormats = @[thumbnailImageFormat, ipadThumbnailImageFormat];
//
//    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
//    sharedImageCache.delegate = self;
//    sharedImageCache.formats = imageFormats;
//}
//
//- (UIImage *) createUIImageFromURL: (NSURL *) url {
//    NSData *data = [NSData dataWithContentsOfURL:url];
//    return [UIImage imageWithData:data];
//}
//
//- (void) imageCache:(FICImageCache *)imageCache cancelImageLoadingForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName {
//
//}
//
//- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
//    Attachment *attachment = (Attachment *) entity;
//    [attachment.managedObjectContext obtainPermanentIDsForObjects:@[attachment] error:nil];
//    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextWithParent:attachment.managedObjectContext];
//
//    [localContext performBlock:^{
//        Attachment *localAttachment = [(Attachment *) entity MR_inContext:localContext];
//        NSURL *url = [localAttachment sourceImageURLWithFormatName:formatName];
//
//        // Fetch the desired source image by making a network request
//        NSLog(@"content type %@", localAttachment.contentType);
//        if (![DataConnectionUtilities shouldFetchAttachments] && !localAttachment.localPath) {
//            return completionBlock(nil);
//        }
//        if ([localAttachment.contentType hasPrefix:@"image"]) {
//            UIImage *sourceImage = [self createUIImageFromURL:url];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                completionBlock(sourceImage);
//            });
//        } else if ([localAttachment.contentType hasPrefix:@"video"]) {
//            NSURL *url = [localAttachment sourceImageURLWithFormatName:formatName];
//            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
//            AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
//            generator.appliesPreferredTrackTransform = YES;
//            CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
//
//            AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
//                if (result != AVAssetImageGeneratorSucceeded) {
//                    NSLog(@"couldn't generate thumbnail, error:%@", error);
//                }
//
//                CGSize thumbnailSize = [AttachmentSmallSquare isEqualToString:formatName] ? AttachmentSquareImageSize : AttachmentiPadSquareImageSize;
//                UIImage *sourceImage = [UIImage imageWithCGImage:image];
//                UIImage *thumbnail = [sourceImage thumbnailWithSize:thumbnailSize];
//                UIImage *playOverlay = [UIImage imageNamed:@"play_overlay"];
//
//                UIGraphicsBeginImageContextWithOptions(thumbnail.size, NO, 0.0);
//                [thumbnail drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
//                [playOverlay drawInRect:CGRectMake(0, 0, thumbnail.size.width, thumbnail.size.height)];
//                UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//                UIGraphicsEndImageContext();
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completionBlock(newImage);
//                });
//            };
//
//            [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
//        } else if ([localAttachment.contentType hasPrefix:@"audio"]) {
//            UIImage *sourceImage = [UIImage imageNamed:@"audio_thumbnail"];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                completionBlock(sourceImage);
//            });
//        } else {
//            UIImage *sourceImage = [UIImage imageNamed:@"paperclip_thumbnail"];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                completionBlock(sourceImage);
//            });
//        }
//    }];
//}


//@end
