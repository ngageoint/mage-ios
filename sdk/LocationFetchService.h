//
//  LocationFetchService.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const kLocationFetchFrequencyKey;

@interface LocationFetchService : NSObject

+ (instancetype) singleton;
- (void) start;
- (void) stop;
@property (nonatomic) BOOL started;
@end
