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
#import "GeoPackageCacheOverlay.h"
#import "MAGE-Swift.h"

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
        [listener cacheOverlaysUpdated:[self getOverlays]];
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
        // Set existing cache overlays to their current enabled state
        [overlay setEnabled:existingOverlay.enabled];
        // If a new version of an existing cache overlay was added
        if(overlay.added){
            // Set the cache overlay being replaced
            if(existingOverlay.replacedCacheOverlay != nil){
                [overlay setReplacedCacheOverlay:existingOverlay.replacedCacheOverlay];
            }else{
                [overlay setReplacedCacheOverlay:existingOverlay];
            }
        }
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
                [listener cacheOverlaysUpdated:[self getOverlays]];
            }
        }
    }
}

-(NSArray<CacheOverlay *> *) getOverlays{
    NSMutableArray<CacheOverlay *> *overlaysInCurrentEvent = [[NSMutableArray alloc] init];
    
    
    for(CacheOverlay * cacheOverlay in [self.overlays allValues]) {
        if ([cacheOverlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
            GeoPackageCacheOverlay *gpCacheOverlay = (GeoPackageCacheOverlay *)cacheOverlay;
            NSString *filePath = gpCacheOverlay.filePath;
            // check if this filePath is consistent with a downloaded layer and if so, verify that layer is in this event
            NSArray *pathComponents = [filePath pathComponents];
            if ([[pathComponents objectAtIndex:[pathComponents count] - 3] isEqualToString:@"geopackages"]) {
                NSString *layerId = [pathComponents objectAtIndex:[pathComponents count] - 2];
                // check if this layer is in the event
                NSUInteger count = [Layer MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND remoteId == %ld", [Server currentEventId], layerId.integerValue] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (count != 0) {
                    [overlaysInCurrentEvent addObject:cacheOverlay];
                }
            } else {
                [overlaysInCurrentEvent addObject:cacheOverlay];
            }
        } else {
            [overlaysInCurrentEvent addObject:cacheOverlay];
        }
    }
    return overlaysInCurrentEvent;
}

-(NSArray <CacheOverlay *> *) getLocallyLoadedOverlays {
    NSMutableArray<CacheOverlay *> *localOverlays = [[NSMutableArray alloc] init];
    
    for(CacheOverlay * cacheOverlay in [self.overlays allValues]) {
        if ([cacheOverlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
            GeoPackageCacheOverlay *gpCacheOverlay = (GeoPackageCacheOverlay *)cacheOverlay;
            NSString *filePath = gpCacheOverlay.filePath;
            // check if this filePath is consistent with a downloaded layer and if so, verify that layer is in this event
            NSArray *pathComponents = [filePath pathComponents];
            if (![[pathComponents objectAtIndex:[pathComponents count] - 3] isEqualToString:@"geopackages"]) {
                [localOverlays addObject:cacheOverlay];
            }
        } else {
            [localOverlays addObject:cacheOverlay];
        }
    }
    return localOverlays;
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
