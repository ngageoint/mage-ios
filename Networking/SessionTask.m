//
//  SessionTask.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 2/14/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "SessionTask.h"

@interface SessionTask()

@property (nonatomic, strong) NSString *taskIdentifier;
@property (nonatomic, strong) NSMutableOrderedSet<NSURLSessionTask *> *tasks;

@end

@implementation SessionTask

static int defaultMaxConcurrentTasks = 1;

-(instancetype) init{
    return [self initWithTasks:nil andMaxConcurrentTasks:defaultMaxConcurrentTasks];
}

-(instancetype) initWithTask: (NSURLSessionTask *) task{
    return [self initWithTask:task andMaxConcurrentTasks:defaultMaxConcurrentTasks];
}

-(instancetype) initWithMaxConcurrentTasks: (int) maxConcurrentTasks{
    return [self initWithTasks:nil andMaxConcurrentTasks:maxConcurrentTasks];
}

-(instancetype) initWithTask: (NSURLSessionTask *) task andMaxConcurrentTasks: (int) maxConcurrentTasks{
    NSArray<NSURLSessionTask *> *tasks = nil;
    if(task != nil){
        tasks = [[NSArray alloc] initWithObjects:task, nil];
    }
    return [self initWithTasks:tasks andMaxConcurrentTasks:maxConcurrentTasks];
}

-(instancetype) initWithTasks: (NSArray<NSURLSessionTask *> *) tasks{
    return [self initWithTasks:tasks andMaxConcurrentTasks:defaultMaxConcurrentTasks];
}

-(instancetype) initWithTasks: (NSArray<NSURLSessionTask *> *) tasks andMaxConcurrentTasks: (int) maxConcurrentTasks{
    self = [super init];
    if(self){
        _taskIdentifier = [[NSUUID UUID] UUIDString];
        _tasks = [[NSMutableOrderedSet alloc] init];
        _priority = NSURLSessionTaskPriorityDefault;
        [self insertTasks: tasks];
        _maxConcurrentTasks = maxConcurrentTasks > 0 ? maxConcurrentTasks : defaultMaxConcurrentTasks;
    }
    return self;
}

-(NSString *) taskIdentifier{
    return _taskIdentifier;
}

-(void) addTask: (NSURLSessionTask *) task{
    if(task != nil){
        @synchronized(self) {
            [self insertTask:task];
        }
    }
}

-(void) addTasks: (NSArray<NSURLSessionTask *> *) tasks{
    if(tasks != nil){
        @synchronized(self) {
            [self insertTasks: tasks];
        }
    }
}

-(NSURLSessionTask *) removeTask{
    NSURLSessionTask *task = nil;
    if([self hasTask]){
        @synchronized(self) {
            if([self hasTask]){
                task = [_tasks objectAtIndex:0];
                [_tasks removeObjectAtIndex:0];
            }
        }
    }
    return task;
}

-(BOOL) hasTask{
    return [self remainingTasks] > 0;
}

-(int) remainingTasks{
    return _tasks.count;
}

/**
 *  Insert the tasks in priority order
 *
 *  @param tasks   url session tasks
 */
-(void) insertTasks: (NSArray<NSURLSessionTask *> *) tasks{
    if(tasks != nil){
        for(NSURLSessionTask *task in tasks){
            [self insertTask:task];
        }
    }
}

/**
 *  Insert the task in priority order
 *
 *  @param task   url session task
 */
-(void) insertTask: (NSURLSessionTask *) task{
    if(_tasks.count == 0){
        // Add the first task and set priority to the task priority
        _priority = task.priority;
        [_tasks addObject:task];
    }else{
        // Set the priority to max between task and current priority
        _priority = MAX(_priority, task.priority);
        // Insert the task by priority order
        NSUInteger insertLocation = [_tasks indexOfObject:task inSortedRange:NSMakeRange(0, _tasks.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSURLSessionTask * obj1, NSURLSessionTask * obj2){
            NSComparisonResult result = NSOrderedAscending;
            if(obj2.priority > obj1.priority){
                result = NSOrderedDescending;
            }
            return result;
        }];
        [_tasks insertObject:task atIndex:insertLocation];
    }
}

@end
