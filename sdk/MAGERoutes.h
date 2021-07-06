//
//  MAGERoutes.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteMethod.h"
#import "AttachmentRoutes.h"
#import "ObservationRoutes.h"

NS_ASSUME_NONNULL_BEGIN

@interface MAGERoutes : NSObject

+ (AttachmentRoutes *) attachment;
+ (ObservationRoutes *) observation;

@end

NS_ASSUME_NONNULL_END
