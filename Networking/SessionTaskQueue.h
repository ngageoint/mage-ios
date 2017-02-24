//
//  SessionTaskQueue.h
//  mage-ios-sdk
//
//  Created by Brian Osborn on 2/14/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionTask.h"

/**
 * Session Task Queue for running tasks in priority order with a specified max concurrent active tasks
 */
@interface SessionTaskQueue : NSObject

/**
 * Max concurrent tasks to execute simultaneously
 */
@property (nonatomic) int maxConcurrentTasks;

/**
 * Flag indicating whether to log requests and responses
 */
@property (nonatomic) BOOL log;

/**
 * Initialize with a default of 4 max concurrent tasks
 */
-(instancetype) init;

/**
 * Initialize with a default of 4 max concurrent tasks
 *
 * @param maxConcurrentTasks   max concurrent tasks to execute
 */
-(instancetype) initWithMaxConcurrentTasks: (int) maxConcurrentTasks;

/**
 * Close the task queue, canceling active tasks and removing queued tasks
 */
-(void) close;

/**
 * Close the task queue after processing active and queued tasks
 */
-(void) finishAndClose;

/**
 * Add a url session task to be run
 *
 * @param task   url session task
 */
-(void) addTask: (NSURLSessionTask *) task;

/**
 * Add a session task to be run
 *
 * @param task   session task
 */
-(void) addSessionTask: (SessionTask *) task;

/**
 *  Check if the queue of non active tasks contains the url session task with the identifier
 *
 *  @param taskIdentifier   url session task identifier
 *  @return YES if queue contains the task
 */
-(BOOL) queueContainsTaskIdentifier: (NSUInteger) taskIdentifier;

/**
 *  Get and remove the url session task with the identifier if it exists in the queue of non active tasks
 *
 *  @param taskIdentifier   url session task identifier
 *  @return url session task if found, nil if not
 */
-(NSURLSessionTask *) removeTaskFromQueueWithIdentifier: (NSUInteger) taskIdentifier;

/**
 *  Check if the queue of non active tasks contains the session task (including partially run) with id
 *
 *  @param taskId   session task id
 *  @return YES if queue contains the session task
 */
-(BOOL) queueContainsSessionTaskId: (NSString *) taskId;

/**
 *  Get and remove the session task (including partially run) with the id if it exists in the queue of non active tasks
 *
 *  @param taskId   session task id
 *  @return session task if found, nil if not
 */
-(SessionTask *) removeSessionTaskFromQueueWithId: (NSString *) taskId;

/**
 * If not already complete or active, remove a task from the waiting queue and run as a solo task
 *
 * @param taskIdentifier   url session task identifier
 */
-(BOOL) readdTaskWithIdentifier: (NSUInteger) taskIdentifier;

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
