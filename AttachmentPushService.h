//
//  AttachmentPushService.h
//  mage-ios-sdk
//
//

#import <AFNetworking.h>

extern NSString * const kAttachmentBackgroundSessionIdentifier;

@interface AttachmentPushService : AFHTTPSessionManager

@property (copy) void (^backgroundSessionCompletionHandler)();

+ (instancetype) singleton;

- (void) start;
- (void) stop;

@end
