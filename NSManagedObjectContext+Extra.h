//
//  NSManagedObjectContext+Extra.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Extra)

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName withPredicate:(id)stringOrPredicate, ...;

@end
