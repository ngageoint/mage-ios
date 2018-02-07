//
//  ObservationGeometryTableViewCell.h
//  Mage
//
//

#import "ObservationPropertyTableViewCell.h"

#import <MapKit/MapKit.h>

@interface ObservationGeometryTableViewCell : ObservationPropertyTableViewCell

@property (weak, nonatomic) IBOutlet MKMapView *map;

@end
