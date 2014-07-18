//
//  PersonViewController.h
//  Mage
//
//  Created by Billy Newman on 7/17/14.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "Location+helper.h"

@interface PersonViewController : UIViewController<MKMapViewDelegate>

@property (strong, nonatomic) Location *location;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;


@end
