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

@end
