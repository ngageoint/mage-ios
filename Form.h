//
//  Form.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface Form : NSObject

extern NSString * const MAGEFormFetched;
+ (NSURLSessionDownloadTask *) operationToPullFormForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure;

@end
