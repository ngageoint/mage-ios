//
//  XYZDirectoryCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "XYZDirectoryCacheOverlay.h"

@interface XYZDirectoryCacheOverlay ()

@property (strong, nonatomic) NSString * directory;

@end

@implementation XYZDirectoryCacheOverlay

-(instancetype) initWithName: (NSString *) name andDirectory: (NSString *) directory{
    self = [super initWithName:name andType:XYZ_DIRECTORY andSupportsChildren:false];
    if(self){
        self.directory = directory;
        self.tileCount = 0;
        self.minZoom = 100;
        self.maxZoom = -1;
        
        NSArray<NSString *> *zooms = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
        for (NSString *zoom in zooms) {
            self.minZoom = MIN(self.minZoom, zoom.intValue);
            self.maxZoom = MAX(self.maxZoom, zoom.intValue);
            NSString *zoomPath = [directory stringByAppendingPathComponent:zoom];
            for (NSString *x in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:zoomPath error:nil]) {
                NSString *xPath = [zoomPath stringByAppendingPathComponent:x];
                self.tileCount += (int)[[NSFileManager defaultManager] contentsOfDirectoryAtPath:xPath error:nil].count;
            }
        }
    }
    return self;
}

-(void) removeFromMap: (MKMapView *) mapView{
    if(self.tileOverlay != nil){
        [mapView removeOverlay:self.tileOverlay];
        self.tileOverlay = nil;
    }
}

-(NSString *) getIconImageName{
    return @"layers";
}

-(NSString *) getDirectory{
    return self.directory;
}

- (NSString *) getInfo {
    return [NSString stringWithFormat:@"%d tiles, zoom: %d - %d", self.tileCount, self.minZoom, self.maxZoom];
}

@end
