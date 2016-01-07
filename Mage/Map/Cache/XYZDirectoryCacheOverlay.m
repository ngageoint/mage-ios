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
    }
    return self;
}

-(void) removeFromMap: (MKMapView *) mapView{
    if(self.tileOverlay != nil){
        [mapView removeOverlay:self.tileOverlay];
        self.tileOverlay = nil;
    }
}

-(NSString *) getDirectory{
    return self.directory;
}

@end
