//
//  HttpManager.m
//  mage-ios-sdk
//

#import "HttpManager.h"
#import "UserUtility.h"
#import "NSString+Contains.h"
#import "MageServer.h"

NSString * const MAGETokenExpiredNotification = @"mil.nga.giat.mage.token.expired";

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    // TODO AFURLConnectionOperation replacement?
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
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
        _manager = [AFHTTPSessionManager manager];
        
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        responseSerializer.removesKeysWithNullValues = YES;
        _manager.responseSerializer = responseSerializer;
        
        _manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        [_manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        _sessionManager = [AFHTTPSessionManager manager];
        
        _downloadManager = [AFHTTPSessionManager manager];
        _downloadManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        _downloadManager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        [_downloadManager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkRequestDidFinish:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:nil];
    }
    return self;
}

-(void) setToken: (NSString *) token{
    [self setToken:token inSessionManager:_manager];
    [self setToken:token inSessionManager:_sessionManager];
    [self setToken:token inSessionManager:_downloadManager];
}

-(void) clearToken{
    [self setToken:nil];
}

-(void) setToken: (NSString *) token inSessionManager: (AFHTTPSessionManager *) sessionManager{
    [sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
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
        if (![[UserUtility singleton] isTokenExpired] && responseStatusCode == 401 && (![[request.URL path] safeContainsString:@"login"] && ![[request.URL path] safeContainsString:@"devices"]) ) {
            [[UserUtility singleton] expireToken];
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGETokenExpiredNotification object:response];
        }
    }
    return;
}
@end
