//
//  GeometryEditViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "ObservationEditTableViewController.h"
#import "AnnotationDragCallback.h"

@interface GeometryEditViewController : UIViewController <AnnotationDragCallback>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UIButton *pointButton;
@property (weak, nonatomic) IBOutlet UIButton *lineButton;
@property (weak, nonatomic) IBOutlet UIButton *rectangleButton;
@property (weak, nonatomic) IBOutlet UIButton *polygonButton;

- (instancetype) initWithFieldDefinition: (NSDictionary *) fieldDefinition andObservation: (Observation *) observation andDelegate:(id<PropertyEditDelegate>)delegate;

@end
