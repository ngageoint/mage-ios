//
//  CacheOverlays.m
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CacheOverlays.h"
#import "CacheOverlay.h"
#import "CacheOverlayListener.h"

@interface CacheOverlays ()

@property (nonatomic, strong) NSMutableArray<CacheOverlay *> * overlays;
@property (nonatomic, strong) NSMutableArray<NSObject<CacheOverlayListener> *> * listeners;

@end

@implementation CacheOverlays

static CacheOverlays * instance;

+(CacheOverlays *) getInstance{
    if(instance == nil){
        instance = [[CacheOverlays alloc] init];
    }
    return instance;
}

-(instancetype) init{
    self = [super init];
    if(self){
        self.overlays = [[NSMutableArray alloc] init];
        self.listeners = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) registerListener: (NSObject<CacheOverlayListener> *) listener{
    @synchronized(self) {
        [self.listeners addObject:listener];
        [listener cacheOverlaysUpdated:self.overlays];
    }
}

-(void) unregisterListener: (NSObject<CacheOverlayListener> *) listener{
    @synchronized(self) {
        [self.listeners removeObject:listener];
    }
}

-(void) setCacheOverlays:(NSArray<CacheOverlay *> *)overlays{
    @synchronized(self) {
        _overlays = [[NSMutableArray alloc] initWithArray:overlays];
        [self notifyListeners];
    }
}

-(void) addCacheOverlays:(NSArray<CacheOverlay *> *)overlays{
    @synchronized(self) {
        [_overlays addObjectsFromArray:overlays];
        [self notifyListeners];
    }
}

-(void) addCacheOverlay:(CacheOverlay *)overlay{
    @synchronized(self) {
        [_overlays addObject:overlay];
        [self notifyListeners];
    }
}

-(void) notifyListeners{
    for(NSObject<CacheOverlayListener> * listener in self.listeners){
        [listener cacheOverlaysUpdated:self.overlays];
    }
}

@end
