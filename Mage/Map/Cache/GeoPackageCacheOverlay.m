//
//  GeoPackageCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageCacheOverlay.h"

@interface GeoPackageCacheOverlay ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, CacheOverlay *> * tables;

@end

@implementation GeoPackageCacheOverlay

-(instancetype) initWithName: (NSString *) name andTables: (NSArray<CacheOverlay *> *) tables{
    self = [super initWithName:name andType:GEOPACKAGE andSupportsChildren:true];
    if(self){
        self.tables = [[NSMutableDictionary alloc] init];
        for(CacheOverlay * table in tables){
            [self.tables setObject:table forKey:[table getCacheName]];
        }
    }
    return self;
}

-(NSArray<CacheOverlay *> *) getChildren{
    NSArray<CacheOverlay *> * children = [[NSArray alloc] initWithArray:[self.tables allValues]];
    return children;
}

@end
