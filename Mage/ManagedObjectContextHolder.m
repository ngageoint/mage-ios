//
//  ManagedObjectContextHolder.m
//  MAGE
//
//

#import "ManagedObjectContextHolder.h"
#import "AppDelegate.h"
#import "MAGE-Swift.h"

@implementation ManagedObjectContextHolder

- (NSManagedObjectContext *) managedObjectContext {
    return [MageInitializer setupCoreData];
}

@end
