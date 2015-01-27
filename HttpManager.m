//
//  HttpManager.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/9/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "HttpManager.h"

NSString * const MAGETokenExpiredNotification = @"mil.nga.giat.mage.token.expired";

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    if ([[notification object] isKindOfClass:[AFURLConnectionOperation class]]) {
        request = [(AFURLConnectionOperation *)[notification object] request];
    } else if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    }
    
    return request;
}

@implementation HttpManager

static HttpManager *sharedSingleton = nil;

+ (HttpManager *) singleton {
    
    if (sharedSingleton == nil) {
        sharedSingleton = [[super allocWithZone:NULL] init];
    }

    return sharedSingleton;
}

- (id) init {
    if ((self = [super init])) {
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        _manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        //_sessionManager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidCompleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingOperationDidFinishNotification object:nil];
    }
    return self;
}

- (void)networkRequestDidFinish:(NSNotification *)notification {
    NSURLRequest *request = AFNetworkRequestFromNotification(notification);
    NSURLResponse *response = [notification.object response];
    
    if (!request && !response) {
        return;
    }
    
    NSUInteger responseStatusCode = 0;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        responseStatusCode = (NSUInteger)[(NSHTTPURLResponse *)response statusCode];
        
        // token expired
        if (responseStatusCode == 401 && (![[request.URL path] containsString:@"login"] && ![[request.URL path] containsString:@"devices"]) ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGETokenExpiredNotification object:response];
        }
    }
    return;
}
@end
