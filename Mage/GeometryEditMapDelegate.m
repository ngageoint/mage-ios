//
//  GeometryEditMapDelegate.m
//  MAGE
//
//  Created by Dan Barela on 8/21/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeometryEditMapDelegate.h"
#import "GPKGMapPoint.h"
#import "MapShapePointAnnotationView.h"
#import "ObservationShapeStyle.h"

@interface GeometryEditMapDelegate()

@property (strong, nonatomic) id<AnnotationDragCallback> dragCallback;
@property (nonatomic, strong) ObservationShapeStyle *editStyle;
@property (strong, nonatomic) id<EditableMapAnnotationDelegate> editDelegate;

@end

@implementation GeometryEditMapDelegate

static NSString *mapPointImageReuseIdentifier = @"mapPointImageReuseIdentifier";
static NSString *mapPointPinReuseIdentifier = @"mapPointPinReuseIdentifier";

- (instancetype) initWithDragCallback:(id<AnnotationDragCallback>)dragCallback andEditDelegate: (id<EditableMapAnnotationDelegate>) editDelegate {
    self = [super init];
    if (self == nil) return nil;
    
    _dragCallback = dragCallback;
    _editDelegate = editDelegate;
    
    // Set the default edit shape draw options
    _editStyle = [[ObservationShapeStyle alloc] init];
    
    return self;
}

- (void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
    for (MKAnnotationView *view in views) {
        view.draggable = YES;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>) annotation {
    
    MKAnnotationView *view = nil;
    
    if ([annotation isKindOfClass:[GPKGMapPoint class]]) {
        GPKGMapPoint * mapPoint = (GPKGMapPoint *) annotation;
        if(mapPoint.options.image != nil){
            MKAnnotationView *mapPointImageView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointImageReuseIdentifier];
            if (mapPointImageView == nil) {
                mapPointImageView = [[MapShapePointAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:mapPointImageReuseIdentifier andMapView:mapView andDragCallback:_dragCallback];
            }
            mapPointImageView.image = mapPoint.options.image;
            mapPointImageView.centerOffset = mapPoint.options.imageCenterOffset;
            
            view = mapPointImageView;
        }
    }
    
    return view;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * renderer = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.strokeColor = self.editStyle.strokeColor;
        polygonRenderer.lineWidth = self.editStyle.lineWidth;
        if(self.editStyle.fillColor != nil){
            polygonRenderer.fillColor = self.editStyle.fillColor;
        }
        renderer = polygonRenderer;
    } else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.strokeColor = self.editStyle.strokeColor;
        polylineRenderer.lineWidth = self.editStyle.lineWidth;
        renderer = polylineRenderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return renderer;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    [self.editDelegate mapView:mapView didSelectAnnotationView:view];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    [self.editDelegate mapView:mapView didDeselectAnnotationView:view];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *) annotationView didChangeDragState:(MKAnnotationViewDragState) newState fromOldState:(MKAnnotationViewDragState) oldState {
    [self.editDelegate mapView:mapView annotationView:annotationView didChangeDragState:newState fromOldState:oldState];
}

@end
