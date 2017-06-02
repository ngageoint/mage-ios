//
//  GeometryEditViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "ObservationEditViewController.h"
#import "AnnotationDragCallback.h"

@interface GeometryEditViewController : UIViewController <MKMapViewDelegate, AnnotationDragCallback>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *pointButton;
@property (weak, nonatomic) IBOutlet UIButton *lineButton;
@property (weak, nonatomic) IBOutlet UIButton *rectangleButton;
@property (weak, nonatomic) IBOutlet UIButton *polygonButton;
@property (nonatomic, strong) Observation *observation;
@property (strong, nonatomic) id fieldDefinition;
@property (weak, nonatomic) id<PropertyEditDelegate> propertyEditDelegate;

- (IBAction) saveLocation;

@end
