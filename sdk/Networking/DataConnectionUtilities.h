//
//  DataConnectionUtilities.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 2/7/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataConnectionUtilities : NSObject

typedef NS_ENUM(NSInteger, ConnectionType) {
    ConnectionTypeUnknown,
    ConnectionTypeNone,
    ConnectionTypeCell,
    ConnectionTypeWiFi
};

typedef NS_ENUM(NSInteger, WIFIRestrictionType) {
    WIFIRestrictionTypeNoRestrictions,
    WIFIRestrictionTypeOnlyTheseWifiNetworks,
    WIFIRestrictionTypeNotTheseWifiNetworks
};

typedef NS_ENUM(NSInteger, NetworkAllowType) {
    NetworkAllowTypeAll,
    NetworkAllowTypeWiFiOnly,
    NetworkAllowTypeNone
};

+ (NSString *) getCurrentWifiSsid;
+ (ConnectionType)connectionType;
+ (BOOL) shouldPushObservations;
+ (BOOL) shouldFetchObservations;
+ (BOOL) shouldFetchLocations;
+ (BOOL) shouldPushLocations;
+ (BOOL) shouldPushAttachments;
+ (BOOL) shouldFetchAttachments;
+ (BOOL) shouldFetchAvatars;

@end

NS_ASSUME_NONNULL_END
