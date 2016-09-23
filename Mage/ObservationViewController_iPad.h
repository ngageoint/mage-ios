//
//  ObservationViewerViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ObservationViewController.h"
#import "Observation.h"
#import "Attachment.h"

@interface ObservationViewController_iPad : ObservationViewController<MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;

@end
