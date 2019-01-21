//
//  ObservationGeometryTableViewCell.m
//  Mage
//
//

#import "ObservationGeometryTableViewCell.h"
#import "SFGeometry.h"
#import "SFGeometryUtils.h"
#import "MapDelegate.h"
#import "GPKGMapShapeConverter.h"
#import "Theme+UIResponder.h"

@interface ObservationGeometryTableViewCell ()

@property (strong, nonatomic) MapDelegate *mapDelegate;

@end

@implementation ObservationGeometryTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.valueTextView.textColor = [UIColor primaryText];
    self.keyLabel.textColor = [UIColor secondaryText];
    [UIColor themeMap:self.map];
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    
    if(self.mapDelegate == nil){
        self.mapDelegate = [[MapDelegate alloc] init];
    }
    [self.mapDelegate setMapView: self.map];
    self.map.delegate = self.mapDelegate;
    
    [self.map removeAnnotations:self.map.annotations];
    [self.map removeOverlays:self.map.overlays];
    
    self.mapDelegate.hideStaticLayers = YES;
    
    if ([value isKindOfClass:[SFGeometry class]]) {
        SFGeometry *geometry = value;
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:geometry];
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", [centroid.y doubleValue], [centroid.x doubleValue]];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
        
        GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
        if (geometry.geometryType == SF_POINT) {
            GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:geometry];
            [shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:nil andPolylinePointOptions:nil andPolygonPointOptions:nil andPolygonPointHoleOptions:nil];
        } else {
            GPKGMapShape *shape = [shapeConverter toShapeWithGeometry:geometry];
            GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
            options.image = [[UIImage alloc] init];
            [shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:options andPolylinePointOptions:options andPolygonPointOptions:options andPolygonPointHoleOptions:options];
        }
        
        MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]), MKCoordinateSpanMake(.03125, .03125));
        MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
        [self.map setRegion:viewRegion animated:NO];
        
    } else {
        NSDictionary *geometry = value;
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", [[geometry objectForKey:@"y"] floatValue], [[geometry objectForKey:@"x"] floatValue]];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
    }
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
    [self registerForThemeChanges];
}

@end
