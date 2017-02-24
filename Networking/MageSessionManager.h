//
//  MageSessionManager.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import "TaskSessionManager.h"
#import "SessionTask.h"

/**
 * MAGE Networking session manager for creating and executing network tasks
 */
@interface MageSessionManager : TaskSessionManager

extern NSString * const MAGETokenExpiredNotification;
extern NSInteger const MAGE_HTTPMaximumConnectionsPerHost;
extern NSInteger const MAGE_MaxConcurrentTasks;
extern NSInteger const MAGE_MaxConcurrentEvents;

/**
 * Get the MAGE Session Manager instance
 *
 * @return MAGE Session Manager
 */
+ (MageSessionManager *) manager;

/**
 * Set the MAGE token for request authentication
 *
 * @param token   request token
 */
-(void) setToken: (NSString *) token;

/**
 * Clear the MAGE token
 */
-(void) clearToken;

/**
 * Get a HTTP request serializer with token
 *
 * @return HTTP request serializer
 */
-(AFHTTPRequestSerializer *) httpRequestSerializer;

/**
 * Add a url session task to the task queue for execution
 *
 * @param task   url session task
 */
-(void) addTask: (NSURLSessionTask *) task;

/**
 * Add a session task to the task queue for execution
 *
 * @param task   session task
 */
-(void) addSessionTask: (SessionTask *) task;

/**
 * If not already complete or active, remove a task from the waiting queue and run as a solo task with the new priority
 *
 * @param taskIdentifier   url session task identifier
 * @param priority         new task priority
 */
-(BOOL) readdTaskWithIdentifier: (NSUInteger) taskIdentifier withPriority: (float) priority;

/**
 * If not already complete or fully active, remove a session task from the waiting queue and run with the new priority
 *
 * @param taskId     session task id
 * @param priority   new session task priority
 */
-(BOOL) readdSessionTaskWithId: (NSString *) taskId withPriority: (float) priority;

@end
