//
//  Form.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface Form : NSObject

+ (NSOperation *) operationToPullFormForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure;

@end
