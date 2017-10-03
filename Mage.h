//
//  Mage.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface Mage : NSObject

+ (instancetype) singleton;

- (void) startServicesAsInitial: (BOOL) initial;
- (void) stopServices;
- (void) fetchEvents;
- (void) fetchFormAndStaticLayerForEvents: (NSArray *) events;

@end
