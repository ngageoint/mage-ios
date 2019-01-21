//
//  ObservationEditGeometryTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "ObservationAnnotationChangedDelegate.h"
#import "SFGeometry.h"

@interface ObservationEditGeometryTableViewCell : ObservationEditTableViewCell<ObservationAnnotationChangedDelegate>

@property (weak, nonatomic) IBOutlet UILabel *latitude;
@property (weak, nonatomic) IBOutlet UILabel *longitude;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (strong, nonatomic) SFGeometry *geometry;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) NSArray *forms;
@property (weak, nonatomic) Observation *observation;

@end
