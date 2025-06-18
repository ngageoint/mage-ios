//
//  GeoPackageCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageCacheOverlay.h"
#import "GeoPackageFeatureTableCacheOverlay.h"

@interface GeoPackageCacheOverlay ()

@property (strong, nonatomic) NSMutableArray<CacheOverlay *> * tables;

@end

@implementation GeoPackageCacheOverlay

-(instancetype) initWithName: (NSString *) name andPath: (NSString *) filePath andTables: (NSArray<GeoPackageTableCacheOverlay *> *) tables{
    self = [super initWithName:name andType:GEOPACKAGE andSupportsChildren:true];
    if(self){
        self.filePath = filePath;
        self.tables = [[NSMutableArray alloc] init];
        for(GeoPackageTableCacheOverlay * table in tables){
            [table setParent:self];
            if([table getType] == GEOPACKAGE_FEATURE_TABLE){
                GeoPackageFeatureTableCacheOverlay * featureTable = (GeoPackageFeatureTableCacheOverlay *) table;
                for(GeoPackageTileTableCacheOverlay * linkedTileTable in [featureTable getLinkedTileTables]){
                    [linkedTileTable setParent:self];
                }
            }
            [self.tables addObject:table];
        }
    }
    return self;
}

-(void) removeFromMap: (MKMapView *) mapView{
    for(CacheOverlay * cacheOverlay in [self getChildren]){
        [cacheOverlay removeFromMap:mapView];
    }
}

-(NSString *) getIconImageName{
    return @"geopackage";
}

-(NSArray<CacheOverlay *> *) getChildren{
    return self.tables;
}

@end
