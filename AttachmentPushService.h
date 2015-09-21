//
//  AttachmentPushService.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface AttachmentPushService : NSObject

+ (instancetype) singleton;
- (void) start;
- (void) stop;

@end
