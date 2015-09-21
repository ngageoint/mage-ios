//
//  ObservationEditGeometryTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import <GeoPoint.h>
#import <MapKit/MapKit.h>

@interface ObservationEditGeometryTableViewCell : ObservationEditTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (strong, nonatomic) GeoPoint *geoPoint;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
