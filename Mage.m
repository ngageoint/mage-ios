  //
//  Mage.m
//  mage-ios-sdk
//
//

#import "Mage.h"
#import "MageSessionManager.h"
#import "LocationService.h"
#import "LocationFetchService.h"
#import "ObservationFetchService.h"
#import "ObservationPushService.h"
#import "AttachmentPushService.h"
#import "User.h"
#import "Role.h"
#import "Event.h"
#import "Form.h"
#import "Layer.h"
#import "MageServer.h"
#import "StaticLayer.h"

@implementation Mage

+ (instancetype) singleton {
    static Mage *mage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mage = [[self alloc] init];
    });
    return mage;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) startServices {
    [[LocationService singleton] start];

    NSURLSessionDataTask *usersPullTask = [User operationToFetchUsersWithSuccess:^{
        NSLog(@"Done with the initial user fetch, start location and observation services");
        [[LocationFetchService singleton] start];
        [[ObservationFetchService singleton] start];
    } failure:^(NSError *error) {
        NSLog(@"Failed to pull users");
    }];
    
    NSURLSessionDataTask *rolesPullTask = [Role operationToFetchRolesWithSuccess:^{
        [usersPullTask resume];
    } failure:nil];
    
    [[ObservationPushService singleton] start];
    [[AttachmentPushService singleton] start];
    
    // Add the operations to the queue
    [rolesPullTask resume];
}

- (void) stopServices {
    [[LocationFetchService singleton] stop];
    [[ObservationFetchService singleton] stop];
    [[ObservationPushService singleton] stop];
    [[AttachmentPushService singleton] stop];
}

- (void) fetchEvents {
    NSURLSessionDataTask *myselfTask = [User operationToFetchMyselfWithSuccess:^{
        
        NSURLSessionDataTask *eventTask = [Event operationToFetchEventsWithSuccess:^{
            NSArray *events = [Event MR_findAll];
            [self addFormFetchOperationsForEvents: events];
            // also go fetch any static data for the static layers
            [self addStaticLayerFetchOperations:events];
        } failure:^(NSError *error) {
            NSLog(@"Failure to pull events");
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
        }];
        [eventTask resume];
    } failure:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
    }];
    [myselfTask resume];
}

- (void) addFormFetchOperationsForEvents: (NSArray *) events {
    for (Event *e in events) {
        NSURLSessionTask *formTask = [Form operationToPullFormForEvent:e.remoteId
                                                        success: ^{
                                                            NSLog(@"Pulled form for event");
                                                        } failure:^(NSError* error) {
                                                            NSLog(@"failed to pull form for event");
                                                        }];
        
        [formTask resume];
    }
}

- (void) addStaticLayerFetchOperations: (NSArray *) events {
    for (Event *e in events) {
        
        NSArray *staticLayers = [StaticLayer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", e.remoteId]];
        for (StaticLayer *s in staticLayers) {
            if (s.data == nil) {
                NSLog(@"Static layer data is nil for %@ in event %@ retrieving data", s.name, s.eventId);
                NSURLSessionDataTask *layerTask = [StaticLayer operationToFetchStaticLayerData:s];
                [layerTask resume];
            }
        }
    }
}

@end
