//
//  PersonViewController.h
//  Mage
//
//  Created by Billy Newman on 7/17/14.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "Location+helper.h"

@interface PersonViewController : UIViewController<MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Location *location;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *latLng;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *phone;
@property (weak, nonatomic) IBOutlet UITableView *observationTableView;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *observationResultsController;

@end