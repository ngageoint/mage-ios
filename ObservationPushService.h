//
//  ObservationPushService.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface ObservationPushService : NSObject

+ (instancetype) singleton;
- (void) start;
- (void) stop;

@end
