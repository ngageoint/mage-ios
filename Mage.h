//
//  Mage.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface Mage : NSObject

+ (instancetype) singleton;

- (void) startServices;
- (void) stopServices;
- (void) fetchEvents;

@end
