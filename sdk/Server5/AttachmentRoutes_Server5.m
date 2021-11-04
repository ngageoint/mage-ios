//
//  AttachmentRoutes_Server5.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "AttachmentRoutes_Server5.h"
#import "Attachment.h"
#import "MAGE-Swift.h"

@implementation AttachmentRoutes_Server5

+ (instancetype) singleton {
    static AttachmentRoutes_Server5 *routes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = [[self alloc] init];
    });
    return routes;
}

- (RouteMethod *) push: (Attachment *) attachment {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"POST";
    method.route = [NSString stringWithFormat:@"%@/%@", attachment.observation.url, @"attachments"];
    return method;
}

- (RouteMethod *) deleteRoute: (Attachment *) attachment {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"DELETE";
    method.route = [NSString stringWithFormat:@"%@/attachments/%@", attachment.observation.url, attachment.remoteId];
    return method;
}

@end
