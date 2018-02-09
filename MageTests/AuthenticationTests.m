//
//  AuthenticationTests.m
//  MAGETests
//
//  Created by Dan Barela on 1/9/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs.h>
#import <OHHTTPStubsResponse+JSON.h>
#import <OHPathHelpers.h>
#import <OCMock.h>
#import "AuthenticationCoordinator.h"
#import "ServerURLController.h"
#import "LoginViewController.h"
#import "DisclaimerViewController.h"
#import <MageSessionManager.h>
#import <StoredPassword.h>
#import <Observation.h>

@interface ServerURLController ()
@property (strong, nonatomic) NSString *error;
@end

@interface AuthenticationCoordinator ()
@property (strong, nonatomic) NSString *urlController;
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
}

- (void)tearDown {
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
}

- (void) testLoginWithRegisteredDeviceAndRandomToken {
    NSString *baseUrlKey = @"baseServerUrl";
    
    [[MageSessionManager manager] setToken:@"oldtoken"];
    [StoredPassword persistTokenToKeyChain:@"oldtoken"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    
    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
    
    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
    id delegatePartialMock = OCMPartialMock(delegate);
    OCMExpect([delegatePartialMock authenticationSuccessful]);
    
    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate];
    
    id navControllerPartialMock = OCMPartialMock(navigationController);
    
    NSURL *url = [MageServer baseURL];
    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
    
    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
        [apiResponseArrived fulfill];
    });
    
    id apiStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSLog(@"URL is %@", request.URL.absoluteString);
        NSLog(@"does it match /api? %@", request.URL.path);
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    id apiLoginStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSLog(@"does it match /api/login? %@", request.URL.path);

        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/login"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"loginSuccess.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];

    id myselfStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSLog(@"does it match /api/users/myself? %@", request.URL.path);
        NSString *authorizationHeader = [request.allHTTPHeaderFields valueForKey:@"Authorization"];
        NSLog(@"Authorization Header is %@", authorizationHeader);
        if ([request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/users/myself"]) {
            XCTAssertTrue([authorizationHeader isEqualToString:@"Bearer TOKEN"]);
        }
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/users/myself"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithJSONObject:[[NSDictionary alloc] init] statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [coordinator start];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        // response came back from the server and we went to the login screen
        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;

        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"test", @"username",
                                    @"test", @"password",
                                    @"uuid", @"uid",
                                    nil];

        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /api/login complete"];

        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
            [loginResponseArrived fulfill];
            [disclaimerDelegate disclaimerAgree];
            OCMVerifyAll(delegatePartialMock);
        });

        [loginDelegate loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
            // login complete
            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
            NSString *token = [StoredPassword retrieveStoredToken];
            NSString *mageSessionToken = [[MageSessionManager manager] getToken];
            XCTAssertTrue([token isEqualToString:@"TOKEN"]);
            XCTAssertTrue([token isEqualToString:mageSessionToken]);

        }];

        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
            XCTestExpectation* myselfResponseArrived = [self expectationWithDescription:@"response of /api/users/myself complete"];
            
            NSURLSessionDataTask *task = [User operationToFetchMyselfWithSuccess:^{
                NSLog(@"user");
                [myselfResponseArrived fulfill];
            } failure:^(NSError * _Nonnull error) {
                NSLog(@"error %@", error);
                [myselfResponseArrived fulfill];
            }];
            
            [[MageSessionManager manager] addTask:task];

            [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
                OCMVerifyAll(navControllerPartialMock);
            }];
        }];
        
    }];
}

- (void) testLoginWithRegisteredDevice {
    NSString *baseUrlKey = @"baseServerUrl";

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
    [defaults setBool:YES forKey:@"deviceRegistered"];

    UINavigationController *navigationController = [[UINavigationController alloc]init];

    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
    
    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
    id delegatePartialMock = OCMPartialMock(delegate);
    OCMExpect([delegatePartialMock authenticationSuccessful]);

    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate];
    
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
                                    @"test", @"password",
                                    @"uuid", @"uid",
                                    nil];

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/login"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            NSString* fixture = OHPathForFile(@"loginSuccess.json", self.class);
            return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
        }];

        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /api/login complete"];

        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
            [loginResponseArrived fulfill];
            [disclaimerDelegate disclaimerAgree];
            OCMVerifyAll(delegatePartialMock);
        });

        [loginDelegate loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
            // login complete
            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
        }];

        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {

            OCMVerifyAll(navControllerPartialMock);
        }];

    }];
}

- (void) testLoginFailWithRegisteredDevice {
    NSString *baseUrlKey = @"baseServerUrl";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    
    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
    
    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
    id delegatePartialMock = OCMPartialMock(delegate);
    OCMExpect([delegatePartialMock authenticationSuccessful]);
    
    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate];
    
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
        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
        
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"test", @"username",
                                    @"test", @"password",
                                    @"uuid", @"uid",
                                    nil];
        
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/login"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            OHHTTPStubsResponse *response = [[OHHTTPStubsResponse alloc] init];
            response.statusCode = 401;
            
            return response;
        }];
        
        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /api/login complete"];
        
        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
        
        [loginDelegate loginWithParameters:parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
            // login complete
            XCTAssertTrue(authenticationStatus == AUTHENTICATION_ERROR);
            [loginResponseArrived fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
            
            OCMVerifyAll(navControllerPartialMock);
        }];
        
    }];
}

- (void)testSetURLSuccess {
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
    
    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate];
    
    id navControllerPartialMock = OCMPartialMock(navigationController);
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
        [responseArrived fulfill];
    });
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
    [serverUrlDelegate setServerURL:[NSURL URLWithString:@"https://mage.geointservices.io"]];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        OCMVerifyAll(navControllerPartialMock);
    }];
}

- (void)testSetURLFailVersion {
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    
    __block id serverUrlControllerMock;
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];

    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate];
    
    id navControllerPartialMock = OCMPartialMock(navigationController);
    
    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO]);

    NSURL *url = [MageServer baseURL];
    XCTAssertTrue([[url absoluteString] isEqualToString:@""]);
    
    [coordinator start];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        serverUrlControllerMock = OCMPartialMock(coordinator.urlController);
        OCMExpect([serverUrlControllerMock showError:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
            [responseArrived fulfill];
        });
        NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
        
    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
    [serverUrlDelegate setServerURL:[NSURL URLWithString:@"https://mage.geointservices.io"]];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        OCMVerifyAll(navControllerPartialMock);
        OCMVerifyAll(serverUrlControllerMock);
    }];
}

- (void) testStartWithVersionFail {
    NSString *baseUrlKey = @"baseServerUrl";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
    
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    
    __block id serverUrlControllerMock;
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];

    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate];
    
    id navControllerPartialMock = OCMPartialMock(navigationController);
        
    NSURL *url = [MageServer baseURL];
    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
    
    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
        serverUrlControllerMock = OCMPartialMock(coordinator.urlController);
        NSString *error = (NSString *)[serverUrlControllerMock error];
        
        XCTAssertTrue([@"This version of the app is not compatible with version 4.0.0 of the server." isEqualToString:error]);
        [responseArrived fulfill];
    });
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [coordinator start];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        OCMVerifyAll(navControllerPartialMock);
    }];
}

@end
