//
//  MageServerTests.m
//  MAGETests
//
//  Created by Dan Barela on 2/14/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

@import OHHTTPStubs;

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MageServer.h"
#import "StoredPassword.h"

@interface MageServerTests : XCTestCase

@end

@implementation MageServerTests

- (void)setUp {
    [super setUp];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
}

- (void)tearDown {
    [super tearDown];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
    [HTTPStubs removeAllStubs];
}

- (void)testSetURLThatHasAlreadyBeenSetWithoutStoredPasswordOrAPIRetrievedAndNoConnectionShouldHaveNoLoginModules {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
        return [HTTPStubsResponse responseWithError:notConnectedError];
    }];

    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        id<Authentication> localAuthenticationModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
        id<Authentication> serverAuthModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
        XCTAssertNil(localAuthenticationModule);
        XCTAssertNil(serverAuthModule);
        [responseArrived fulfill];
    } failure:^(NSError *error) {
        // failure
        XCTFail(@"Should not have a failure");
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testSetURLThatHasAlreadyBeenSetAndAPIHasBeenRetrievedWithoutStoredPasswordAndNoConnectionShouldHaveNoLocalLoginModule {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    NSDictionary *authStrategies = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:14], @"passwordMinLength", nil], @"local", nil];
    [defaults setObject:authStrategies forKey:@"authenticationStrategies"];
    
    NSMutableDictionary *loginParameters = [[NSMutableDictionary alloc] init];
    [loginParameters setObject:@"https://mage.geointservices.io" forKey:@"serverUrl"];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
        return [HTTPStubsResponse responseWithError:notConnectedError];
    }];
    
    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        id<Authentication> localAuthenticationModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
        id<Authentication> serverAuthModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
        XCTAssertNil(localAuthenticationModule);
        XCTAssertNotNil(serverAuthModule);
        [responseArrived fulfill];
    } failure:^(NSError *error) {
        // failure
        XCTFail(@"Should not have a failure");
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testSetURLWithNoStoredPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    NSDictionary *authStrategies = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:14], @"passwordMinLength", nil], @"local", nil];
    [defaults setObject:authStrategies forKey:@"authenticationStrategies"];
    
    NSMutableDictionary *loginParameters = [[NSMutableDictionary alloc] init];
    [loginParameters setObject:@"https://mage.geointservices.io" forKey:@"serverUrl"];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        id<Authentication> localAuthenticationModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
        id<Authentication> serverAuthModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
        XCTAssertNil(localAuthenticationModule);
        XCTAssertNotNil(serverAuthModule);
        [responseArrived fulfill];
    } failure:^(NSError *error) {
        // failure
        XCTFail(@"Should not have a failure");
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testSetURLWithStoredPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", nil] forKey:@"loginParameters"];
    
    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
    [[[storedPasswordMock stub] andReturn:@"mockpassword"] retrieveStoredPassword];
    
    NSDictionary *authStrategies = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:14], @"passwordMinLength", nil], @"local", nil];
    [defaults setObject:authStrategies forKey:@"authenticationStrategies"];
    
    NSMutableDictionary *loginParameters = [[NSMutableDictionary alloc] init];
    [loginParameters setObject:@"https://mage.geointservices.io" forKey:@"serverUrl"];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        id<Authentication> localAuthenticationModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
        id<Authentication> serverAuthModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
        XCTAssertNotNil(localAuthenticationModule);
        XCTAssertNotNil(serverAuthModule);
        [responseArrived fulfill];
    } failure:^(NSError *error) {
        // failure
        XCTFail(@"Should not have a failure");
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
       
    }];
}

- (void)testSetURLHitAPINoStoredPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    [defaults setObject:@[@{@"serverMajorVersion" : @5}, @{@"serverMinorVersion" : @4}] forKey:@"serverCompatibilities"];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        id<Authentication> localAuthenticationModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
        id<Authentication> serverAuthModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
        XCTAssertNil(localAuthenticationModule);
        XCTAssertNotNil(serverAuthModule);
        [responseArrived fulfill];
    } failure:^(NSError *error) {
        // failure
        NSLog(@"Error was %@", error);
        XCTFail(@"Should not have a failure");
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testSetURL503 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        HTTPStubsResponse *response = [[HTTPStubsResponse alloc] init];
        response.statusCode = 503;
        
        return response;
    }];
    
    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        XCTFail(@"Should not have a success");
    } failure:^(NSError *error) {
        // failure
        [responseArrived fulfill];
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testSetURLHitAPIWithStoredPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"https://mage.geointservices.io" forKey:@"baseServerUrl"];
    [defaults setBool:YES forKey:@"deviceRegistered"];
    [defaults setObject:@[@{@"serverMajorVersion" : @5}, @{@"serverMinorVersion" : @4}] forKey:@"serverCompatibilities"];
    
    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", nil] forKey:@"loginParameters"];
    
    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
    [[[storedPasswordMock stub] andReturn:@"mockpassword"] retrieveStoredPassword];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"Server URL Set"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [MageServer serverWithURL:[NSURL URLWithString:@"https://mage.geointservices.io"] success:^(MageServer *mageServer) {
        // success
        NSLog(@"Success");
        id<Authentication> localAuthenticationModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:LOCAL]];
        id<Authentication> serverAuthModule = [mageServer.authenticationModules objectForKey:[Authentication authenticationTypeToString:SERVER]];
        XCTAssertNotNil(localAuthenticationModule);
        XCTAssertNotNil(serverAuthModule);
        [responseArrived fulfill];
    } failure:^(NSError *error) {
        // failure
        XCTFail(@"Should not have a failure");
        NSLog(@"Failure");
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

@end
