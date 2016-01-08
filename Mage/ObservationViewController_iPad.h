//
//  ObservationViewerViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "Attachment.h"
#import "AttachmentCollectionDataStore.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationViewController_iPad : UIViewController<MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource, AttachmentSelectionDelegate>

@property (strong, nonatomic) Observation *observation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UITableView *propertyTable;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) IBOutlet AttachmentCollectionDataStore *attachmentCollectionDataStore;

@end
