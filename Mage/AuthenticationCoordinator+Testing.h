//
//  AuthenticationCoordinator 2.h
//  MAGE
//
//  Created by Brent Michalski on 3/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


#import "AuthenticationCoordinator.h"

@interface AuthenticationCoordinator (Testing)

@property (nonatomic, strong, nullable) MageServer *server; // ✅ Expose for tests only

@end