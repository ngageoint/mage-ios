//
//  ObservationMapTableViewCell.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"
#import <MapKit/MapKit.h>

@interface ObservationMapTableViewCell : ObservationHeaderTableViewCell

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
