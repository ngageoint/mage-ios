//
//  ObservationCommonHeaderTableViewCell.h
//  MAGE
//
//

#import "ObservationHeaderTableViewCell.h"
#import <MapKit/MapKit.h>

@interface ObservationCommonHeaderTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *primaryFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *variantFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
