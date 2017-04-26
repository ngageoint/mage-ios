//
//  ObservationEditGeometryTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "ObservationAnnotationChangedDelegate.h"
#import "WKBGeometry.h"

@interface ObservationEditGeometryTableViewCell : ObservationEditTableViewCell<ObservationAnnotationChangedDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (strong, nonatomic) WKBGeometry *geometry;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
