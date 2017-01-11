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
@property (weak, nonatomic) IBOutlet UIStackView *favoritesView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButton;

@property (strong, nonatomic) UIColor *favoriteDefaultColor;
@property (strong, nonatomic) UIColor *favoriteHighlightColor;
@end

@implementation ObservationViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.favoriteDefaultColor = [UIColor colorWithWhite:0.0 alpha:.54];
    self.favoriteHighlightColor = [UIColor colorWithRed:126/255.0 green:211/255.0 blue:33/255.0 alpha:1.0];
    
    self.attachmentCollectionDataStore.attachmentFormatName = AttachmentMediumSquare;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.userLabel.text = self.observation.user.name;
    
    self.userLabel.text = self.observation.user.name;
    self.timestampLabel.text = [self.observation.timestamp formattedDisplayDate];
	
	self.locationLabel.text = [NSString stringWithFormat:@"%.6f, %.6f", self.observation.location.coordinate.latitude, self.observation.location.coordinate.longitude];
    
    self.attachmentCollectionDataStore.attachmentSelectionDelegate = self;
    if (self.attachmentCollectionDataStore.observation == nil) {
        self.attachmentCollectionDataStore.observation = self.observation;
        [self.attachmentCollection reloadData];
    } else {
        [self.attachmentCollection reloadData];
    }
    
    [self updateFavorites];
}

- (void) updateFavorites {
    NSSet *favorites = [self.observation.favorites filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.favorite = %@", [NSNumber numberWithBool:YES]]];
    NSInteger favoritesCount = [favorites count];
    
    if (favoritesCount == 0) {
        self.favoritesView.hidden = YES;
        self.favoriteButton.tintColor = self.favoriteDefaultColor;
    } else {
        self.favoritesView.hidden = NO;
        self.favoriteButton.tintColor = self.favoriteHighlightColor;
        [self.favoritesButton setTitle:[NSString stringWithFormat:@"%ld %@", favoritesCount, favoritesCount > 1 ? @"FAVORITES" : @"FAVORITE"] forState:UIControlStateNormal];
    }
}

//- (IBAction) getDirections:(id)sender {
//    CLLocationCoordinate2D coordinate = ((GeoPoint *) self.observation.geometry).location.coordinate;
//    NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
//    if ([[UIApplication sharedApplication] canOpenURL:testURL]) {
//        NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
//                                       @"comgooglemaps-x-callback",
//                                       coordinate.latitude,
//                                       coordinate.longitude,
//                                       @"mage://?resume=true",
//                                       "MAGE"];
//        NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
//        [[UIApplication sharedApplication] openURL:directionsURL];
//    } else {
//        NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
//        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
//        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
//        [mapItem setName:[self.observation.properties valueForKey:@"type"]];
//        NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
//        [mapItem openInMapsWithLaunchOptions:options];
//    }
//}

@end
