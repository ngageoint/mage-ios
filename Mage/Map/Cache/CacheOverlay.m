//
//  CacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CacheOverlay.h"

@interface CacheOverlay ()

@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSString * cacheName;
@property (nonatomic) enum CacheOverlayType type;
@property (nonatomic) BOOL supportsChildren;

@end

@implementation CacheOverlay

-(instancetype) initWithName: (NSString *) name andType: (enum CacheOverlayType) type andSupportsChildren: (BOOL) supportsChildrens{
    return [self initWithName:name andCacheName:name andType:type andSupportsChildren:supportsChildrens];
}

-(instancetype) initWithName: (NSString *) name andCacheName: (NSString *) cacheName andType: (enum CacheOverlayType) type andSupportsChildren: (BOOL) supportsChildrens{
    self = [super init];
    if(self != nil){
        self.name = name;
        self.cacheName = cacheName;
        self.type = type;
        self.supportsChildren = supportsChildrens;
        self.enabled = false;
    }
    return self;
}

-(NSString *) getName{
    return self.name;
}

-(NSString *) getCacheName{
    return self.cacheName;
}

-(enum CacheOverlayType) getType{
    return self.type;
}

-(BOOL) getSupportsChildren{
    return self.supportsChildren;
}

-(NSArray<CacheOverlay *> *) getChildren{
    return [[NSArray alloc] init];
}

-(NSString *) getInfo{
    return nil;
}

-(void) removeFromMap: (MKMapView *) mapView{
    
}

-(NSString *) onMapClickWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView{
    return nil;
}

+(NSString *) buildChildCacheNameWithName: (NSString *) name andChildName: (NSString *) childName{
    return [NSString stringWithFormat:@"%@-%@", name, childName];
}

@end
