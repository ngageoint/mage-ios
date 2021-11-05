//
//  AttachmentRoutes.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "AttachmentRoutes.h"

#import "MAGE-Swift.h"

@implementation AttachmentRoutes

+ (instancetype) singleton {
    static AttachmentRoutes *routes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = [[self alloc] init];
    });
    return routes;
}

- (RouteMethod *) push: (Attachment *) attachment {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"PUT";
    method.route = [NSString stringWithFormat:@"%@/attachments/%@", attachment.observation.url, attachment.remoteId];
    return method;
}

- (RouteMethod *) deleteRoute: (Attachment *) attachment {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"DELETE";
    method.route = [NSString stringWithFormat:@"%@/attachments/%@", attachment.observation.url, attachment.remoteId];
    return method;
}

@end
