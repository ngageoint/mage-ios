//
//  ObservationPushService.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import "Observation.h"

@protocol ObservationPushDelegate <NSObject>

@required

- (void) didPushObservation:(Observation *) observation success:(BOOL) success error:(NSError *) error;

@end

@interface ObservationPushService : NSObject

+ (instancetype) singleton;
- (void) start;
- (void) stop;

- (void) addObservationPushDelegate:(id<ObservationPushDelegate>) delegate;
- (void) removeObservationPushDelegate:(id<ObservationPushDelegate>) delegate;

- (void) pushObservations:(NSArray *) observations;
- (BOOL) isPushingFavorites;
- (BOOL) isPushingObservations;
- (BOOL) isPushingImportant;
@end
