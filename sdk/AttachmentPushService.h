//
//  AttachmentPushService.h
//  mage-ios-sdk
//
//

@import AFNetworking;

extern NSString * const kAttachmentBackgroundSessionIdentifier;

@interface AttachmentPushService : AFHTTPSessionManager

@property (copy) void (^backgroundSessionCompletionHandler)(void);

+ (instancetype) singleton;

- (void) start: (NSManagedObjectContext *) context;
- (void) stop;
@property (nonatomic) BOOL started;

@end
