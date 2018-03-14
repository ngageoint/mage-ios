//
//  ObservationEditGeometryTableViewCell.m
//  MAGE
//
//

#import "ObservationEditGeometryTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import "Observation.h"
#import "MapDelegate.h"
#import "ObservationAnnotation.h"
#import "GeometryUtility.h"
#import "MapObservationManager.h"
#import "MapAnnotationObservation.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGMapShapePoints.h"
#import "MapShapePointsObservation.h"
#import "Theme+UIResponder.h"

@interface MKMapView ()
-(void) _setShowsNightMode:(BOOL)yesOrNo;
@end

@interface ObservationEditGeometryTableViewCell()

@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (strong, nonatomic) MapObservation *mapObservation;
@property (strong, nonatomic) MapObservationManager *observationManager;
@property (assign, nonatomic) BOOL isGeometryField;

@end

@implementation ObservationEditGeometryTableViewCell

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    // special case if it is the actual observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geometry = [value objectForKey:@"geometry"];
        self.isGeometryField = YES;
    } else {
        id geometry = value;
        if (geometry) {
            self.geometry = (WKBGeometry *) geometry;
        } else {
            self.geometry = nil;
        }
        self.isGeometryField = NO;
    }

    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
    
    self.mapDelegate = [[MapDelegate alloc] init];

    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    self.mapDelegate.hideStaticLayers = YES;
    
    if (self.geometry) {
        if (self.isGeometryField) {
            self.observationManager = [[MapObservationManager alloc] initWithMapView:self.mapView andEventForms:[value objectForKey:@"forms"]];
            self.mapObservation = [self.observationManager addToMapWithObservation:[value objectForKey:@"observation"]];
            MKCoordinateRegion viewRegion = [self.mapObservation viewRegionOfMapView:self.mapView];
            [self.mapView setRegion:viewRegion animated:NO];
        }
        
        WKBPoint *point = [GeometryUtility centroidOfGeometry:self.geometry];
        [self.latitude setText:[NSString stringWithFormat:@"%.6f", [point.y doubleValue]]];
        [self.longitude setText:[NSString stringWithFormat:@"%.6f", [point.x doubleValue]]];

        if (!self.isGeometryField) {
            GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
            if (self.geometry.geometryType == WKB_POINT) {
                GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:self.geometry];
                [shapeConverter addMapShape:shape asPointsToMapView:self.mapView withPointOptions:nil andPolylinePointOptions:nil andPolygonPointOptions:nil andPolygonPointHoleOptions:nil];
            } else {
                GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:self.geometry];
                GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
                options.image = [[UIImage alloc] init];
                [shapeConverter addMapShape:shape asPointsToMapView:self.mapView withPointOptions:options andPolylinePointOptions:options andPolygonPointOptions:options andPolygonPointHoleOptions:options];
            }
            
            MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue]), MKCoordinateSpanMake(.03125, .03125));
            MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
            [self.mapView setRegion:viewRegion animated:NO];
        }
            
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        
        [self.latitude setText:@""];
        [self.longitude setText:@""];
    }
}

- (BOOL) isEmpty {
    return self.geometry == nil;
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    if (theme == Night) {
        [self.mapView _setShowsNightMode:YES];
    } else {
        [self.mapView _setShowsNightMode:NO];
    }
    self.backgroundColor = [UIColor dialog];
    self.keyLabel.textColor = [UIColor primaryText];
    self.latitudeLabel.textColor = [UIColor primaryText];
    self.longitudeLabel.textColor = [UIColor primaryText];
    self.mapView.layer.borderColor = [[UIColor tableBackground] CGColor];
    if (self.fieldValueValid) {
        self.latitude.textColor = [UIColor primaryText];
        self.longitude.textColor = [UIColor primaryText];
        self.requiredIndicator.textColor = [UIColor primaryText];
    } else {
        self.latitude.textColor = [UIColor redColor];
        self.longitude.textColor = [UIColor redColor];
        self.requiredIndicator.textColor = [UIColor redColor];
    }
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.latitudeLabel.textColor = nil;
        self.longitudeLabel.textColor = nil;
    } else {
        self.latitudeLabel.textColor = [UIColor redColor];
        self.longitudeLabel.textColor = [UIColor redColor];
    }
}

- (void) typeChanged:(Observation *) observation {
    if (self.isGeometryField) {
        [self.mapObservation removeFromMapView:self.mapView];
        self.mapObservation = [self.observationManager addToMapWithObservation:observation];
    }
}

- (void) variantChanged:(Observation *)observation {
    if (self.isGeometryField) {
        [self.mapObservation removeFromMapView:self.mapView];
        self.mapObservation = [self.observationManager addToMapWithObservation:observation];
    }
}

@end
