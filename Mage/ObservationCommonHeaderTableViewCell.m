//
//  ObservationCommonHeaderTableViewCell.m
//  MAGE
//
//

#import "ObservationCommonHeaderTableViewCell.h"
#import "Server.h"
#import "User.h"
#import "Event.h"
#import "NSDate+display.h"
#import "MapDelegate.h"
#import "ObservationDataStore.h"
#import "AttachmentCollectionDataStore.h"
#import "Attachment+Thumbnail.h"
#import "Theme+UIResponder.h"

@interface MKMapView ()
-(void) _setShowsNightMode:(BOOL)yesOrNo;
@end

@interface ObservationCommonHeaderTableViewCell ()
@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@end

@implementation ObservationCommonHeaderTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.primaryFieldLabel.textColor = [UIColor brand];
    self.variantFieldLabel.textColor = [UIColor brand];
    self.userLabel.textColor = [UIColor secondaryText];
    self.dateLabel.textColor = [UIColor secondaryText];
    self.locationLabel.textColor = [UIColor secondaryText];
    if (theme == Day) {
        [self.mapView _setShowsNightMode:NO];
    } else {
        [self.mapView _setShowsNightMode:YES];
    }
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    
    NSString *primaryFieldText = [observation primaryFieldText];
    
    if (primaryFieldText != nil && [primaryFieldText length] > 0) {
        self.primaryFieldLabel.text = primaryFieldText;
        self.primaryFieldLabel.hidden = NO;
    } else {
        self.primaryFieldLabel.hidden = YES;
    }
    
    NSString *variantText = [observation secondaryFieldText];
    if (variantText != nil && [variantText length] > 0) {
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
    
    [self registerForThemeChanges];
}
         
- (void) setupMapForObservation:(Observation *) observation {
    if (!self.mapView) {
        return;
    }
    
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    
    Observations *observations = [Observations observationsForObservation:observation];
    self.mapDelegate.hideStaticLayers = YES;
    
    __weak __typeof__(self) weakSelf = self;
    [self.mapDelegate setObservations:observations withCompletion:^{
        MapObservation *mapObservation = [weakSelf.mapDelegate.mapObservations observationOfId:observation.objectID];
        MKCoordinateRegion viewRegion = [mapObservation viewRegionOfMapView:weakSelf.mapView];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.mapDelegate selectedObservation:observation region:viewRegion];
        });
    }];

 }

- (void) setupAttachmentsForObservation:(Observation *) observation {
    if (!self.attachmentCollection) {
        return;
    }
    
    [self.attachmentCollection registerNib:[UINib nibWithNibName:@"AttachmentCell" bundle:nil] forCellWithReuseIdentifier:@"AttachmentCell"];

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
