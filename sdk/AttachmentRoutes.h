//
//  AttachmentRoutes.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteMethod.h"

@class Attachment;
@class Observation;
NS_ASSUME_NONNULL_BEGIN

@interface AttachmentRoutes : NSObject

+ (instancetype) singleton;

- (RouteMethod *) push: (Attachment *) attachment;
- (RouteMethod *) deleteRoute: (Attachment *) attachment;

@end

NS_ASSUME_NONNULL_END
