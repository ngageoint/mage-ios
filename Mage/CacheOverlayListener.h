//
//  CacheOverlayListener.h
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#ifndef CacheOverlayListener_h
#define CacheOverlayListener_h

#import "CacheOverlay.h"

/**
 *  Cache Overlay Listener protocol interface for subscribing to updated cache overlays
 */
@protocol CacheOverlayListener <NSObject>

/**
 *  Cache overlays have been updated
 *
 *  @param cacheOverlays updated cache overlays array
 */
-(void) cacheOverlaysUpdated: (NSArray<CacheOverlay *> *) cacheOverlays;

@end

#endif /* CacheOverlayListener_h */
