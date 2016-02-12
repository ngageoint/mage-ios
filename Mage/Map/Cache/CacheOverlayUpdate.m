//
//  CacheOverlayUpdate.m
//  MAGE
//
//  Created by Brian Osborn on 2/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CacheOverlayUpdate.h"

@implementation CacheOverlayUpdate

-(instancetype) initWithCacheOverlays: (NSArray<CacheOverlay *> *) cacheOverlays{
    self = [super init];
    if(self){
        self.updateCacheOverlays = [[NSArray alloc] initWithArray:cacheOverlays];
    }
    return self;
}

@end
