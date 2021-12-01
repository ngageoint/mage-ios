//
//  MAGERoutes.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "MAGERoutes.h"
#import "MAGE-Swift.h"

// legacy imports
#import "AttachmentRoutes_Server5.h"

@implementation MAGERoutes

+ (AttachmentRoutes *) attachment {
    if ([MageServer isServerVersion5]) {
        return [AttachmentRoutes_Server5 singleton];
    }
    return [AttachmentRoutes singleton];
}

+ (ObservationRoutes *) observation {
    return [ObservationRoutes singleton];
}

@end
