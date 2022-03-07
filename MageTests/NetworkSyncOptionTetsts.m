//
//  NetworkSyncOptionTetsts.m
//  MAGETests
//
//  Created by Daniel Barela on 2/19/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MAGE-Swift.h"

@interface NetworkSyncOptionTetsts : XCTestCase

@end

@implementation NetworkSyncOptionTetsts

- (void)skipped_testPushObservationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"observationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushObservations] == true);
}

- (void)skipped_testPushObservationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"observationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushObservations] == false);
}

- (void)skipped_testPushObservationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)skipped_testPushObservationsOverWifiWhitelistSsidIncluded {
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

- (void)skipped_testPushObservationsOverWifiWhitelistSsidMissing {
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

- (void)skipped_testPushObservationsOverWifiBlacklistSsidIncluded {
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

- (void)skipped_testPushObservationsOverWifiBlacklistSsidMissing {
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

- (void)skipped_testFetchObservationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"observationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == true);
}

- (void)skipped_testFetchObservationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"observationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == false);
}

- (void)skipped_testFetchObservationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"observationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchObservations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)skipped_testFetchObservationsOverWifiWhitelistSsidIncluded {
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

- (void)skipped_testFetchObservationsOverWifiWhitelistSsidMissing {
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

- (void)skipped_testFetchObservationsOverWifiBlacklistSsidIncluded {
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

- (void)skipped_testFetchObservationsOverWifiBlacklistSsidMissing {
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

- (void)skipped_testPushLocationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"locationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushLocations] == true);
}

- (void)skipped_testPushLocationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"locationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushLocations] == false);
}

- (void)skipped_testPushLocationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)skipped_testPushLocationsOverWifiWhitelistSsidIncluded {
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

- (void)skipped_testPushLocationsOverWifiWhitelistSsidMissing {
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

- (void)skipped_testPushLocationsOverWifiBlacklistSsidIncluded {
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

- (void)skipped_testPushLocationsOverWifiBlacklistSsidMissing {
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

- (void)skipped_testFetchLocationsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"locationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == true);
}

- (void)skipped_testFetchLocationsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"locationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == false);
}

- (void)skipped_testFetchLocationsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"locationFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchLocations] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)skipped_testFetchLocationsOverWifiWhitelistSsidIncluded {
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

- (void)skipped_testFetchLocationsOverWifiWhitelistSsidMissing {
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

- (void)skipped_testFetchLocationsOverWifiBlacklistSsidIncluded {
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

- (void)skipped_testFetchLocationsOverWifiBlacklistSsidMissing {
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

- (void)skipped_testPushAttachmentsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"attachmentPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == true);
}

- (void)skipped_testPushAttachmentsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"attachmentPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == false);
}

- (void)skipped_testPushAttachmentsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentPushNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldPushAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)skipped_testPushAttachmentsOverWifiWhitelistSsidIncluded {
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

- (void)skipped_testPushAttachmentsOverWifiWhitelistSsidMissing {
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

- (void)skipped_testPushAttachmentsOverWifiBlacklistSsidIncluded {
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

- (void)skipped_testPushAttachmentsOverWifiBlacklistSsidMissing {
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

- (void)skipped_testFetchAttachmentsOverAllNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeAll forKey:@"attachmentFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == true);
}

- (void)skipped_testFetchAttachmentsOverNoNetworks {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeNone forKey:@"attachmentFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == false);
}

- (void)skipped_testFetchAttachmentsOverWifiOnlyWhenConnectedToCell {
    id dataConnectionMock = OCMClassMock([DataConnectionUtilities class]);
    [OCMStub([dataConnectionMock connectionType]) andReturnValue:[NSNumber numberWithLong:ConnectionTypeCell]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:NetworkAllowTypeWiFiOnly forKey:@"attachmentFetchNetworkOption"];
    XCTAssert([DataConnectionUtilities shouldFetchAttachments] == false);
    
    [dataConnectionMock stopMocking];
}

- (void)skipped_testFetchAttachmentsOverWifiWhitelistSsidIncluded {
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

- (void)skipped_testFetchAttachmentsOverWifiWhitelistSsidMissing {
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

- (void)skipped_testFetchAttachmentsOverWifiBlacklistSsidIncluded {
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

- (void)skipped_testFetchAttachmentsOverWifiBlacklistSsidMissing {
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
