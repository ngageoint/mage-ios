//
//  MapAnnotation.m
//  MAGE
//
//  Created by Brian Osborn on 5/3/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

static NSUInteger idCounter = 0;

-(id) init{
    if (self = [super init]) {
        self.id = idCounter++;
    }
    return self;
}

-(NSNumber *) getIdAsNumber{
    return [NSNumber numberWithInteger:self.id];
}

-(MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView  scheme: (id<MDCContainerScheming>) scheme {
    [NSException raise:@"No Implementation" format:@"Implementation must be provided by an extending map annotation type"];
    return nil;
}

-(MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView withDragCallback: (NSObject<AnnotationDragCallback> *) dragCallback scheme: (id<MDCContainerScheming>) scheme {
    return [self viewForAnnotationOnMapView:mapView scheme:scheme];
}

-(void) hidden: (BOOL) hidden{
    if(self.view != nil){
        self.view.hidden = hidden;
    }
}

@end
