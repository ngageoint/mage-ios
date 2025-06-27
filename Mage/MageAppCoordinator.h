//
//  MageAppCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 9/5/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppContainerScheming.h"

@interface MageAppCoordinator : NSObject

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController forApplication: (UIApplication *) application andScheme: (id<AppContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;
- (void) start;

@end
