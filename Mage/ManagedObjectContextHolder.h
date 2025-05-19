//
//  ManagedObjectContextHolder.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ManagedObjectContextHolder : NSObject

- (NSManagedObjectContext *) managedObjectContext;

@end
