//
//  DisconnectedLogin.m
//  MAGETests
//
//  Created by Dan Barela on 2/26/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//[[UserUtility singleton] expireToken];
//[[NSNotificationCenter defaultCenter] postNotificationName:MAGETokenExpiredNotification object:response];
//

@import OHHTTPStubs;

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AuthenticationCoordinator.h"
#import "LoginViewController.h"
#import "DisclaimerViewController.h"
#import "MageSessionManager.h"
#import "StoredPassword.h"
#import "Event.h"
#import "Authentication.h"
#import "UserUtility.h"

@interface AuthenticationCoordinator ()
- (void) unableToAuthenticate: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) workOffline: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
@end

@interface DisconnectedLogin : XCTestCase

@end

@implementation DisconnectedLogin

- (void)setUp {
    [super setUp];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
}

- (void)tearDown {
    [super tearDown];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
    [OHHTTPStubs removeAllStubs];
}

- (void) testLoginDisconnectedThenRegainConnection {
    NSString *baseUrlKey = @"baseServerUrl";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    [defaults setObject:[NSNumber numberWithDouble:2880] forKey:@"tokenExpirationLength"];
    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
    
    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
    [[[storedPasswordMock stub] andReturn:@"goodpassword"] retrieveStoredPassword];
    
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    
    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
    
    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:nil];
    
    id navControllerPartialMock = OCMPartialMock(navigationController);
    
    NSURL *url = [MageServer baseURL];
    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
    
    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
        [apiResponseArrived fulfill];
    });
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [coordinator start];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        // response came back from the server and we went to the login screen
        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
        
        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
        
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"test", @"username",
                                    @"goodpassword", @"password",
                                    @"uuid", @"uid",
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"local", @"identifier", nil],
                                    @"strategy",
                                    @"5.0.0", @"appVersion",
                                    nil];
        
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
            return [OHHTTPStubsResponse responseWithError:notConnectedError];
        }];
        
        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
        id coordinatorMock = OCMPartialMock(coordinator);
        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            [loginResponseArrived fulfill];
        }).andForwardToRealObject();
        
        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
            __unsafe_unretained UIAlertController *alert;
            [invocation getArgument:&alert atIndex:2];
            XCTAssertTrue([alert.title isEqualToString:@"Disconnected Login"]);
            [coordinator workOffline: parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
                NSLog(@"Auth Success");
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                XCTAssertTrue([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]);
                XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
            }];
        });
        
        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
            [disclaimerDelegate disclaimerAgree];
        });
        
        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
            NSLog(@"Unable to authenticate");
            XCTFail(@"Should not be in here");
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
            OCMVerifyAll(navControllerPartialMock);
            OCMVerifyAll(coordinatorMock);
            
            // we are now connected offline.  Make a call to the server that returns a 401 and verify that the user is not kicked out
            id userUtilityMock = OCMPartialMock([UserUtility singleton]);
            OCMReject([userUtilityMock expireToken]);
            
            XCTestExpectation* eventResponseArrived = [self expectationWithDescription:@"response of /api/events complete"];
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/events"];
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                OHHTTPStubsResponse *response = [[OHHTTPStubsResponse alloc] init];
                response.statusCode = 401;
                
                return response;
            }];
            
            NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
            id notificationCenterMock = OCMPartialMock(defaultCenter);

            OCMExpect([notificationCenterMock postNotificationName:MAGEServerContactedAfterOfflineLogin object:[OCMArg any]]);
            
            NSURLSessionDataTask *eventFetchTask = [Event operationToFetchEventsWithSuccess:^{
                NSLog(@"success");
                [eventResponseArrived fulfill];
            } failure:^(NSError* error) {
                NSLog(@"error");
                [eventResponseArrived fulfill];
            }];
            
            [[MageSessionManager manager] addTask:eventFetchTask];

            [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
                OCMVerifyAll(userUtilityMock);
                [storedPasswordMock stopMocking];
            }];
        }];
    }];
}

@end
