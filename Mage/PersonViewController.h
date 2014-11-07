//
//  PersonViewController.h
//  Mage
//
//  Created by Billy Newman on 7/17/14.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "User+helper.h"
#import "ManagedObjectContextHolder.h"
#import "MapDelegate.h"
#import "ObservationDataStore.h"

@interface PersonViewController : UIViewController

@property (strong, nonatomic) User *user;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *latLng;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UITextView *contact1;
@property (weak, nonatomic) IBOutlet UITextView *contact2;
@property (weak, nonatomic) IBOutlet UITableView *observationTableView;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;

@end