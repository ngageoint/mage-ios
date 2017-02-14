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
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    }
    
    return request;
}

@interface HttpManager()

@property (nonatomic, strong)  NSString * token;

@end

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
        
        AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        jsonSerializer.removesKeysWithNullValues = YES;
        
        AFHTTPResponseSerializer * httpSerializer = [AFHTTPResponseSerializer serializer];
        
        AFCompoundResponseSerializer *compoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonSerializer, httpSerializer]];
        
        _manager = [AFHTTPSessionManager manager];
        _manager.responseSerializer = compoundSerializer;
        
        _manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        [_manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkRequestDidFinish:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:nil];
    }
    return self;
}

-(void) setToken: (NSString *) token{
    _token = token;
    [self setTokenInRequestSerializer:_manager.requestSerializer];
}

-(void) clearToken{
    [self setToken:nil];
}

-(void) setTokenInRequestSerializer: (AFHTTPRequestSerializer *) requestSerializer{
    [requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", _token] forHTTPHeaderField:@"Authorization"];
}

-(AFHTTPRequestSerializer *) httpRequestSerializer{
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [self setTokenInRequestSerializer:requestSerializer];
    return requestSerializer;
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
