//
//  NetworkSyncOptionTetsts.m
//  MAGETests
//
//  Created by Daniel Barela on 2/19/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "DataConnectionUtilities.h"

@interface NetworkSyncOptionTetsts : XCTestCase

@end

@implementation NetworkSyncOptionTetsts

- (void)testPushObservationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"observationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushObservations] == true);
}

- (void)testPushObservationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"observationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushObservations] == false);
}

- (void)testPushObservationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushObservationsOverWifiWhitelistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldPushObservations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushObservationsOverWifiWhitelistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldPushObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushObservationsOverWifiBlacklistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldPushObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushObservationsOverWifiBlacklistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldPushObservations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchObservationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"observationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == true);
}

- (void)testFetchObservationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"observationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == false);
}

- (void)testFetchObservationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchObservationsOverWifiWhitelistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchObservationsOverWifiWhitelistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchObservationsOverWifiBlacklistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchObservationsOverWifiBlacklistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushLocationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"locationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushLocations] == true);
}

- (void)testPushLocationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"locationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushLocations] == false);
}

- (void)testPushLocationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushLocationsOverWifiWhitelistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldPushLocations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushLocationsOverWifiWhitelistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldPushLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushLocationsOverWifiBlacklistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldPushLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushLocationsOverWifiBlacklistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldPushLocations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchLocationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"locationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == true);
}

- (void)testFetchLocationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"locationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == false);
}

- (void)testFetchLocationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchLocationsOverWifiWhitelistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchLocationsOverWifiWhitelistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchLocationsOverWifiBlacklistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchLocationsOverWifiBlacklistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushAttachmentsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"attachmentPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == true);
}

- (void)testPushAttachmentsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"attachmentPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == false);
}

- (void)testPushAttachmentsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushAttachmentsOverWifiWhitelistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushAttachmentsOverWifiWhitelistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushAttachmentsOverWifiBlacklistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testPushAttachmentsOverWifiBlacklistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentPushNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchAttachmentsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"attachmentFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == true);
}

- (void)testFetchAttachmentsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"attachmentFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == false);
}

- (void)testFetchAttachmentsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchAttachmentsOverWifiWhitelistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == true);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchAttachmentsOverWifiWhitelistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeOnlyTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiWhitelist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchAttachmentsOverWifiBlacklistSsidIncluded {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifi"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)testFetchAttachmentsOverWifiBlacklistSsidMissing {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeWiFi]];
    [OCMStub([dataConnectionMock getCurrentWifiSsid]) andReturn:@"testWifiNotInList"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentFetchNetworkOption"];
    [defaults setInteger:WIFIRestrictionTypeNotTheseWifiNetworks forKey:@"wifiNetworkRestrictionType"];
    NSArray *whitelist = [NSArray arrayWithObjects:@"first", @"testWifi", @"secondone", nil];
    [defaults setObject:whitelist forKey:@"wifiBlacklist"];
    
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == true);
    
    [dataConnectionMock stopMocking];
}
@end
