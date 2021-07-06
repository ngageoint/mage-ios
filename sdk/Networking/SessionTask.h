//
//  SessionTask.h
//  mage-ios-sdk
//
//  Created by Brian Osborn on 2/14/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A session task contains one or more NSURLSessionTask to submit to a SessionTaskQueue
 */
@interface SessionTask : NSObject

/**
 * Max tasks from this session task to run concurrently.  A value of one results in sequential execution.
 */
@property (nonatomic) int maxConcurrentTasks;

/**
 * Task priority between 0.0 and 1.0. Defaults to the max NSURLSessionTask.priority.
 */
@property (nonatomic) float priority;

/**
 * Initialize with no tasks and set to one max concurrent task
 */
-(instancetype) init;

/**
 * Initialize with a task and set to one max concurrent task
 *
 * @param task   url session task
 */
-(instancetype) initWithTask: (NSURLSessionTask *) task;

/**
 * Initialize with no tasks and specified max concurrent tasks
 *
 * @param maxConcurrentTasks   max concurrent tasks to run from this session
 */
-(instancetype) initWithMaxConcurrentTasks: (int) maxConcurrentTasks;

/**
 * Initialize with a task and specified max concurrent tasks
 *
 * @param task                 url session task
 * @param maxConcurrentTasks   max concurrent tasks to run from this session
 */
-(instancetype) initWithTask: (NSURLSessionTask *) task andMaxConcurrentTasks: (int) maxConcurrentTasks;

/**
 * Initialize with tasks and set to one max concurrent task. Added tasks are sorted by their priorities.
 *
 * @param tasks   url session tasks
 */
-(instancetype) initWithTasks: (NSArray<NSURLSessionTask *> *) tasks;

/**
 * Initialize with tasks and specified max concurrent tasks. Added tasks are sorted by their priorities.
 *
 * @param tasks                url session tasks
 * @param maxConcurrentTasks   max concurrent tasks to run from this session
 */
-(instancetype) initWithTasks: (NSArray<NSURLSessionTask *> *) tasks andMaxConcurrentTasks: (int) maxConcurrentTasks;

/**
 *  Get the unique session task id
 *
 *  @return task id
 */
-(NSString *) taskId;

/**
 *  Add a url session task by priority order
 *
 *  @param task   url session task
 */
-(void) addTask: (NSURLSessionTask *) task;

/**
 *  Add url session tasks each by priority order
 *
 *  @param tasks   url session tasks
 */
-(void) addTasks: (NSArray<NSURLSessionTask *> *) tasks;

/**
 *  Remove the next session task with highest priority
 *
 *  @return url session task or nil if no tasks
 */
-(NSURLSessionTask *) removeTask;

/**
 *  Determine if there are more tasks
 *
 *  @return YES if at least one task
 */
-(BOOL) hasTask;

/**
 *  Get the count of remaining tasks
 *
 *  @return count of tasks
 */
-(int) remainingTasks;

/**
 *  Determine if more than one url session tasks were added to this session task
 *
 *  @return YES if contains multiple url session tasks
 */
-(BOOL) multi;

/**
 *  Check if contains the task with the identifier
 *
 *  @param taskIdentifier   url session task identifier
 *  @return YES if contains the task
 */
-(BOOL) containsTaskIdentifier: (NSUInteger) taskIdentifier;

/**
 *  Get and remove the task with the identifier if it exists
 *
 *  @param taskIdentifier   url session task identifier
 *  @return url session task if found, nil if not
 */
-(NSURLSessionTask *) removeTaskWithIdentifier: (NSUInteger) taskIdentifier;

@end
