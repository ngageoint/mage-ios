//
//  AuthenticationTests.m
//  MAGETests
//
//  Created by Dan Barela on 1/9/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs.h>
#import <OHPathHelpers.h>
#import <OCMock.h>
#import "AuthenticationCoordinator.h"
#import "ServerURLController.h"
#import "LoginViewController.h"

@interface ServerURLController ()
@property (strong, nonatomic) NSString *error;
@end

@interface AuthenticationCoordinator ()
@property (strong, nonatomic) NSString *urlController;
@end

@interface AuthenticationTests : XCTestCase <AuthenticationDelegate>

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


- (void)testSetURLSuccess {
    UINavigationController *navigationController = [[UINavigationController alloc]init];
    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:self];
    
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
    
    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:self];
    
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
    
    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:self];
    
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

- (void)authenticationSuccessful {
    
}

@end
