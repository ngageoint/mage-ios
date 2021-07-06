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
#import "Server.h"

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

- (void) startServicesAsInitial: (BOOL) initial {
    [[LocationService singleton] start];

    NSURLSessionDataTask *rolesPullTask = [Role operationToFetchRolesWithSuccess:nil failure:nil];
    
    NSURLSessionDataTask *usersPullTask = [User operationToFetchUsersWithSuccess:^{
        NSLog(@"Done with the initial user fetch, start location and observation services");
        [[LocationFetchService singleton] start];
        [[ObservationFetchService singleton] startAsInitial:initial];
    } failure:^(NSError *error) {
        NSLog(@"Failed to pull users");
    }];
    
    [[ObservationPushService singleton] start];
    [[AttachmentPushService singleton] start];
    
    // Add the operations to the queue
    NSArray<NSURLSessionTask *> *tasks = [[NSArray alloc] initWithObjects:rolesPullTask, usersPullTask, nil];
    SessionTask *sessionTask = [[SessionTask alloc] initWithTasks:tasks andMaxConcurrentTasks:1];
    [[MageSessionManager sharedManager] addSessionTask:sessionTask];

    [MageSessionManager setEventTasks:nil];
}

- (void) stopServices {
    [[LocationFetchService singleton] stop];
    [[ObservationFetchService singleton] stop];
    [[ObservationPushService singleton] stop];
    [[AttachmentPushService singleton] stop];
}

- (void) fetchEvents {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *myselfTask = [User operationToFetchMyselfWithSuccess:^{
        
        NSURLSessionDataTask *eventTask = [Event operationToFetchEventsWithSuccess:^{
            NSArray *events = [Event MR_findAll];
            [self fetchFormAndStaticLayerForEvents: events];
        } failure:^(NSError *error) {
            NSLog(@"Failure to pull events");
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
            NSArray *events = [Event MR_findAll];
            [self fetchFormAndStaticLayerForEvents: events];
        }];
        [manager addTask:eventTask];
    } failure:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
        NSArray *events = [Event MR_findAll];
        [self fetchFormAndStaticLayerForEvents: events];
    }];
    [manager addTask:myselfTask];
}

- (void) fetchFormAndStaticLayerForEvents: (NSArray *) events {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    SessionTask *task = [[SessionTask alloc] initWithMaxConcurrentTasks:(int)MAGE_MaxConcurrentEvents];
    
    NSMutableDictionary<NSNumber *, NSMutableArray<NSNumber *> *> * eventTasks = [[NSMutableDictionary alloc] init];
    NSNumber *currentEventId = [Server currentEventId];
    
    for (Event *e in events) {
        NSURLSessionTask *formTask = [Form operationToPullFormForEvent:e.remoteId
                                                        success: ^{
                                                            NSLog(@"Pulled form for event");
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEFormFetched object:e];
                                                        } failure:^(NSError* error) {
                                                            NSLog(@"failed to pull form for event");
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEFormFetched object:e];
                                                        }];
        if(currentEventId != nil && [currentEventId isEqualToNumber:e.remoteId]){
            [formTask setPriority:NSURLSessionTaskPriorityHigh];
            [manager addTask:formTask];
        }else{
            [task addTask:formTask];
            [self addTask:formTask toTasks:eventTasks forEvent:e];
        }
    }
    
//    for (Event *e in events) {
//
//        NSArray *staticLayers = [StaticLayer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", e.remoteId]];
//        for (StaticLayer *s in staticLayers) {
//            if (s.data == nil) {
//                NSLog(@"Static layer data is nil for %@ in event %@ retrieving data", s.name, s.eventId);
//                NSURLSessionTask *layerTask = [StaticLayer operationToFetchStaticLayerData:s];
//
//                if(currentEventId != nil && [currentEventId isEqualToNumber:e.remoteId]){
//                    [manager addTask:layerTask];
//                }else{
//                    [task addTask:layerTask];
//                    [self addTask:layerTask toTasks:eventTasks forEvent:e];
//                }
//            }
//        }
//    }
    
    [MageSessionManager setEventTasks:eventTasks];
    
    [task setPriority:NSURLSessionTaskPriorityLow];
    [manager addSessionTask:task];
}

-(void) addTask: (NSURLSessionTask *) task toTasks: (NSMutableDictionary<NSNumber *, NSMutableArray<NSNumber *> *> *) eventTasks forEvent: (Event *) event{
    NSNumber *taskIdentifier = [NSNumber numberWithUnsignedInteger:task.taskIdentifier];
    NSMutableArray<NSNumber *> * tasks = [eventTasks objectForKey:event.remoteId];
    if(tasks == nil){
        tasks = [[NSMutableArray alloc] init];
        [eventTasks setObject:tasks forKey:event.remoteId];
    }
    [tasks addObject:taskIdentifier];
}

@end
