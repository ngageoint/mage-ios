//
//  CacheOverlayUpdate.h
//  MAGE
//
//  Created by Brian Osborn on 2/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheOverlay.h"

@interface CacheOverlayUpdate : NSObject

@property (nonatomic, strong) NSArray<CacheOverlay *> * updateCacheOverlays;

-(instancetype) initWithCacheOverlays: (NSArray<CacheOverlay *> *) cacheOverlays;

@end
