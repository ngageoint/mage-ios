//
//  ObservationEditGeometryTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import <GeoPoint.h>
#import <MapKit/MapKit.h>
#import "ObservationAnnotationChangedDelegate.h"

@interface ObservationEditGeometryTableViewCell : ObservationEditTableViewCell<ObservationAnnotationChangedDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (strong, nonatomic) GeoPoint *geoPoint;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
