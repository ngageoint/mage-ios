//
//  MapDelegate.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapDelegate.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "GPSLocationAnnotation.h"
#import "ObservationImage.h"
#import "User+helper.h"
#import "Location+helper.h"
#import "UIImage+Resize.h"
#import <GeoPoint.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "MKAnnotationView+PersonIcon.h"
#import <StaticLayer.h>
#import "StaticPointAnnotation.h"
#import <HexColor.h>
#import "StyledPolygon.h"
#import "StyledPolyline.h"
#import "AreaAnnotation.h"
#import <MapKit/MapKit.h>
#import <NSDate+DateTools.h>
#import <Server+helper.h>

@interface MapDelegate ()
    @property (nonatomic, weak) IBOutlet MKMapView *mapView;
    @property (nonatomic, strong) User *selectedUser;
    @property (nonatomic, strong) MKCircle *selectedUserCircle;
    @property (nonatomic, strong) NSMutableDictionary *offlineMaps;
    @property (nonatomic, strong) NSMutableDictionary *staticLayers;
    @property (nonatomic, strong) AreaAnnotation *areaAnnotation;

    @property (nonatomic) BOOL isTrackingAnimation;
    @property (nonatomic) BOOL canShowUserCallout;
    @property (nonatomic) BOOL canShowObservationCallout;
    @property (nonatomic) BOOL canShowGpsLocationCallout;

    @property (strong, nonatomic) CLLocationManager *locationManager;
@end

@implementation MapDelegate

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver:self
                   forKeyPath:@"mapType"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        
        [defaults addObserver:self
                   forKeyPath:@"selectedOfflineMaps"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        if (!self.hideStaticLayers) {
            [defaults addObserver:self
                       forKeyPath:@"selectedStaticLayers"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        }
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    
    return self;
}

BOOL RectContainsLine(CGRect r, CGPoint lineStart, CGPoint lineEnd)
{
    BOOL (^LineIntersectsLine)(CGPoint, CGPoint, CGPoint, CGPoint) = ^BOOL(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End)
    {
        CGFloat q =
        //Distance between the lines' starting rows times line2's horizontal length
        (line1Start.y - line2Start.y) * (line2End.x - line2Start.x)
        //Distance between the lines' starting columns times line2's vertical length
        - (line1Start.x - line2Start.x) * (line2End.y - line2Start.y);
        CGFloat d =
        //Line 1's horizontal length times line 2's vertical length
        (line1End.x - line1Start.x) * (line2End.y - line2Start.y)
        //Line 1's vertical length times line 2's horizontal length
        - (line1End.y - line1Start.y) * (line2End.x - line2Start.x);
        
        if( d == 0 )
            return NO;
        
        CGFloat r = q / d;
        
        q =
        //Distance between the lines' starting rows times line 1's horizontal length
        (line1Start.y - line2Start.y) * (line1End.x - line1Start.x)
        //Distance between the lines' starting columns times line 1's vertical length
        - (line1Start.x - line2Start.x) * (line1End.y - line1Start.y);
        
        CGFloat s = q / d;
        if( r < 0 || r > 1 || s < 0 || s > 1 )
            return NO;
        
        return YES;
    };
    
    /*Test whether the line intersects any of:
     *- the bottom edge of the rectangle
     *- the right edge of the rectangle
     *- the top edge of the rectangle
     *- the left edge of the rectangle
     *- the interior of the rectangle (both points inside)
     */
    
    return (LineIntersectsLine(lineStart, lineEnd, CGPointMake(r.origin.x, r.origin.y), CGPointMake(r.origin.x + r.size.width, r.origin.y)) ||
            LineIntersectsLine(lineStart, lineEnd, CGPointMake(r.origin.x + r.size.width, r.origin.y), CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height)) ||
            LineIntersectsLine(lineStart, lineEnd, CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height), CGPointMake(r.origin.x, r.origin.y + r.size.height)) ||
            LineIntersectsLine(lineStart, lineEnd, CGPointMake(r.origin.x, r.origin.y + r.size.height), CGPointMake(r.origin.x, r.origin.y)) ||
            (CGRectContainsPoint(r, lineStart) && CGRectContainsPoint(r, lineEnd)));
}


-(void)mapTap:(UIGestureRecognizer*)gesture {
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gesture;
    if (tap.state == UIGestureRecognizerStateEnded) {
        CGPoint tapPoint = [tap locationInView:self.mapView];
        CLLocationCoordinate2D tapCoord = [self.mapView convertPoint:tapPoint toCoordinateFromView:self.mapView];
        MKMapPoint mapPoint = MKMapPointForCoordinate(tapCoord);
        CGPoint mapPointAsCGP = CGPointMake(mapPoint.x, mapPoint.y);
        
        CLLocationCoordinate2D l1 = [self.mapView convertPoint:CGPointMake(0,0) toCoordinateFromView:self.mapView];
        CLLocation *ll1 = [[CLLocation alloc] initWithLatitude:l1.latitude longitude:l1.longitude];
        CLLocationCoordinate2D l2 = [self.mapView convertPoint:CGPointMake(0,500) toCoordinateFromView:self.mapView];
        CLLocation *ll2 = [[CLLocation alloc] initWithLatitude:l2.latitude longitude:l2.longitude];
        double mpp = [ll1 distanceFromLocation:ll2] / 500.0;
        
        double tolerance = mpp * sqrt(2.0) * 20.0;
        
        if (_areaAnnotation != nil) {
            [_mapView deselectAnnotation:_areaAnnotation animated:NO];
            [_mapView removeAnnotation:_areaAnnotation];
            _areaAnnotation = nil;
        }
        
        CGRect tapRect = CGRectMake(mapPointAsCGP.x, mapPointAsCGP.y, tolerance, tolerance);
        
        for (NSString* layerId in self.staticLayers) {
            NSArray *layerFeatures = [self.staticLayers objectForKey:layerId];
            for (id feature in layerFeatures) {
                if ([feature isKindOfClass:[MKPolyline class]]) {
                    MKPolyline *polyline = (MKPolyline *) feature;
                    
                    MKMapPoint *polylinePoints = polyline.points;
                    
                    for (int p=0; p < polyline.pointCount-1; p++){
                        MKMapPoint mp = polylinePoints[p];
                        MKMapPoint mp2 = polylinePoints[p+1];
                        if (RectContainsLine(tapRect, CGPointMake(mp.x, mp.y), CGPointMake(mp2.x, mp2.y))) {
                            NSLog(@"tapped the polyline in layer %@ named %@", layerId, polyline.title);
                            _areaAnnotation = [[AreaAnnotation alloc] init];
                            _areaAnnotation.title = polyline.title;
                            _areaAnnotation.coordinate = tapCoord;
                            
                            [_mapView addAnnotation:_areaAnnotation];
                            [_mapView selectAnnotation:_areaAnnotation animated:NO];

                        }
                    }
                } else if ([feature isKindOfClass:[MKPolygon class]]){
                    MKPolygon *polygon = (MKPolygon*) feature;
                    
                    CGMutablePathRef mpr = CGPathCreateMutable();
                    
                    MKMapPoint *polygonPoints = polygon.points;
                    
                    for (int p=0; p < polygon.pointCount; p++){
                        MKMapPoint mp = polygonPoints[p];
                        if (p == 0)
                            CGPathMoveToPoint(mpr, NULL, mp.x, mp.y);
                        else
                            CGPathAddLineToPoint(mpr, NULL, mp.x, mp.y);
                    }
                    
                    
                    
                    if(CGPathContainsPoint(mpr , NULL, mapPointAsCGP, FALSE)){
                        NSLog(@"tapped the polygon in layer %@ named %@", layerId, polygon.title);
                        _areaAnnotation = [[AreaAnnotation alloc] init];
                        _areaAnnotation.title = polygon.title;
                        _areaAnnotation.coordinate = tapCoord;
                        
                        [_mapView addAnnotation:_areaAnnotation];
                        [_mapView selectAnnotation:_areaAnnotation animated:NO];
                    }
                    
                    CGPathRelease(mpr);
                }

            }
        }
    }
}

- (void) dealloc {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"mapType"];
    [defaults removeObserver:self forKeyPath:@"selectedOfflineMaps"];
    [defaults removeObserver:self forKeyPath:@"selectedStaticLayers"];
    
    self.locationManager.delegate = nil;
}

- (NSMutableDictionary *) offlineMaps {
    if (_offlineMaps == nil) {
        _offlineMaps = [[NSMutableDictionary alloc] init];
    }
    
    return _offlineMaps;
}

- (NSMutableDictionary *) staticLayers {
    if (_staticLayers == nil) {
        _staticLayers = [[NSMutableDictionary alloc] init];
    }
    
    return _staticLayers;
}

- (void) setLocations:(Locations *) locations {
    _locations = locations;
    _locations.delegate = self;
    
    NSError *error;
    if (![self.locations.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);
    }
    
    [self updateLocations:[self.locations.fetchedResultsController fetchedObjects]];
}

- (void) setObservations:(Observations *)observations {
    _observations = observations;
    _observations.delegate = self;
    
    NSError *error;
    if (![self.observations.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);
    }

    [self updateObservations:[self.observations.fetchedResultsController fetchedObjects]];
}

- (void) setMapView:(MKMapView *)mapView {
    _mapView = mapView;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _mapView.mapType = [defaults integerForKey:@"mapType"];
    
    [self updateOfflineMaps:[defaults objectForKey:@"selectedOfflineMaps"]];
    [self updateStaticLayers:[defaults objectForKey:@"selectedStaticLayers"]];
    
    if (!self.hideStaticLayers) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTap:)];
        [self.mapView addGestureRecognizer:tap];
    }
}

-(void) observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    if ([@"mapType" isEqualToString:keyPath] && self.mapView) {
        self.mapView.mapType = [object integerForKey:keyPath];
    } else if ([@"selectedOfflineMaps" isEqualToString:keyPath] && self.mapView) {
        [self updateOfflineMaps:[object objectForKey:keyPath]];
    } else if ([@"selectedStaticLayers" isEqualToString:keyPath] && self.mapView) {
        [self updateStaticLayers: [object objectForKey:keyPath]];
    }
}

-(void) setHideLocations:(BOOL) hideLocations {
    _hideLocations = hideLocations;
    [self hideAnnotations:[self.locationAnnotations allValues] hide:hideLocations];
}

-(void) setHideObservations:(BOOL) hideObservations {
    _hideObservations = hideObservations;
    [self hideAnnotations:[self.observationAnnotations allValues] hide:hideObservations];
}

- (void) hideAnnotations:(NSArray *) annotations hide:(BOOL) hide {
    for (id<MKAnnotation> annotation in annotations) {
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
        annotationView.hidden = hide;
        annotationView.accessibilityElementsHidden = hide;
        annotationView.enabled = !hide;
    }
}

- (void) updateOfflineMaps:(NSSet *) offlineMaps {
    NSMutableSet *unselectedOfflineMaps = [[self.offlineMaps allKeys] mutableCopy];
    
    for (NSString *offlineMap in offlineMaps) {
        
        if (![[self.offlineMaps allKeys] containsObject:offlineMap]) {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *template = [NSString stringWithFormat:@"file://%@/MapCache/%@/{z}/{x}/{y}.png", documentsDirectory, offlineMap];
            MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
            [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
            [self.offlineMaps setObject:overlay forKey:offlineMap];
        }
        
        [unselectedOfflineMaps removeObject:offlineMap];
    }
    
    for (NSString *unselectedOfflineMap in unselectedOfflineMaps) {
        MKTileOverlay *overlay = [self.offlineMaps objectForKey:unselectedOfflineMap];
        if (overlay) {
            [self.mapView removeOverlay:overlay];
            [self.offlineMaps removeObjectForKey:unselectedOfflineMap];
        }
    }
}

- (void) updateStaticLayers: (NSDictionary *) staticLayersPerEvent {
    if (self.hideStaticLayers) return;
    NSMutableSet *unselectedStaticLayers = [[self.staticLayers allKeys] mutableCopy];
    
    NSArray *staticLayers = [staticLayersPerEvent objectForKey:[[Server currentEventId] stringValue]];
    
    for (NSNumber *staticLayerId in staticLayers) {
        StaticLayer *staticLayer = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", staticLayerId, [Server currentEventId]]];
        if (![unselectedStaticLayers containsObject:staticLayerId]) {
            NSLog(@"adding the static layer %@ to the map", staticLayer.name);
            NSMutableArray *annotations = [NSMutableArray array];
            for (NSDictionary *feature in [staticLayer.data objectForKey:@"features"]) {
                if ([[feature valueForKeyPath:@"geometry.type"] isEqualToString:@"Point"]) {
                    StaticPointAnnotation *annotation = [[StaticPointAnnotation alloc] initWithFeature:feature];
                    [_mapView addAnnotation:annotation];
                    [annotations addObject:annotation];
                } else if([[feature valueForKeyPath:@"geometry.type"] isEqualToString:@"Polygon"]) {
                    NSMutableArray *coordinates = [NSMutableArray arrayWithArray:[feature valueForKeyPath:@"geometry.coordinates"]];
                    StyledPolygon *polygon = [MapDelegate generatePolygon:coordinates];
                    [polygon fillColorWithHexString:[feature valueForKeyPath:@"properties.style.polyStyle.color.rgb"] andAlpha: [[feature valueForKeyPath:@"properties.style.polyStyle.color.opacity"] floatValue]/255.0f];
                    [polygon lineColorWithHexString:[feature valueForKeyPath:@"properties.style.lineStyle.color.rgb"] andAlpha: [[feature valueForKeyPath:@"properties.style.lineStyle.color.opacity"] floatValue]/255.0f];
                    id lineWidth = [feature valueForKeyPath:@"properties.style.lineStyle.width"];
                    if (!lineWidth) {
                        polygon.lineWidth = 1.0f;
                    } else {
                        polygon.lineWidth = [lineWidth floatValue];
                    }
                    polygon.title = [feature valueForKeyPath:@"properties.name"];
                    [annotations addObject:polygon];
                    [_mapView addOverlay:polygon];
                } else if([[feature valueForKeyPath:@"geometry.type"] isEqualToString:@"LineString"]) {
                    NSMutableArray *coordinates = [NSMutableArray arrayWithArray:[feature valueForKeyPath:@"geometry.coordinates"]];
                    StyledPolyline *polyline = [MapDelegate generatePolyline:coordinates];
                    [polyline lineColorWithHexString: [feature valueForKeyPath:@"properties.style.lineStyle.color.rgb"] andAlpha: [[feature valueForKeyPath:@"properties.style.lineStyle.color.opacity"] floatValue]/255.0f];
                    id lineWidth = [feature valueForKeyPath:@"properties.style.lineStyle.width"];
                    if (!lineWidth) {
                        polyline.lineWidth = 1.0f;
                    } else {
                        polyline.lineWidth = [lineWidth floatValue];
                    }
                    polyline.title = [feature valueForKeyPath:@"properties.name"];
                    [annotations addObject:polyline];
                    [_mapView addOverlay:polyline];
                }
            }
            [self.staticLayers setObject:annotations forKey:staticLayerId];
        }
        
        [unselectedStaticLayers removeObject:staticLayerId];
    }
    
    for (NSNumber *unselectedStaticLayerId in unselectedStaticLayers) {
        StaticLayer *unselectedStaticLayer = [StaticLayer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", unselectedStaticLayerId, [Server currentEventId]]];
        NSLog(@"removing the layer %@ from the map", unselectedStaticLayer.name);
        for (id staticItem in [self.staticLayers objectForKey:unselectedStaticLayerId]) {
            if ([staticItem conformsToProtocol:@protocol(MKOverlay)]) {
                [self.mapView removeOverlay:staticItem];
            } else if ([staticItem conformsToProtocol:@protocol(MKAnnotation)]) {
                [self.mapView removeAnnotation:staticItem];
            }
        }
        [self.staticLayers removeObjectForKey:unselectedStaticLayerId];
    }
}

+ (StyledPolyline *) generatePolyline:(NSMutableArray *) coordinates {
    
    CLLocationCoordinate2D *exteriorMapCoordinates = malloc(coordinates.count * sizeof(CLLocationCoordinate2D));
    NSInteger exteriorCoordinateCount = 0;
    for (id coordinate in coordinates) {
        NSNumber *y = coordinate[0];
        NSNumber *x = coordinate[1];
        CLLocationCoordinate2D exteriorCoord = CLLocationCoordinate2DMake([x doubleValue], [y doubleValue]);
        exteriorMapCoordinates[exteriorCoordinateCount++] = exteriorCoord;
    }
    
    return [StyledPolyline polylineWithCoordinates:exteriorMapCoordinates count:coordinates.count];
}


+ (StyledPolygon *) generatePolygon:(NSMutableArray *) coordinates {
    //exterior polygon
    NSMutableArray *exteriorPolygonCoordinates = coordinates[0];
    NSMutableArray *interiorPolygonCoordinates = [[NSMutableArray alloc] init];
    
    
    CLLocationCoordinate2D *exteriorMapCoordinates = malloc(exteriorPolygonCoordinates.count * sizeof(CLLocationCoordinate2D));
    NSInteger exteriorCoordinateCount = 0;
    for (id coordinate in exteriorPolygonCoordinates) {
        NSNumber *y = coordinate[0];
        NSNumber *x = coordinate[1];
        CLLocationCoordinate2D exteriorCoord = CLLocationCoordinate2DMake([x doubleValue], [y doubleValue]);
        exteriorMapCoordinates[exteriorCoordinateCount++] = exteriorCoord;
    }
    
    //interior polygons
    NSMutableArray *interiorPolygons = [[NSMutableArray alloc] init];
    if (coordinates.count > 1) {
        [interiorPolygonCoordinates addObjectsFromArray:coordinates];
        [interiorPolygonCoordinates removeObjectAtIndex:0];
        MKPolygon *recursePolygon = [MapDelegate generatePolygon:interiorPolygonCoordinates];
        [interiorPolygons addObject:recursePolygon];
    }

    StyledPolygon *exteriorPolygon;
    if (interiorPolygons.count > 0) {
        exteriorPolygon = [StyledPolygon polygonWithCoordinates:exteriorMapCoordinates count:exteriorPolygonCoordinates.count interiorPolygons:[NSArray arrayWithArray:interiorPolygons]];
    }
    else {
        exteriorPolygon = [StyledPolygon polygonWithCoordinates:exteriorMapCoordinates count:exteriorPolygonCoordinates.count];
    }
    
    return exteriorPolygon;
}


- (void) setUserTrackingMode:(MKUserTrackingMode) mode animated:(BOOL) animated {
    if (!self.isTrackingAnimation || mode != MKUserTrackingModeFollowWithHeading) {
        [self.mapView setUserTrackingMode:mode animated:animated];
    }
}

- (void) mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    if (self.userTrackingModeDelegate) {
        [self.userTrackingModeDelegate userTrackingModeChanged:mode];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (self.mapView.userTrackingMode == MKUserTrackingModeFollow) {
        self.isTrackingAnimation = YES;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.mapView.userTrackingMode == MKUserTrackingModeFollow) {
        self.isTrackingAnimation = NO;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
        MKAnnotationView *annotationView = [locationAnnotation viewForAnnotationOnMapView:self.mapView];
        annotationView.canShowCallout = self.canShowUserCallout;
        annotationView.hidden = self.hideLocations;
        annotationView.accessibilityElementsHidden = self.hideLocations;
        annotationView.enabled = !self.hideLocations;
        return annotationView;
    } else if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        MKAnnotationView *annotationView = [observationAnnotation viewForAnnotationOnMapView:self.mapView];
        annotationView.canShowCallout = self.canShowObservationCallout;
        annotationView.hidden = self.hideObservations;
        annotationView.accessibilityElementsHidden = self.hideObservations;
        annotationView.enabled = !self.hideObservations;
        return annotationView;
    } else if ([annotation isKindOfClass:[GPSLocationAnnotation class]]) {
        GPSLocationAnnotation *gpsAnnotation = annotation;
        MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"gpsLocationAnnotation"];
        
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"gpsLocationAnnotation"];
            annotationView.enabled = YES;
            annotationView.canShowCallout = self.canShowGpsLocationCallout;
            
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
            annotationView.rightCalloutAccessoryView = rightButton;
            annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
        } else {
            annotationView.annotation = annotation;
        }
        
        [annotationView setImageForUser:gpsAnnotation.user];
        
        return annotationView;
    } else if ([annotation isKindOfClass:[StaticPointAnnotation class]]) {
        StaticPointAnnotation *staticAnnotation = annotation;
        return [staticAnnotation viewForAnnotationOnMapView:self.mapView];
    } else if ([annotation isKindOfClass:[AreaAnnotation class]]) {
        AreaAnnotation *areaAnnotation = annotation;
        return [areaAnnotation viewForAnnotationOnMapView:self.mapView];
    }
    return nil;
}

- (void)mapView:(MKMapView *) mapView didSelectAnnotationView:(MKAnnotationView *) view {
    if ([view.annotation isKindOfClass:[LocationAnnotation class]]) {
        LocationAnnotation *annotation = view.annotation;
        self.selectedUser = annotation.location.user;
        
        if ([self.selectedUser avatarUrl] != nil) {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", documentsDirectory, self.selectedUser.avatarUrl]]];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
            view.leftCalloutAccessoryView = imageView;
            
            [imageView setImage:image];// setImageWithURLRequest:[NSURLRequest requestWithURL:url] placeholderImage:nil success:nil failure:nil];
        }
        
        if (self.selectedUserCircle != nil) {
            [_mapView removeOverlay:self.selectedUserCircle];
        }
        
        NSDictionary *properties = self.selectedUser.location.properties;
        id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
        if (accuracyProperty != nil) {
            double accuracy = [accuracyProperty doubleValue];
            
            self.selectedUserCircle = [MKCircle circleWithCenterCoordinate:self.selectedUser.location.location.coordinate radius:accuracy];
            [self.mapView addOverlay:self.selectedUserCircle];
        }
    }
}

- (void)mapView:(MKMapView *) mapView didDeselectAnnotationView:(MKAnnotationView *) view {
    if (self.selectedUserCircle != nil) {
        [_mapView removeOverlay:self.selectedUserCircle];
    }
    
    if (_areaAnnotation != nil && view.annotation == _areaAnnotation) {
        [self performSelector:@selector(reSelectAnnotationIfNoneSelected:)
                   withObject:view.annotation afterDelay:0];
    }
}

- (void)reSelectAnnotationIfNoneSelected:(id<MKAnnotation>)annotation {
    if (_mapView.selectedAnnotations == nil || _mapView.selectedAnnotations.count == 0)
        [_mapView selectAnnotation:annotation animated:NO];
}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control {

	if ([view.annotation isKindOfClass:[LocationAnnotation class]] || view.annotation == mapView.userLocation) {
        if (self.mapCalloutDelegate) {
            LocationAnnotation *annotation = view.annotation;
            [self.mapCalloutDelegate calloutTapped:annotation.location.user];
        }
	} else if ([view.annotation isKindOfClass:[ObservationAnnotation class]]) {
        if (self.mapCalloutDelegate) {
            ObservationAnnotation *annotation = view.annotation;
            [self.mapCalloutDelegate calloutTapped:annotation.observation];
        }
	}
}

- (MKOverlayRenderer *) mapView:(MKMapView *) mapView rendererForOverlay:(id < MKOverlay >) overlay {
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    } else if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
        renderer.lineWidth = 1.0f;
        
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.selectedUser.location.timestamp];
        if (interval <= 600) {
            renderer.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.1f];
            renderer.strokeColor = [UIColor blueColor];
        } else if (interval <= 1200) {
            renderer.fillColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:.1f];
            renderer.strokeColor = [UIColor yellowColor];
        } else {
            renderer.fillColor = [UIColor colorWithRed:1 green:.5 blue:0 alpha:.1f];
            renderer.strokeColor = [UIColor orangeColor];
        }
        
        return renderer;
    } else if ([overlay isKindOfClass:[StyledPolygon class]]) {
        StyledPolygon *polygon = (StyledPolygon *) overlay;
        MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:polygon];
        renderer.fillColor = polygon.fillColor;
        renderer.strokeColor = polygon.lineColor;
        renderer.lineWidth = polygon.lineWidth;
        return renderer;
    } else if ([overlay isKindOfClass:[StyledPolyline class]]) {
        StyledPolyline *polyline = (StyledPolyline *) overlay;
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        renderer.strokeColor = polyline.lineColor;
        renderer.lineWidth = polyline.lineWidth;
        return renderer;
    }

    return nil;
}

- (NSMutableDictionary *) locationAnnotations {
    if (!_locationAnnotations) {
        _locationAnnotations = [[NSMutableDictionary alloc] init];
    }
    
    return _locationAnnotations;
}

- (NSMutableDictionary *) observationAnnotations {
    if (!_observationAnnotations) {
        _observationAnnotations = [[NSMutableDictionary alloc] init];
    }
    
    return _observationAnnotations;
}

#pragma mark - NSFetchResultsController

- (void) controller:(NSFetchedResultsController *) controller
    didChangeObject:(id) object
        atIndexPath:(NSIndexPath *) indexPath
      forChangeType:(NSFetchedResultsChangeType) type
       newIndexPath:(NSIndexPath *)newIndexPath {
    
    if ([object isKindOfClass:[Observation class]]) {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateObservation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self deleteObservation:object];
                NSLog(@"Got delete for observation");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateObservation:object];
                break;
            default:
                break;
        }
        
    } else {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateLocation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for location");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateLocation:object];
                break;
            default:
                break;
        }
    }
}

- (void) updateLocations:(NSArray *)locations {
    for (Location *location in locations) {
        [self updateLocation:location];
    }
}

- (void) updateObservations:(NSArray *)observations {
    for (Observation *observation in observations) {
        [self updateObservation:observation];
    }
}

- (void) updateLocation:(Location *) location {
    User *user = location.user;
    
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    if (annotation == nil) {
        annotation = [[LocationAnnotation alloc] initWithLocation:location];
        [_mapView addAnnotation:annotation];
        [self.locationAnnotations setObject:annotation forKey:user.remoteId];
    } else {
        [annotation setSubtitle:location.timestamp.timeAgoSinceNow];
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        [annotation setCoordinate:[location location].coordinate];
        
        [annotationView setImageForUser:annotation.location.user];
    }
}

- (void) updateGPSLocation:(GPSLocation *)location forUser:(User *)user andCenter: (BOOL) shouldCenter {
    GPSLocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    if (annotation == nil) {
        annotation = [[GPSLocationAnnotation alloc] initWithGPSLocation:location andUser:user];
        [_mapView addAnnotation:annotation];
        [self.locationAnnotations setObject:annotation forKey:user.remoteId];
        GeoPoint *geoPoint = (GeoPoint *)location.geometry;
        [self.mapView setCenterCoordinate:geoPoint.location.coordinate];
    } else {
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        GeoPoint *geoPoint = (GeoPoint *)location.geometry;
        [annotation setCoordinate:geoPoint.location.coordinate];
        if (shouldCenter) {
            [self.mapView setCenterCoordinate:geoPoint.location.coordinate];
        }
        
        [annotationView setImageForUser:user];
    }
}

- (void) updateObservation: (Observation *) observation {
    ObservationAnnotation *annotation = [self.observationAnnotations objectForKey:observation.objectID];
    if (annotation == nil) {
        annotation = [[ObservationAnnotation alloc] initWithObservation:observation];
        [_mapView addAnnotation:annotation];
        [self.observationAnnotations setObject:annotation forKey:observation.objectID];
    } else {
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        annotationView.image = [ObservationImage imageForObservation:observation scaledToWidth:[NSNumber numberWithFloat:35]];
        [annotation setCoordinate:[observation location].coordinate];
    }
}

- (void) deleteObservation: (Observation *) observation {
    ObservationAnnotation *annotation = [self.observationAnnotations objectForKey:observation.objectID];
    [_mapView removeAnnotation:annotation];
    [self.observationAnnotations removeObjectForKey:observation.objectID];
}

- (void)selectedUser:(User *) user {
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    [self.mapView selectAnnotation:annotation animated:YES];
    
    [self.mapView setCenterCoordinate:[annotation.location location].coordinate];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapView setCenterCoordinate:[observation location].coordinate];
    
    ObservationAnnotation *annotation = [self.observationAnnotations objectForKey:observation.objectID];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    LocationAnnotation *annotation = [self.observationAnnotations objectForKey:observation.remoteId];
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)observationDetailSelected:(Observation *)observation {
    [self selectedObservation:observation];
}

- (void)userDetailSelected:(User *)user {
    [self selectedUser:user];
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (self.locationAuthorizationChangedDelegate) {
        [self.locationAuthorizationChangedDelegate locationManager:manager didChangeAuthorizationStatus:status];
    }
}


@end
