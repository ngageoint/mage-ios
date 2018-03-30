//
//  MageSessionManager.m
//  mage-ios-sdk
//

#import "MageSessionManager.h"
#import "UserUtility.h"
#import "NSString+Contains.h"
#import "MageServer.h"
#import "SessionTaskQueue.h"

NSString * const MAGETokenExpiredNotification = @"mil.nga.giat.mage.token.expired";
NSString * const MAGEServerContactedAfterOfflineLogin = @"mil.nga.mage.server.contacted";
NSInteger const MAGE_HTTPMaximumConnectionsPerHost = 6;
NSInteger const MAGE_MaxConcurrentTasks = 6;
NSInteger const MAGE_MaxConcurrentEvents = 4;

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    }
    
    return request;
}

@interface MageSessionManager()

@property (nonatomic, strong)  NSString *token;
@property (nonatomic, strong)  SessionTaskQueue *taskQueue;

@end

static NSDictionary<NSNumber *, NSArray<NSNumber *> *> * eventTasks;

@implementation MageSessionManager

+(MageSessionManager *)manager
{
    static MageSessionManager *managerSingleton = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        managerSingleton = ([[MageSessionManager alloc] init]);
    });
    
    return managerSingleton;
}

- (id) init {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = MAGE_HTTPMaximumConnectionsPerHost;
    self = [super initWithSessionConfiguration:configuration];
    if(self){
        AFJSONResponseSerializer *responseJsonSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        responseJsonSerializer.removesKeysWithNullValues = YES;
        
        AFHTTPResponseSerializer *responseHttpSerializer = [AFHTTPResponseSerializer serializer];
        
        AFCompoundResponseSerializer *responseCompoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[responseJsonSerializer, responseHttpSerializer]];
        [self setResponseSerializer:responseCompoundSerializer];
        
        AFJSONRequestSerializer *requestJsonSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        [requestJsonSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [self setRequestSerializer:requestJsonSerializer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkRequestDidFinish:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:nil];
        
        _taskQueue = [[SessionTaskQueue alloc] initWithMaxConcurrentTasks:MAGE_MaxConcurrentTasks];
        [_taskQueue setLog:YES];
        
        NSLog(@"%@ Init, HTTP Maximum Connections Per Host: %d", NSStringFromClass([self class]), (int)configuration.HTTPMaximumConnectionsPerHost);
    }
    return self;
}

-(void) setToken: (NSString *) token{
    _token = token;
    [self setTokenInRequestSerializer:self.requestSerializer];
}

-(NSString *) getToken {
    return _token;
}

-(void) clearToken {
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
    if (request) {
        NSLog(@"Request URL: %@", request.URL);
        NSLog(@"Request Status: %lu", (unsigned long)[(NSHTTPURLResponse *)response statusCode]);
    }
    if (!request && !response) {
        return;
    }
    
    NSUInteger responseStatusCode = 0;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        responseStatusCode = (NSUInteger)[(NSHTTPURLResponse *)response statusCode];
        
        if ([[request.URL path] safeContainsString:@"login"] || [[request.URL path] safeContainsString:@"devices"] || [[request.URL path] safeContainsString:@"password"]) {
            return;
        }
        
        // if the token expired, kick the user out and make them log in again
        if ([[UserUtility singleton] isTokenExpired]) {
            return;
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // user was logged in online
        if ([[Authentication authenticationTypeToString:SERVER] isEqualToString:[defaults valueForKey:@"loginType"]]) {
            // if the user was online and the token was expired ie 401 we should force them to the login screen
            if (![[UserUtility singleton] isTokenExpired] && responseStatusCode == 401) {
                [[UserUtility singleton] expireToken];
                [[NSNotificationCenter defaultCenter] postNotificationName:MAGETokenExpiredNotification object:response];
                return;
            }
        } else if ([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]) {
            // if the user was logged in offline and a request makes it, we should tell them that they can try to login again
            if (responseStatusCode == 401) {
                [[NSNotificationCenter defaultCenter] postNotificationName:MAGEServerContactedAfterOfflineLogin object:response];
                return;
            }
        }
    }
    return;
}

-(void) addTask: (NSURLSessionTask *) task{
    [_taskQueue addTask:task];
}

-(void) addSessionTask: (SessionTask *) task{
    [_taskQueue addSessionTask:task];
}

-(BOOL) readdTaskWithIdentifier: (NSUInteger) taskIdentifier withPriority: (float) priority{
    return [_taskQueue readdTaskWithIdentifier:taskIdentifier withPriority:priority];
}
-(BOOL) readdSessionTaskWithId: (NSString *) taskId withPriority: (float) priority{
    return [_taskQueue readdSessionTaskWithId:taskId withPriority:priority];
}

+(void) setEventTasks: (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) tasks{
    eventTasks = tasks;
}

+(NSDictionary<NSNumber *, NSArray<NSNumber *> *> *) eventTasks{
    return eventTasks;
}

@end
