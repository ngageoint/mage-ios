//
//  ObservationAnnotation.m
//  Mage
//
//

@import DateTools;

#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "MapShapeObservation.h"
#import "ObservationAnnotationView.h"
#import "SFGeometryUtils.h"

@interface ObservationAnnotation ()

@property (nonatomic) BOOL point;

@end

@implementation ObservationAnnotation

NSString * OBSERVATION_ANNOTATION_VIEW_REUSE_ID = @"OBSERVATION_ICON";

-(id) initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms {
    return [self initWithObservation:observation andEventForms: forms andGeometry:[observation getGeometry]];
}

-(id) initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms andGeometry: (SFGeometry *) geometry {
    SFPoint *point = [SFGeometryUtils centroidOfGeometry:geometry];
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue]);
    self.point = YES;
    return [self initWithObservation:observation andEventForms: forms andLocation:location];
}

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms andLocation:(CLLocationCoordinate2D) location{
    if ((self = [super init])) {
        _observation = observation;
        [self setCoordinate:location];
        [self setTitle:[observation primaryFeedFieldText]];
        
        if ([self.title length] == 0) {
            [self setTitle:@"Observation"];
        }
        [self setSubtitle:observation.timestamp.timeAgoSinceNow];
    }
    [self setAccessibilityLabel:@"Observation Annotation"];
    [self setAccessibilityValue:@"Observation Annotation"];
    return self;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView scheme: (id<MDCContainerScheming>) scheme {
    return [self viewForAnnotationOnMapView:mapView withDragCallback:nil scheme:scheme];
}

-(MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView withDragCallback: (NSObject<AnnotationDragCallback> *) dragCallback scheme: (id<MDCContainerScheming>) scheme{
    UIImage *image = [ObservationImage imageForObservation:self.observation];
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:OBSERVATION_ANNOTATION_VIEW_REUSE_ID];
    
    if (annotationView == nil) {
        annotationView = [[ObservationAnnotationView alloc] initWithAnnotation:self reuseIdentifier:OBSERVATION_ANNOTATION_VIEW_REUSE_ID andMapView:mapView andDragCallback:dragCallback];
        annotationView.enabled = YES;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
//        rightButton.tintColor = [UIColor mageBlue];
        annotationView.rightCalloutAccessoryView = rightButton;
    } else {
        annotationView.annotation = self;
    }
    
    if (self.point) {
        annotationView.image = image;
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
    } else {
        annotationView.image = nil;
        annotationView.frame = CGRectMake(0, 0, 0, 0);
        annotationView.centerOffset = CGPointMake(0, 0);
    }
    
    [annotationView setAccessibilityLabel:@"Observation"];
    [annotationView setAccessibilityValue:@"Observation"];
//    annotationView.clusteringIdentifier = @"observationAnnotation";
    annotationView.displayPriority = MKFeatureDisplayPriorityRequired;
//    annotationView.collisionMode = MKAnnotationViewCollisionModeNone;
    return annotationView;
}

@end
