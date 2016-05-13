//
//  MapViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapDelegate.h"
#import "Locations.h"
#import "Observations.h"
#import "TimeFilter.h"

@interface MapViewController : UIViewController
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet MapDelegate *mapDelegate;
@end
