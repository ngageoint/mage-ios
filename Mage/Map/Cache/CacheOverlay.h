//
//  CacheOverlay.h
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheOverlayTypes.h"
#import <MapKit/MapKit.h>

/**
 *  Abstract cache overlay
 */
@interface CacheOverlay : NSObject

/**
 *  True when enabled
 */
@property (nonatomic) BOOL enabled;

/**
 *  True when expanded
 */
@property (nonatomic) BOOL expanded;

/**
 *  True when the cache was newly added, such as a file opened with MAGE
 */
@property (nonatomic) BOOL added;

/**
 *  A cache overlay that is being replaced by a new version
 */
@property (nonatomic, strong) CacheOverlay *replacedCacheOverlay;

/**
 *  Initializer
 *
 *  @param name              name
 *  @param type              cache type
 *  @param supportsChildrens true if cache overlay with children caches
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andType: (enum CacheOverlayType) type andSupportsChildren: (BOOL) supportsChildrens;

/**
 *  Constructor
 *
 *  @param name              name
 *  @param cacheName         cache name
 *  @param type              cache type
 *  @param supportsChildrens true if cache overlay with children caches
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andCacheName: (NSString *) cacheName andType: (enum CacheOverlayType) type andSupportsChildren: (BOOL) supportsChildrens;

/**
 *  Get the name
 *
 *  @return name
 */
-(NSString *) getName;

/**
 *  Get the cache name
 *
 *  @return cache name
 */
-(NSString *) getCacheName;

/**
 *  Get the cache overlay type
 *
 *  @return cache overlay type
 */
-(enum CacheOverlayType) getType;

/**
 *  Get the icon image name
 *
 *  @return icon image name
 */
-(NSString *) getIconImageName;

/**
 *  Determine if the cache overlay supports children
 *
 *  @return true if supports children
 */
-(BOOL) getSupportsChildren;

/**
 *  Get the children cache overlays
 *
 *  @return children cache overlays
 */
-(NSArray<CacheOverlay *> *) getChildren;

/**
 *  Return true if a child cache overlay, false if a top level with or without children
 *
 *  @return true if a child
 */
-(BOOL) isChild;

/**
 *  Get the child's parent cache overlay
 *
 *  @return parent cache overlay
 */
-(CacheOverlay *) getParent;

/**
 *  Get information about the cache to display
 *
 *  @return cache overlay info
 */
-(NSString *) getInfo;

/**
 *  Remove the cache overlay from the map
 *
 *  @param mapView map view
 */
-(void) removeFromMap: (MKMapView *) mapView;

/**
 *  On map click
 *
 *  @param locationCoordinate location coordinate
 *  @param mapView            map view
 *
 *  @return map click message
 */
-(NSString *) onMapClickWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView;

/**
 *  Build the cache name of a child
 *
 *  @param name      cache name
 *  @param childName child cache name
 *
 *  @return child cache name
 */
+(NSString *) buildChildCacheNameWithName: (NSString *) name andChildName: (NSString *) childName;

@end
