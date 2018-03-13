//
//  ObservationGeometryTableViewCell.m
//  Mage
//
//

#import "ObservationGeometryTableViewCell.h"
#import "WKBGeometry.h"
#import "WKBGeometryUtils.h"
#import "MapDelegate.h"
#import <GPKGMapShapeConverter.h>
#import "Theme+UIResponder.h"

@interface MKMapView ()
-(void) _setShowsNightMode:(BOOL)yesOrNo;
@end

@interface ObservationGeometryTableViewCell ()

@property (strong, nonatomic) MapDelegate *mapDelegate;

@end

@implementation ObservationGeometryTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.valueTextView.textColor = [UIColor primaryText];
    self.keyLabel.textColor = [UIColor secondaryText];
    if (theme == Day) {
        [self.map _setShowsNightMode:NO];
    } else {
        [self.map _setShowsNightMode:YES];
    }
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
    
    if ([value isKindOfClass:[WKBGeometry class]]) {
        WKBGeometry *geometry = value;
        WKBPoint *centroid = [WKBGeometryUtils centroidOfGeometry:geometry];
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", [centroid.y doubleValue], [centroid.x doubleValue]];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
        
        GPKGMapShapeConverter *shapeConverter = [[GPKGMapShapeConverter alloc] init];
        if (geometry.geometryType == WKB_POINT) {
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
