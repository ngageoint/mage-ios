//
//  ManagedObjectContextHolder.m
//  MAGE
//
//

#import "ManagedObjectContextHolder.h"
#import "AppDelegate.h"

@implementation ManagedObjectContextHolder

- (NSManagedObjectContext *) managedObjectContext {
    return [NSManagedObjectContext MR_defaultContext];
}

@end
