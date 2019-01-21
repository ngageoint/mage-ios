//
//  UserUtility.m
//  mage-ios-sdk
//
//

@import DateTools;

#import "UserUtility.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "StoredPassword.h"

@interface UserUtility()

@property BOOL expired;

@end

@implementation UserUtility

+ (id) singleton {
    static UserUtility *userUtility = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userUtility = [[self alloc] init];
    });
    return userUtility;
}

- (id) init {
    if (self = [super init]) {
        self.expired = NO;
    }
    return self;
}

- (void) resetExpiration {
    self.expired = NO;
}

- (void) acceptConsent {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *loginParameters = [[defaults objectForKey:@"loginParameters"] mutableCopy];
    [loginParameters setValue:@"agree" forKey:@"acceptedConsent"];
    [defaults setObject:loginParameters forKey:@"loginParameters"];
    [defaults synchronize];
}

- (BOOL) isTokenExpired{
    if (self.expired) return YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *loginParameters = [defaults objectForKey:@"loginParameters"];
    
    NSString *acceptedConsent = [loginParameters objectForKey:@"acceptedConsent"];
    
    NSDate *tokenExpirationDate = [loginParameters objectForKey:@"tokenExpirationDate"];
    if (acceptedConsent != nil && [acceptedConsent isEqualToString:@"agree"] && tokenExpirationDate != nil && [tokenExpirationDate isKindOfClass:NSDate.class]) {
        NSDate *currentDate = [NSDate date];
        NSLog(@"current date %@ token expiration %@", currentDate, tokenExpirationDate);
        self.expired = [currentDate isLaterThan:tokenExpirationDate];
        if (self.expired) {
            [self expireToken];
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGETokenExpiredNotification object:nil];
        }
        return self.expired;
    }
    self.expired = YES;
    return self.expired;
}

- (void) expireToken {
    [StoredPassword clearToken];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *loginParameters = [[defaults objectForKey:@"loginParameters"] mutableCopy];
    
    [loginParameters removeObjectForKey:@"tokenExpirationDate"];
    [loginParameters removeObjectForKey:@"acceptedConsent"];
    
    [[MageSessionManager manager] clearToken];
    
    [defaults setObject:loginParameters forKey:@"loginParameters"];
    
    [defaults removeObjectForKey:@"loginType"];
    
    [defaults synchronize];
    self.expired = YES;
}

- (void) logoutWithCompletion: (void (^)(void)) completion {
    NSString *url = [NSString stringWithFormat:@"%@/api/logout", [MageServer baseURL]];

    MageSessionManager *manager = [MageSessionManager manager];
    __weak typeof(self) weakSelf = self;

    NSURLSessionDataTask *task = [manager POST_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"Logged out");
        [weakSelf expireToken];
        completion();
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [weakSelf expireToken];
        completion();
    }];
    [manager addTask:task];
}

@end
