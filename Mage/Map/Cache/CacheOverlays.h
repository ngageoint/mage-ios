//
//  CacheOverlays.h
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheOverlayListener.h"

/**
 *  Cache Overlays, maintaining all cache overlays and listeners interested in changes
 */
@interface CacheOverlays : NSObject

/**
 *  Get the singleton instance
 *
 *  @return instance
 */
+(CacheOverlays *) getInstance;

/**
 *  Register a listener for overlay updates
 *
 *  @param listener cache overlay listener
 */
-(void) registerListener: (NSObject<CacheOverlayListener> *) listener;

/**
 *  Unregister a listener from overlay updates
 *
 *  @param listener cache overlay listener
 */
-(void) unregisterListener: (NSObject<CacheOverlayListener> *) listener;

/**
 *  Set the cache overalys
 *
 *  @param overlays cache overlays
 */
-(void) setCacheOverlays:(NSArray<CacheOverlay *> *)overlays;

/**
 *  Add additional cache overlays
 *
 *  @param overlays cache overlays
 */
-(void) addCacheOverlays:(NSArray<CacheOverlay *> *)overlays;

/**
 *  Add a cache overlay
 *
 *  @param overlay cache overlay
 */
-(void) addCacheOverlay:(CacheOverlay *)overlay;

@end
