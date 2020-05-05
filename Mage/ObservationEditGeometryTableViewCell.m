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
#import <mgrs/MGRS.h>

@import SkyFloatingLabelTextField;
@import HexColors;

@interface ObservationEditGeometryTableViewCell()

@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *locationField;
@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (strong, nonatomic) MapObservation *mapObservation;
@property (strong, nonatomic) MapObservationManager *observationManager;
@property (assign, nonatomic) BOOL isGeometryField;

@end

@implementation ObservationEditGeometryTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];

    if (self.mapDelegate) {
        [self.mapDelegate cleanup];
        self.mapDelegate = nil;
    }
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor background];
    
    self.locationField.textColor = [UIColor primaryText];
    self.locationField.selectedLineColor = [UIColor brand];
    self.locationField.selectedTitleColor = [UIColor brand];
    self.locationField.placeholderColor = [UIColor secondaryText];
    self.locationField.lineColor = [UIColor secondaryText];
    self.locationField.titleColor = [UIColor secondaryText];
    self.locationField.errorColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    self.locationField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.locationField.iconText = @"\U0000f0ac";
    self.locationField.iconColor = [UIColor secondaryText];
    
    [UIColor themeMap:self.mapView];
    [self.mapDelegate updateTheme];
}

- (void) populateCellWithFormField: (id) field andValue: (id) value {
    // special case if it is the actual observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geometry = [value objectForKey:@"geometry"];
        self.isGeometryField = YES;
    } else {
        id geometry = value;
        if (geometry) {
            self.geometry = (SFGeometry *) geometry;
        } else {
            self.geometry = nil;
        }
        self.isGeometryField = NO;
    }
    
    self.locationField.errorMessage = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMGRS"]) {
        self.locationField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [NSString stringWithFormat:@"%@ (MGRS)", [field objectForKey:@"title"]] : [NSString stringWithFormat:@"%@ (MGRS) %@", [field objectForKey:@"title"], @"*"];
    } else {
        self.locationField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [NSString stringWithFormat:@"%@ (Lat, Long)", [field objectForKey:@"title"]] : [NSString stringWithFormat:@"%@ (Lat, Long) %@", [field objectForKey:@"title"], @"*"];
    }
    self.mapDelegate = [[MapDelegate alloc] init];

    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    [self.mapDelegate setupListeners];
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
        
        SFPoint *point = [GeometryUtility centroidOfGeometry:self.geometry];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showMGRS"]) {
            self.locationField.text = [MGRS MGRSfromCoordinate:CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue])];
        } else {
            self.locationField.text = [NSString stringWithFormat:@"%.6f, %.6f", [point.y doubleValue], [point.x doubleValue]];
        }

        if (!self.isGeometryField) {
            GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
            if (self.geometry.geometryType == SF_POINT) {
                GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:self.geometry];
                [shapeConverter addMapShape:shape asPointsToMapView:self.mapView withPointOptions:nil andPolylinePointOptions:nil andPolygonPointOptions:nil andPolygonPointHoleOptions:nil andPolylineOptions:nil andPolygonOptions:nil];
            } else {
                GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:self.geometry];
                GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
                options.image = [[UIImage alloc] init];
                [shapeConverter addMapShape:shape asPointsToMapView:self.mapView withPointOptions:options andPolylinePointOptions:options andPolygonPointOptions:options andPolygonPointHoleOptions:options andPolylineOptions:options andPolygonOptions:options];
            }
            
            MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue]), MKCoordinateSpanMake(.03125, .03125));
            MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
            [self.mapView setRegion:viewRegion animated:NO];
        }
            
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        self.locationField.text = @"";
    }
    [self.mapDelegate ensureMapLayout];
}

- (BOOL) isEmpty {
    return self.geometry == nil;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.locationField.errorMessage = nil;
    } else {
        self.locationField.errorMessage = self.locationField.placeholder;
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
