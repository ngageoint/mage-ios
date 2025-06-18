//
//  AuthenticationTests.m
//  MAGETests
//
//  Created by Dan Barela on 1/9/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

@import OHHTTPStubs;

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AuthenticationCoordinator.h"
#import "LoginViewController.h"
#import "MageSessionManager.h"
#import "StoredPassword.h"
#import "Authentication.h"
#import "MageOfflineObservationManager.h"
#import "MagicalRecord+MAGE.h"
#import "MAGE-Swift.h"

@interface ServerURLController ()
@property (strong, nonatomic) NSString *error;
@end

@interface AuthenticationCoordinator ()
@property (strong, nonatomic) NSString *urlController;
- (void) unableToAuthenticate: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) workOffline: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) returnToLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) changeServerURL;
@end

@interface AuthenticationTests : XCTestCase

@end

@interface AuthenticationTestDelegate : NSObject

@end

@interface AuthenticationTestDelegate() <AuthenticationDelegate>

@end

@implementation AuthenticationTestDelegate

-(void) authenticationSuccessful {
}

@end

@implementation AuthenticationTests

- (void)setUp {
    [super setUp];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown {
    [super tearDown];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
    [HTTPStubs removeAllStubs];
}

//- (void) skipped_testLoginWithRegisteredDeviceAndRandomToken {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    [[MageSessionManager sharedManager] setToken:@"oldtoken"];
//    [StoredPassword persistTokenToKeyChain:@"oldtoken"];
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://magetest" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    id apiStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        NSLog(@"URL is %@", request.URL.absoluteString);
//        NSLog(@"does it match /api? %@", request.URL.path);
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id apiSigninStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        NSLog(@"does it match /auth/local/signin? %@", request.URL.path);
//        NSLog(@"is it? %d", [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"]);
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"signinSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id apiAuthorizeStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        NSLog(@"does it match /auth/local/authorize? %@", request.URL.path);
//
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/authorize"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"authorizeLocalSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id myselfStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        NSLog(@"does it match /api/users/myself? %@", request.URL.path);
//        NSString *authorizationHeader = [request.allHTTPHeaderFields valueForKey:@"Authorization"];
//        NSLog(@"Authorization Header is %@", authorizationHeader);
//        if ([request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/users/myself"]) {
//            XCTAssertTrue([authorizationHeader isEqualToString:@"Bearer TOKEN"]);
//        }
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/users/myself"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        return [HTTPStubsResponse responseWithJSONObject:[[NSDictionary alloc] init] statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    @"5.0.0", @"appVersion",
//                                    nil];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /api/login complete"];
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//            [disclaimerDelegate disclaimerAgree];
//            OCMVerifyAll(delegatePartialMock);
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////            NSString *token = [StoredPassword retrieveStoredToken];
////            NSString *mageSessionToken = [[MageSessionManager sharedManager] getToken];
////            XCTAssertTrue([token isEqualToString:@"TOKEN"]);
////            XCTAssertTrue([token isEqualToString:mageSessionToken]);
////
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            XCTestExpectation* myselfResponseArrived = [self expectationWithDescription:@"response of /api/users/myself complete"];
//
//            NSURLSessionDataTask *task = [User operationToFetchMyselfWithSuccess:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
//                NSLog(@"user");
//                [myselfResponseArrived fulfill];
//            } failure:^(NSURLSessionDataTask * _Nullable task , NSError * _Nonnull error ) {
//                NSLog(@"error %@", error);
//                [myselfResponseArrived fulfill];
//            }];
//
//            [[MageSessionManager sharedManager] addTask:task];
//
//            [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//                OCMVerifyAll(navControllerPartialMock);
//            }];
//        }];
//
//    }];
//}
//
//- (void) skipped_testRegisterDevice {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    @"5.0.0", @"appVersion",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            HTTPStubsResponse *response = [[HTTPStubsResponse alloc] init];
//            response.statusCode = 401;
//
//            return response;
//        }];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/devices"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"registrationSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Registration Sent"]);
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            XCTAssertTrue(authenticationStatus == REGISTRATION_SUCCESS);
////            [loginResponseArrived fulfill];
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginWithRegisteredDevice {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSLog(@"api request recieved and handled");
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    @"5.0.0", @"appVersion",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"loginSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//            [disclaimerDelegate disclaimerAgree];
//            OCMVerifyAll(delegatePartialMock);
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginWithRegisteredDeviceChangingUserWithOfflineObservations {
//    User *u = [User MR_createEntity];
//    u.username = @"old";
//
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    id offlineManagerMock = OCMClassMock([MageOfflineObservationManager class]);
//    OCMStub(ClassMethod([offlineManagerMock offlineObservationCount]))._andReturn([NSNumber numberWithInt:1]);
//
//    id userMock = [OCMockObject mockForClass:[User class]];
//    [[[userMock stub] andReturn:u] fetchCurrentUserWithContext:[OCMArg any]];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    @"5.0.0", @"appVersion",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"signinSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Loss of Unsaved Data"]);
//            [loginResponseArrived fulfill];
//        });
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginWithRegisteredDeviceChangingUserWithoutOfflineObservations {
//    User *u = [User MR_createEntity];
//    u.username = @"old";
//
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"signinSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//            [disclaimerDelegate disclaimerAgree];
//            OCMVerifyAll(delegatePartialMock);
//        });
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginFailWithRegisteredDevice {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            HTTPStubsResponse *response = [[HTTPStubsResponse alloc] init];
//            response.statusCode = 401;
//
//            return response;
//        }];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/devices"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:401 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_ERROR);
////            [loginResponseArrived fulfill];
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testWorkOffline {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
//    [defaults setObject:[NSNumber numberWithDouble:2880] forKey:@"tokenExpirationLength"];
//    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
//    [[[storedPasswordMock stub] andReturn:@"goodpassword"] retrieveStoredPassword];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"goodpassword", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
//            return [HTTPStubsResponse responseWithError:notConnectedError];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//        id coordinatorMock = OCMPartialMock(coordinator);
//        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//        }).andForwardToRealObject();
//
////        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
////            __unsafe_unretained UIAlertController *alert;
////            [invocation getArgument:&alert atIndex:2];
////            XCTAssertTrue([alert.title isEqualToString:@"Disconnected Login"]);
////            [coordinator workOffline: parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////                NSLog(@"Auth Success");
////                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////                XCTAssertTrue([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]);
////                XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////                [loginResponseArrived fulfill];
////            }];
////        });
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [disclaimerDelegate disclaimerAgree];
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            NSLog(@"Unable to authenticate");
////            XCTFail(@"Should not be in here");
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            OCMVerifyAll(navControllerPartialMock);
//            OCMVerifyAll(coordinatorMock);
//            [storedPasswordMock stopMocking];
//        }];
//    }];
//}
//
//- (void) skipped_testWorkOfflineBadPassword {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
//
//    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
//    [[[storedPasswordMock stub] andReturn:@"goodpassword"] retrieveStoredPassword];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"badpassword", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
//            return [HTTPStubsResponse responseWithError:notConnectedError];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//        id coordinatorMock = OCMPartialMock(coordinator);
//        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//        }).andForwardToRealObject();
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Disconnected Login"]);
//            [coordinator workOffline: parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
//                NSLog(@"Auth error");
//                XCTAssertTrue(authenticationStatus == AUTHENTICATION_ERROR);
//            }];
//        });
//
//        OCMStub([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            XCTFail(@"Should not have pushed the disclaimer");
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            NSLog(@"Unable to authenticate");
////            XCTFail(@"Should not be in here");
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            OCMVerifyAll(navControllerPartialMock);
//            OCMVerifyAll(coordinatorMock);
//            [storedPasswordMock stopMocking];
//        }];
//
//    }];
//
//}
//
//- (void) skipped_testUnableToWorkOfflineDueToNoSavedPassword {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
//
//    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
//    [[[storedPasswordMock stub] andReturn:nil] retrieveStoredPassword];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"goodpassword", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
//            return [HTTPStubsResponse responseWithError:notConnectedError];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//        id coordinatorMock = OCMPartialMock(coordinator);
//        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//        }).andForwardToRealObject();
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Unable to Login"]);
//            [coordinator returnToLogin: ^(AuthenticationStatus authenticationStatus, NSString *errorString) {
//                NSLog(@"Auth error");
//                XCTAssertTrue([@"We are unable to connect to the server. Please try logging in again when your connection to the internet has been restored." isEqualToString:errorString]);
//                XCTAssertTrue(authenticationStatus == UNABLE_TO_AUTHENTICATE);
//            }];
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            NSLog(@"Unable to authenticate");
////            XCTFail(@"Should not be in here");
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            OCMVerifyAll(navControllerPartialMock);
//            OCMVerifyAll(coordinatorMock);
//            [storedPasswordMock stopMocking];
//        }];
//    }];
//}
//
//- (void)skipped_testSetURLSuccess {
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [responseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
//    [serverUrlDelegate setServerURL:[NSURL URLWithString:@"https://mage.geointservices.io"]];
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//    }];
//}
//
//- (void)skipped_testSetURLCancel {
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        NSLog(@"server url controller pushed");
//    });
//    OCMExpect([navControllerPartialMock popViewControllerAnimated:NO])._andDo(^(NSInvocation *invocation) {
//        [responseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        XCTFail(@"No network requests should be made when the cancel action is taken after setting the server url");
//        return nil;
//    }];
//
//    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
//    [coordinator changeServerURL];
//    [serverUrlDelegate cancelSetServerURL];
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//    }];
//}
//
//- (void)skipped_testSetURLFailVersion {
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    __block id serverUrlControllerMock;
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO]);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@""]);
//
////    [coordinator start];
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        serverUrlControllerMock = OCMPartialMock(coordinator.urlController);
//        OCMExpect([serverUrlControllerMock showError:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            [responseArrived fulfill];
//        });
//        NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
//    [serverUrlDelegate setServerURL:[NSURL URLWithString:@"https://mage.geointservices.io"]];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//        OCMVerifyAll(serverUrlControllerMock);
//    }];
//}
//
//- (void) skipped_testStartWithVersionFail {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    __block id serverUrlControllerMock;
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        serverUrlControllerMock = OCMPartialMock(coordinator.urlController);
//        NSString *error = (NSString *)[serverUrlControllerMock error];
//
//        XCTAssertTrue([@"This version of the app is not compatible with version 4.0.0 of the server." isEqualToString:error]);
//        [responseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//    }];
//}

@end
