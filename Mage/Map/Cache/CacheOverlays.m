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

@property (nonatomic, strong) NSMutableDictionary<NSString *, CacheOverlay *> * overlays;
@property (nonatomic, strong) NSMutableArray<NSString *> * overlayNames;
@property (nonatomic, strong) NSMutableArray<NSObject<CacheOverlayListener> *> * listeners;
@property (nonatomic, strong) NSMutableSet<NSString *> * processing;

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
        self.overlays = [[NSMutableDictionary alloc] init];
        self.overlayNames = [[NSMutableArray alloc] init];
        self.listeners = [[NSMutableArray alloc] init];
        self.processing = [[NSMutableSet alloc] init];
    }
    return self;
}

-(void) registerListener: (NSObject<CacheOverlayListener> *) listener{
    @synchronized(self) {
        [self.listeners addObject:listener];
        [listener cacheOverlaysUpdated:[self.overlays allValues]];
    }
}

-(void) unregisterListener: (NSObject<CacheOverlayListener> *) listener{
    @synchronized(self) {
        [self.listeners removeObject:listener];
    }
}

-(void) setCacheOverlays:(NSArray<CacheOverlay *> *)overlays{
    @synchronized(self) {
        _overlays = [[NSMutableDictionary alloc] init];
        _overlayNames = [[NSMutableArray alloc] init];
        [self addCacheOverlays:overlays];
    }
}

-(void) addCacheOverlays:(NSArray<CacheOverlay *> *)overlays{
    @synchronized(self) {
        for(CacheOverlay * overlay in overlays){
            [self addCacheOverlayHelper:overlay];
        }
        [self notifyListeners];
    }
}

-(void) addCacheOverlay:(CacheOverlay *)overlay{
    @synchronized(self) {
        [self addCacheOverlayHelper:overlay];
        [self notifyListeners];
    }
}

-(void) addCacheOverlayHelper:(CacheOverlay *)overlay{
    NSString * cacheName = [overlay getCacheName];
    CacheOverlay * existingOverlay = [_overlays objectForKey:cacheName];
    if(existingOverlay == nil){
        [_overlayNames addObject:cacheName];
    }else{
        [overlay setEnabled:existingOverlay.enabled];
    }
    [_overlays setObject:overlay forKey:cacheName];
}

-(void) notifyListeners{
    @synchronized(self) {
        [self notifyListenersExceptCaller:nil];
    }
}

-(void) notifyListenersExceptCaller:(NSObject<CacheOverlayListener> *) caller{
    @synchronized(self) {
        for(NSObject<CacheOverlayListener> * listener in self.listeners){
            if(caller == nil || listener != caller){
                [listener cacheOverlaysUpdated:[self.overlays allValues]];
            }
        }
    }
}

-(NSArray<CacheOverlay *> *) getOverlays{
    return [self.overlays allValues];
}

-(NSUInteger) count{
    return [self.overlayNames count];
}

-(CacheOverlay *) atIndex:(NSUInteger)index{
    return [self.overlays objectForKey:[self.overlayNames objectAtIndex:index]];
}

-(CacheOverlay *) getByCacheName: (NSString *) cacheName{
    return [self.overlays objectForKey:cacheName];
}

-(void) removeCacheOverlay: (CacheOverlay *) overlay{
    [self removeByCacheName:[overlay getCacheName]];
}

-(void) removeByCacheName: (NSString *) cacheName{
    @synchronized(self) {
        [self.overlays removeObjectForKey:cacheName];
        [self.overlayNames removeObject:cacheName];
        [self notifyListeners];
    }
}

-(void) addProcessing: (NSString *) name{
    @synchronized(self) {
        [self.processing addObject:name];
        [self notifyListeners];
    }
}

-(void) addProcessingFromArray: (NSArray *) names{
    @synchronized(self) {
        [self.processing addObjectsFromArray:names];
        [self notifyListeners];
    }
}

-(void) removeProcessing: (NSString *) name{
    @synchronized(self) {
        [self.processing removeObject:name];
        [self notifyListeners];
    }
}

-(NSArray *) getProcessing{
    return [self.processing allObjects];
}

@end
