//
//  ObservationViewerViewController.m
//  Mage
//
//

#import "ObservationViewController_iPad.h"
#import "GeoPoint.h"
#import "Observation.h"
#import "ObservationImportant.h"
#import "ObservationFavorite.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "ObservationHeaderTableViewCell.h"
#import "ObservationPropertyTableViewCell.h"
#import "User.h"
#import "Role.h"
#import "AttachmentCell.h"
#import "AttachmentViewController.h"
#import "ObservationEditViewController.h"
#import "Server.h"
#import "MapDelegate.h"
#import "ObservationDataStore.h"
#import "Event.h"
#import "NSDate+display.h"
#import "Attachment+Thumbnail.h"
#import "ObservationFields.h"

@interface ObservationViewController_iPad ()<NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;

@end

@implementation ObservationViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.attachmentCollectionDataStore.attachmentFormatName = AttachmentMediumSquare;    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.userLabel.text = self.observation.user.name;
    
    self.userLabel.text = self.observation.user.name;
    self.timestampLabel.text = [self.observation.timestamp formattedDisplayDate];
	
	self.locationLabel.text = [NSString stringWithFormat:@"%.6f, %.6f", self.observation.location.coordinate.latitude, self.observation.location.coordinate.longitude];
    
    CLLocationDistance latitudeMeters = 500;
    CLLocationDistance longitudeMeters = 500;
    NSDictionary *properties = self.observation.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.observation.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    
    [self.mapDelegate selectedObservation:self.observation region:viewRegion];
    
    self.attachmentCollectionDataStore.attachmentSelectionDelegate = self;
    if (self.attachmentCollectionDataStore.observation == nil) {
        self.attachmentCollectionDataStore.observation = self.observation;
        [self.attachmentCollection reloadData];
    } else {
        [self.attachmentCollection reloadData];
    }    
}

- (IBAction) getDirections:(id)sender {
    CLLocationCoordinate2D coordinate = ((GeoPoint *) self.observation.geometry).location.coordinate;
    NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
    if ([[UIApplication sharedApplication] canOpenURL:testURL]) {
        NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
                                       @"comgooglemaps-x-callback",
                                       coordinate.latitude,
                                       coordinate.longitude,
                                       @"mage://?resume=true",
                                       "MAGE"];
        NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
        [[UIApplication sharedApplication] openURL:directionsURL];
    } else {
        NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:[self.observation.properties valueForKey:@"type"]];
        NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        [mapItem openInMapsWithLaunchOptions:options];
    }
}

@end
