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


- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    NSArray *observationForms = [observation.properties objectForKey:@"forms"];
    NSDictionary *form;
    for (NSDictionary *checkForm in forms) {
        if ((long)[checkForm objectForKey:@"id"] == (long)[[observationForms objectAtIndex:0] objectForKey:@"formId"]) {
            form = checkForm;
        }
    }
    
    NSString *primaryField = [form objectForKey:@"primaryField"];
    NSString *variantField = [form objectForKey:@"secondaryField"];
    
    NSString *primaryText = [[observationForms objectAtIndex:0] objectForKey:primaryField];
    if (primaryField != nil && primaryText != nil && [primaryText isKindOfClass:[NSString class]] && [primaryText length] > 0) {
        self.primaryFieldLabel.text = primaryText;
        self.primaryFieldLabel.hidden = NO;
    } else {
        self.primaryFieldLabel.hidden = YES;
    }
    
    NSString *variantText = [[observationForms objectAtIndex:0] objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && [variantText length] > 0) {
        self.variantFieldLabel.hidden = NO;
        self.variantFieldLabel.text = variantText;
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
