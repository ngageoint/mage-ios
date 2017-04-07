//
//  ObservationCommonHeaderTableViewCell.m
//  MAGE
//
//

#import "ObservationCommonHeaderTableViewCell.h"
#import <Server.h>
#import <User.h>
#import <Event.h>
#import "NSDate+display.h"
#import "MapDelegate.h"
#import "ObservationDataStore.h"
#import "AttachmentCollectionDataStore.h"
#import "Attachment+Thumbnail.h"

@interface ObservationCommonHeaderTableViewCell ()
@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@end

@implementation ObservationCommonHeaderTableViewCell


- (void) configureCellForObservation: (Observation *) observation {
    NSString *name = [observation.properties valueForKey:@"type"];
    if (name != nil) {
        self.primaryFieldLabel.text = name;
    } else {
        self.primaryFieldLabel.text = @"Observation";
    }
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *variantText = [observation.properties objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && variantText.length > 0) {
        self.variantFieldLabel.hidden = NO;
        self.variantFieldLabel.text = [observation.properties objectForKey:variantField];
    } else {
        self.variantFieldLabel.hidden = YES;
    }
    
    self.userLabel.text = observation.user.name;
    self.dateLabel.text = [observation.timestamp formattedDisplayDate];
    self.locationLabel.text = [NSString stringWithFormat:@"%.05f, %.05f", observation.location.coordinate.latitude, observation.location.coordinate.longitude];
    
    [self setupMapForObservation:observation];
    [self setupAttachmentsForObservation:observation];
}
         
- (void) setupMapForObservation:(Observation *) observation {
    if (!self.mapView) {
        return;
    }
    
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    
    Observations *observations = [Observations observationsForObservation:observation];
    [self.mapDelegate setObservations:observations];
    
    CLLocationDistance latitudeMeters = 2500;
    CLLocationDistance longitudeMeters = 2500;
    NSDictionary *properties = observation.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(observation.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    
    [self.mapDelegate setObservations:observations];
    [self.mapDelegate selectedObservation:observation];
    self.mapDelegate.hideStaticLayers = YES;
    
    [self.mapDelegate selectedObservation:observation region:viewRegion];
 }

- (void) setupAttachmentsForObservation:(Observation *) observation {
    if (!self.attachmentCollection) {
        return;
    }
    
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentFormatName = AttachmentSmallSquare;
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.observation = observation;
}

- (void) setAttachmentSelectionDelegate:(NSObject<AttachmentSelectionDelegate> *)attachmentSelectionDelegate {
    _attachmentSelectionDelegate = attachmentSelectionDelegate;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end
