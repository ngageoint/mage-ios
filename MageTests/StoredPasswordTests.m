//
//  StoredPasswordTests.m
//  MAGETests
//
//  Created by Dan Barela on 3/1/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "StoredPassword.h"
#import "NSDate+Iso8601.h"

@interface StoredPasswordTests : XCTestCase

@end

@implementation StoredPasswordTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testStorePassword {
    [StoredPassword persistTokenToKeyChain:@"TheTOKEN"];
    NSString *token = [StoredPassword retrieveStoredToken];
    XCTAssertTrue([token isEqualToString:@"TheTOKEN"]);
}

- (void) testClearPassword {
    [StoredPassword persistTokenToKeyChain:@"TheTOKEN"];
    NSString *token = [StoredPassword retrieveStoredToken];
    XCTAssertTrue([token isEqualToString:@"TheTOKEN"]);
    [StoredPassword clearToken];
    NSString *newToken = [StoredPassword retrieveStoredToken];
    XCTAssertNil(newToken);
}

- (void)testParse {
    NSDate *date = [NSDate dateFromIso8601String:@"2022-08-26T19:38:58.121Z"];
    NSLog(@"Parsed %@ into date %@", @"2022-08-26T19:38:58.121Z", date);
}

@end
