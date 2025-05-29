////
////  CacheOverlays.h
////  MAGE
////
////  Created by Brian Osborn on 12/17/15.
////  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
////
//
//#import <Foundation/Foundation.h>
//#import "CacheOverlayListener.h"
//
///**
// *  Cache Overlays, maintaining all cache overlays and listeners interested in changes
// */
//@interface CacheOverlays : NSObject
//
///**
// *  Get the singleton instance
// *
// *  @return instance
// */
//+(CacheOverlays *) getInstance;
//
///**
// *  Register a listener for overlay updates
// *
// *  @param listener cache overlay listener
// */
//-(void) registerListener: (NSObject<CacheOverlayListener> *) listener;
//
///**
// *  Unregister a listener from overlay updates
// *
// *  @param listener cache overlay listener
// */
//-(void) unregisterListener: (NSObject<CacheOverlayListener> *) listener;
//
///**
// *  Set the cache overalys
// *
// *  @param overlays cache overlays
// */
//-(void) setCacheOverlays:(NSArray<CacheOverlay *> *)overlays;
//
///**
// *  Add additional cache overlays
// *
// *  @param overlays cache overlays
// */
//-(void) addCacheOverlays:(NSArray<CacheOverlay *> *)overlays;
//
///**
// *  Add a cache overlay
// *
// *  @param overlay cache overlay
// */
//-(void) addCacheOverlay:(CacheOverlay *)overlay;
//
///**
// *  Notify all listeners that a cache overlay change occurred
// */
//-(void) notifyListeners;
//
///**
// *  Notify all listeners that a cache overlay change occurred except for the provided caller
// *
// *  @param caller calling listener
// */
//-(void) notifyListenersExceptCaller:(NSObject<CacheOverlayListener> *) caller;
//
///**
// *  Get the cache overlays
// *
// *  @return cache overlays
// */
//-(NSArray<CacheOverlay *> *) getOverlays;
//
///**
// *  Get the count of cache overlays
// *
// *  @return cache overlays
// */
//-(NSUInteger) count;
//
///**
// *  Get the Cache Overlay at the index
// *
// *  @param index index
// *
// *  @return cache overlay at index
// */
//-(CacheOverlay *) atIndex:(NSUInteger)index;
//
///**
// *  Get a cache overlay by cache name
// *
// *  @param cacheName cachename
// *
// *  @return cache overlay
// */
//-(CacheOverlay *) getByCacheName: (NSString *) cacheName;
//
///**
// *  Remove a cache overlay
// *
// *  @param overlay cache overlay
// */
//-(void) removeCacheOverlay: (CacheOverlay *) overlay;
//
///**
// *  Remove a cache overlay by cache name
// *
// *  @param cacheName cache name
// */
//-(void) removeByCacheName: (NSString *) cacheName;
//
///**
// *  Add a processing cache name
// *
// *  @param name processing name
// */
//-(void) addProcessing: (NSString *) name;
//
///**
// *  Add processing cache names from an array
// *
// *  @param names processing cache names
// */
//-(void) addProcessingFromArray: (NSArray *) names;
//
///**
// *  Remove a processing cache name
// *
// *  @param name processing name
// */
//-(void) removeProcessing: (NSString *) name;
//
///**
// *  Get the processing cache names
// *
// *  @return processing caches
// */
//-(NSArray *) getProcessing;
//
//-(void) removeAll;
//
//@end
